import AppKit

struct Program {
    var path: String = ""
    var name: String = ""
    var ext : String = ""
    var img : NSImage? = nil
}

final class PathManager {
    static let shared = PathManager()

    private var dirMonitor: DirMonitor?

    // NOTE: These are default paths where MacOS's default programs are
    //       stored. This list should be updated if something changes in
    //       newer MacOS version.
    static let defaultPaths = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        "/System/Library/CoreServices",
        "/Applications/Xcode.app/Contents/Applications",
        "/System/Library/CoreServices/Applications"
    ]
    private(set) var paths: [String: [Program]] = [:]

    private let fileManager = FileManager.default

    private init() {
        // UserDefaults.standard.removeObject(forKey: "programPaths")
        if let dirs =
                UserDefaults.standard.stringArray(forKey: "programPaths"),
                                                  !dirs.isEmpty
        {
            for dir in dirs {
                addPath(dir)
            }
        } else {
            for path in PathManager.defaultPaths {
                addPath(path)
            }
        }
    }

    deinit {}

    public func addPath(_ path: String) {
        if isDirectory(path) {
            paths[path] = []
        }
    }

    public func removePath(_ path: String) {
        paths.removeValue(forKey: path)
    }

    public func resetPaths() {
        paths = [:]
        for path in PathManager.defaultPaths {
            addPath(path)
        }
    }

    public func contains(_ name: String) -> Bool {
        for path in paths {
            for prog in path.value {
                if prog.name == name {
                    return true
                }
            }
        }
        return false
    }

    public func refreshFilesystemWatchers() {
        dirMonitor?.stop()
        dirMonitor = nil

        var buf: [String] = []
        for path in paths {
            buf.append(path.key)
        }

        dirMonitor =
            DirMonitor(paths: buf,
                       queue: DispatchQueue.global(qos: .userInitiated))
        // _ = dirMonitor!.start()
        if dirMonitor!.start() {
            print("Started monitoring directories.")
        } else {
            print("Failed to start monitoring directories.")
        }
    }

    public func savePaths() {
        var buf: [String] = []
        for path in paths {
            buf.append(path.key)
        }
        UserDefaults.standard.set(buf, forKey: "programPaths")
    }

    // PERF: Optimize some more. Do not rebuild the entire array, instead
    //       remove or add only needed programs. Thereby, limiting the
    //       amount of allocations.
    public func rebuildIndex(at path: String) {
        paths[path] = []
        paths[path] = indexDirs(at: path, deepness: 2)
    }

    public func indexDirs(at path: String, deepness: Int) -> [Program] {
        var array: [Program] = []

        do {
            var items = try fileManager.contentsOfDirectory(atPath: path)
            items = items.filter({ isDirectory((path + "/" + $0)) })

            for item in items {
                let name = String(item.dropLast(4))

                if item.hasSuffix(".app"), !contains(name) {
                    array.append(Program(path: path, name: name,
                                         ext: ".app", img: nil))
                }
                if deepness > 0 {
                    array += indexDirs(at: path + "/" + item,
                                       deepness: deepness-1)
                }
            }
        } catch { print("Error: \(error.localizedDescription)") }

        return array
    }

    public func updateIndex() {
        print("updateIndex()")
        for path in paths {
            rebuildIndex(at: path.key)
        }
        refreshFilesystemWatchers()
    }

    // Touch paths to load them into CPUs cache.
    public func touchPaths() {
        for path in paths {
            _ = path
        }
    }
}
