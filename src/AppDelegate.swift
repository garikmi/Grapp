import Cocoa
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let fileManager = FileManager.default

    let window = PopoverPanel(viewController: SearchViewController())
    let settingsWindow =
        MenulessWindow(viewController: SettingsViewController())
    let aboutWindow = MenulessWindow(viewController: AboutViewController())

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsWindow.title = "Settings"
        aboutWindow.level = .statusBar

        PathManager.shared.updateIndex()

        window.delegate = self

        // TODO: Move down.
        // NOTE: Here we check wether the program was launched by the
        // system (e.g. launch-at-login). If it was not, then display the
        // window.
        if let event = NSAppleEventManager.shared().currentAppleEvent,
           !(event.eventID == kAEOpenApplication &&
                event.paramDescriptor(forKeyword: keyAEPropData)?
                    .enumCodeValue == keyAELaunchedAsLogInItem)
        {
            window.makeKeyAndOrderFront(nil)
        }

        HotKeyManager.shared.handler =
        { (inHandlerCallRef, inEvent, inUserData) -> OSStatus in
            if let delegate = NSApplication.shared.delegate as? AppDelegate
            {
                let window = delegate.window
                if window.isKeyWindow {
                    window.resignKey()
                } else {
                    window.makeKeyAndOrderFront(nil)
                    if let controller =
                        window.contentViewController as? SearchViewController
                    {
                        controller.centerWindow()
                    }
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
            HotKeyManager.shared.registerHotKey(key: code, modifiers: mods)
        } else {
            // NOTE: This is the default shortcut. If you want to change
            //       it, do not forget to change it in other files
            //       (SettingsViewController).
            HotKeyManager.shared.registerHotKey(key: kVK_Space,
                                                modifiers: optionKey)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if window.isVisible {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows: Bool) -> Bool {
        if !window.isKeyWindow {
            if !settingsWindow.isVisible {
                window.makeKeyAndOrderFront(nil)
            }
        }

        return true
    }

    public func toggleLaunchAtLogin(isOn status: Bool) {
        let service = SMAppService.mainApp
        if status, service.status != .enabled {
            try? service.register()
        } else if service.status == .enabled {
            try? service.unregister()
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
        aboutWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func showSettingsWindow() {
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // NOTE: This function act like a callback and is triggered by
    // DirMonitor when file system events occur.
    public func fsEventTriggered(_ path: String, _ flags: Int) {
        if containsFlags(key: kFSEventStreamEventFlagItemCreated, in: flags) ||
           containsFlags(key: kFSEventStreamEventFlagItemRemoved, in: flags) ||
           containsFlags(key: kFSEventStreamEventFlagItemCloned,  in: flags) ||
           containsFlags(key: kFSEventStreamEventFlagItemRenamed, in: flags)
        {
            for dir in PathManager.shared.paths {
                if path.hasPrefix(dir.key) {
                    PathManager.shared.rebuildIndex(at: dir.key)
                }
            }
        }
    }
}
