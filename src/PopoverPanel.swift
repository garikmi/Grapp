import Cocoa
import OSLog

class PopoverPanel: NSPanel {
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PopoverPanel.self)
    )

    override var canBecomeKey: Bool { true }

    init(viewController: NSViewController) {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled, .nonactivatingPanel, .utilityWindow,
                        .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.contentViewController = viewController

        title = ""
        isMovable = true
        isMovableByWindowBackground = true
        isFloatingPanel = true
        isOpaque = false
        level = .statusBar
        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        animationBehavior = .none
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary,
                              .transient]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.rawValue
        let command = NSEvent.ModifierFlags.command.rawValue
        let shift = NSEvent.ModifierFlags.shift.rawValue
        let control = NSEvent.ModifierFlags.control.rawValue
        let option = NSEvent.ModifierFlags.option.rawValue

        if event.type == NSEvent.EventType.keyDown {
            // Checks if flags contains a command key,
            // then check if flags doesn't contain any other keys.
            if (modifiers & command) == command,
                (modifiers & (control | shift | option)) == 0,
                event.keyCode == 12 // Q
            {
                NSApplication.shared.terminate(self)
                return true
            } else if (modifiers & command) == command,
                (modifiers & (control | shift | option)) == 0,
                event.keyCode == 13 // W
            {
                resignKey()
                return true
            } else if (modifiers & (command & shift)) == command & shift,
                (modifiers & (control | option)) == 0,
                event.keyCode == 15 // R
            {
                PathManager.shared.rebuildIndex()
            } else if event.keyCode == 53 { // ESC
                resignKey()
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }
}
