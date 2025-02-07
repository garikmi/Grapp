import AppKit
import Carbon

class MenulessWindow: NSWindow {
    init(viewController: NSViewController) {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.contentViewController = viewController

        title = ""
        titlebarAppearsTransparent = true
        collectionBehavior = [.managed, .fullScreenNone]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.rawValue
        let key = event.keyCode

        if event.type == NSEvent.EventType.keyDown {
            if modsContains(keys: OSCmd, in: modifiers) && key == kVK_ANSI_W {
                performClose(nil)
            }
        }

        return super.performKeyEquivalent(with: event)
    }
}
