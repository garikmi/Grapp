import Cocoa
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let fileManager = FileManager.default

    let window = PopoverPanel(viewController: SearchViewController())

    func applicationDidFinishLaunching(_ notification: Notification) {
        PathManager.shared.rebuildIndex()

        window.delegate = self

        window.makeKeyAndOrderFront(nil)

        HotKeyManager.shared.handler =
        { (inHandlerCallRef, inEvent, inUserData) -> OSStatus in
            if let delegate =
                NSApplication.shared.delegate as? AppDelegate
            {
                let window = delegate.window
                if window.isKeyWindow {
                    window.resignKey()
                } else {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            return noErr
        }

        HotKeyManager.shared.enable()
        if let code =
                UserDefaults.standard.object(forKey: "keyCode") as? Int,
           let mods =
            UserDefaults.standard.object(forKey: "keyModifiers") as? Int
        {
            HotKeyManager.shared.registerHotKey(key: code,
                modifiers: mods)
        } else {
            // NOTE: This is the default shortcut. If you want to change
            //       it, do not forget to change it in other files
            //       (SettingsViewController).
            HotKeyManager.shared.registerHotKey(key: kVK_Space,
                modifiers: optionKey)
        }
    }

    //func applicationWillTerminate(_ notification: Notification) {
    //}

    func windowDidBecomeKey(_ notification: Notification) {
    }

    func windowDidResignKey(_ notification: Notification) {
        if window.isVisible {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
        hasVisibleWindows: Bool) -> Bool 
    {
        if !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }

        return true
    }

    public func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        if service.status == .enabled {
            try? service.unregister()
        } else {
            try? service.register()
        }
    }

    public func willLaunchAtLogin() -> Bool {
        let service = SMAppService.mainApp
        if service.status == .enabled {
            return true
        } else {
            return false
        }
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
