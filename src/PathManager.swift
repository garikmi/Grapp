import AppKit
import OSLog

final class PathManager {
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PathManager.self)
    )

    static let shared = PathManager()

    // TODO: Filesystem events to watch changes on these directories and
    //       rebuild index when needed.
    // NOTE: These are default paths where MacOS's default programs are
    //       stored. This list should be updated if something changes in
    //       newer MacOS version.
    static let defaultPaths = ["/Applications", "/System/Applications",
        "/System/Applications/Utilities", "/System/Library/CoreServices",
        "/Applications/Xcode.app/Contents/Applications",
        "/System/Library/CoreServices/Applications"]
    var userPaths: [String] = []
    private(set) var programs: [Program] = []

    private let fileManager = FileManager.default

    private init() {
        if let paths =
            UserDefaults.standard.stringArray(forKey: "programPaths")
        {
            for path in paths {
                addPath(path)
            }
        } else {
            userPaths += Self.defaultPaths
        }
    }

    deinit {}

    public func addPath(_ path: String) {
        if !userPaths.contains(path) {
            userPaths.append(path)
        }
    }

    public func removePath(_ path: String) {
        userPaths.removeAll { $0 == path }
    }

    public func removeEmpty() {
        userPaths.removeAll { $0.isEmpty }
    }

    public func savePaths() {
        UserDefaults.standard.set(userPaths, forKey: "programPaths")
    }

    public func reset() {
        userPaths = []
        userPaths += Self.defaultPaths
        savePaths()
    }

    public func rebuildIndex() {
        programs.removeAll(keepingCapacity: true)
        for path in userPaths {
            do {
                let items = try fileManager.contentsOfDirectory(
                    atPath: path)
                for item in items {
                    let name = String(item.dropLast(4))

                    if item.hasSuffix(".app") {
                        if !programs.contains(where: { name == $0.name }) {
                            programs.append(
                                Program(
                                    path: path, name: name, ext: ".app",
                                    img: nil))
                        }
                    }
                }
            } catch {
                Self.logger.error("Error reading directory: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
