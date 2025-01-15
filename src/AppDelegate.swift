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
