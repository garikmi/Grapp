import AppKit

class DirMonitor {
    init(paths: [String], queue: DispatchQueue) {
        for path in paths {
            if isDirectory(path) {
                self.dirs.add(path)
            }
        }
        self.queue = queue
    }

    deinit {
        precondition(self.stream == nil, "released a running monitor")
    }

    private var dirs: NSMutableArray = []
    private let queue: DispatchQueue
    private var stream: FSEventStreamRef? = nil

    func start() -> Bool {
        precondition(self.stream == nil, "started a running monitor")
        if dirs.count < 1 { return false }

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(nil,
            { (stream, info, numEvents, eventPaths, eventFlags, eventIds) in
                let pathsBase = eventPaths
                    .assumingMemoryBound(to: UnsafePointer<CChar>.self)
                let pathsBuffer =
                    UnsafeBufferPointer(start: pathsBase, count: numEvents)
                let flagsBuffer =
                    UnsafeBufferPointer(start: eventFlags, count: numEvents)
                // let eventIDsBuffer =
                //     UnsafeBufferPointer(start: eventIds, count: numEvents)

                for i in 0..<numEvents {
                    let flags = Int(flagsBuffer[i])
                    let url: URL =
                        URL(fileURLWithFileSystemRepresentation: pathsBuffer[i],
                            isDirectory: true, relativeTo: nil)

                    // Since this is a directory monitor, we discard file
                    // events.
                    if !containsFlags(key: kFSEventStreamEventFlagItemIsDir,
                                      in: flags) ||
                        !url.path.hasSuffix(".app")
                    {
                        continue
                    }

                    // NOTE: The delegate callback should always be called
                    //       on main thread!
                    DispatchQueue.main.async {
                        delegate.fsEventTriggered(url.path, flags)
                    }
                }
            },
            &context,
            self.dirs, // [path as NSString] as NSArray,
            UInt64(kFSEventStreamEventIdSinceNow),
            2.0,
            // FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        ) else {
            return false
        }

        self.stream = stream

        FSEventStreamSetDispatchQueue(stream, queue)
        guard FSEventStreamStart(stream) else {
            FSEventStreamInvalidate(stream)
            self.stream = nil
            return false
        }
        return true
    }

    func stop() {
        guard let stream = self.stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        self.stream = nil
    }
}
