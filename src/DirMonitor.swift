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
    // var handler: ((Int, UnsafeMutablePointer<UnsafePointer<Int8>>, UnsafeBufferPointer<UInt32>, UnsafeBufferPointer<UInt64>) -> Void)?
    private var stream: FSEventStreamRef? = nil

    func start() -> Bool {
        precondition(self.stream == nil, "started a running monitor")
        if dirs.count < 1 { return false }

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        // func test(count: Int, paths: UnsafeMutablePointer<UnsafePointer<Int8>>, flags: UnsafeBufferPointer<UInt32>, ids: UnsafeBufferPointer<UInt64>) { }
        // test(count: numEvents, paths: pathsBase, flags: flagsBuffer, ids: eventIDsBuffer)

        guard let stream = FSEventStreamCreate(nil,
            {
            (stream, info, numEvents, eventPaths, eventFlags, eventIds) in
                let pathsBase         = eventPaths .assumingMemoryBound(to: UnsafePointer<CChar>.self)
                let pathsBuffer       = UnsafeBufferPointer(start: pathsBase, count: numEvents)
                let flagsBuffer       = UnsafeBufferPointer(start: eventFlags, count: numEvents)
                // let eventIDsBuffer = UnsafeBufferPointer(start: eventIds, count: numEvents)

                // stream     -> OpaquePointer
                // info       -> Optional<UnsafeMutableRawPointer>
                // numEvents  -> Int
                // eventPaths -> UnsafeMutableRawPointer
                // eventFlags -> UnsafePointer<UInt32>
                // eventIds   -> UnsafePointer<UInt64>

                // pathsBase      -> UnsafeMutablePointer<UnsafePointer<Int8>>
                // pathsBuffer    -> UnsafeBufferPointer<UnsafePointer<Int8>>
                // flagsBuffer    -> UnsafeBufferPointer<UInt32>
                // eventIDsBuffer -> UnsafeBufferPointer<UInt64>

                for i in 0..<numEvents {
                    let flags = Int(flagsBuffer[i])

                    // NOTE: Since this is a directory monitor, we discard file events.
                    if !containsFlags(key: kFSEventStreamEventFlagItemIsDir, in: flags) {
                        continue
                    }

                    let url: URL = URL(fileURLWithFileSystemRepresentation: pathsBuffer[i], isDirectory: true, relativeTo: nil)

                    // NOTE: The delegate callback should always be called on main thread!
                    DispatchQueue.main.async {
                        delegate.fsEventTriggered(url.path, flags)
                    }
                }
            },
            &context,
            self.dirs, // [path as NSString] as NSArray,
            UInt64(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents) // FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone)
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
