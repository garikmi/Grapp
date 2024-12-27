import Cocoa
import Carbon
import ServiceManagement
import OSLog

struct Program {
    let path: String
    let name: String
    let ext: String
}

func appActivatedHandler(nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    print("App was activated!")
    return noErr
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AppDelegate.self)
    )

    var paths = ["/Applications", "/System/Applications",
                 "/System/Applications/Utilities",
                 "/Applications/Xcode.app/Contents/Applications",
                 "/System/Library/CoreServices/Applications"]
    var programs: [Program] = []

    let fileManager = FileManager.default

    let window = PopoverPanel(viewController: SearchViewController())

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.logger.debug("applicationDidFinishLaunching")

        NSRunningApplication.current.hide()

        window.delegate = self

        //GlobalEventTap.shared.enable()

        for path in paths {
            do {
                let items = try fileManager.contentsOfDirectory(atPath: path)
                for item in items {
                    let name = String(item.dropLast(4))
                    if item.hasSuffix(".app") {
                        if !programs.contains(where: { name == $0.name }) {
                            programs.append(Program(path: path, name: name, ext: ".app"))
                        }
                    }
                }
            } catch {
                print("Error reading directory: \(error.localizedDescription)")
            }
        }

        window.makeKeyAndOrderFront(nil)

        // TODO: Implement Unregister and Uninstall.
        // TODO: A user should be able to enter hot keys to trigger.
        //       We either can use local event monitor or let user choose
        //       from list.
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID: EventHotKeyID = EventHotKeyID(signature: OSType("grap".fourCharCodeValue), id: 1)

        // GetEventDispatcherTarget
        var err = RegisterEventHotKey(UInt32(kVK_Space), UInt32(optionKey), hotKeyID, GetApplicationEventTarget(), UInt32(kEventHotKeyNoOptions), &hotKeyRef)
        //let handler = NewEventHandlerUPP()

        // Handler get executed on main thread.
        let handler: EventHandlerUPP = { (inHandlerCallRef, inEvent, inUserData) -> OSStatus in
            AppDelegate.logger.debug("Shortcut handler fired off.")
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                let window = delegate.window
                if window.isKeyWindow {
                    window.resignKey()
                } else {
                    window.makeKeyAndOrderFront(nil)
                }
            }

            return noErr
        }
        var eventHandlerRef: EventHandlerRef? = nil

        if err == noErr {
            Self.logger.debug("Registered hot key.")

            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            err = InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandlerRef)

            if err == noErr {
                Self.logger.debug("Event handler installed.")
            } else {
                Self.logger.debug("Failed to install event handler.")
            }
        } else {
            Self.logger.debug("Failed to register hot key.")
        }
    }

    //func applicationWillTerminate(_ notification: Notification) {
    //}

    func windowDidBecomeKey(_ notification: Notification) {
        Self.logger.debug("Popover became key.")
    }

    func windowDidResignKey(_ notification: Notification) {
        Self.logger.debug("Popover resigned key.")

        if window.isVisible {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Self.logger.debug("Application reopened.")

        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }

        return true
    }
}

extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

extension String {
    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line : [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat : [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                }
                else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}
