import Cocoa
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let fileManager = FileManager.default

    let window = PopoverPanel(viewController: SearchViewController())
    let aboutWindow = MenulessWindow(viewController: AboutViewController())

    func applicationDidFinishLaunching(_ notification: Notification) {
        aboutWindow.level = .statusBar

        PathManager.shared.updateIndex()

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
        if let code = UserDefaults.standard.object(forKey: "keyCode") as? Int,
           let mods = UserDefaults.standard.object(forKey: "keyModifiers") as? Int
        {
            HotKeyManager.shared.registerHotKey(key: code, modifiers: mods)
        } else {
            // NOTE: This is the default shortcut. If you want to change
            //       it, do not forget to change it in other files
            //       (SettingsViewController).
            HotKeyManager.shared.registerHotKey(key: kVK_Space, modifiers: optionKey)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if window.isVisible {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
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

    public func showAboutWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        aboutWindow.makeKeyAndOrderFront(nil)
    }

    // NOTE: This function is triggered by DirMonitor.
    public func fsEventTriggered(_ path: String, _ flags: Int) {
        var shouldReload = false
        print("PATH: \(path)")
        // if containsFlags(key: kFSEventStreamEventFlagNone, in: flags) {
        // }
        // if containsFlags(key: kFSEventStreamEventFlagRootChanged, in: flags) {
        // }
        // if containsFlags(key: kFSEventStreamEventFlagMustScanSubDirs, in: flags) {
        // }
        // if containsFlags(key: kFSEventStreamEventFlagItemInodeMetaMod, in: flags) {
        // }
        if containsFlags(key: kFSEventStreamEventFlagItemCreated, in: flags) {
            print("    CREATED")
            shouldReload = true
        }
        if containsFlags(key: kFSEventStreamEventFlagItemRemoved, in: flags) {
            print("    REMOVED")
            shouldReload = true
        }
        if containsFlags(key: kFSEventStreamEventFlagItemCloned, in: flags) {
            print("    CLONED")
            shouldReload = true
        }
        if containsFlags(key: kFSEventStreamEventFlagItemRenamed, in: flags) {
            print("    RENAMED")
            shouldReload = true
        }

        // TODO: This should also trigger SearchViewController's search re-index.
        if shouldReload {
            for dir in PathManager.shared.paths {
                if path.hasPrefix(dir.key) {
                    PathManager.shared.rebuildIndex(at: dir.key)
                }
            }
            PathManager.shared.refreshFilesystemWatchers()
        }
    }
}
