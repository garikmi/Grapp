import Cocoa
import Carbon

class PopoverPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init(viewController: NSViewController) {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.contentViewController = viewController

        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = false

        title = ""
        isMovable = true
        isMovableByWindowBackground = true
        isFloatingPanel = true
        level = .statusBar
        titlebarAppearsTransparent = true

        animationBehavior = .none
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.rawValue
        let key = event.keyCode

        if event.type == NSEvent.EventType.keyDown {
            if modsContains(keys: OSCmd, in: modifiers) && key == kVK_ANSI_Q {
                NSApplication.shared.terminate(self)
                return true
            } else if modsContains(keys: OSCmd, in: modifiers) && key == kVK_ANSI_W {
                resignKey()
                return true
            } else if modsContains(keys: OSCmd | OSShift, in: modifiers) && key == kVK_ANSI_R {
                PathManager.shared.updateIndex()
                return true
            } else if key == kVK_Escape {
                resignKey()
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }
}
