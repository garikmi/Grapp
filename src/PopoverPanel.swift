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
        Self.logger.debug("performKeyEquivalent keyCode=\(event.keyCode)")
        let commandKey = NSEvent.ModifierFlags.command.rawValue

        // TODO: Make these depend on virtual keycodes, instead of
        //       characters.
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue &
                NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
                == commandKey,
                event.charactersIgnoringModifiers! == "w"
            {
                resignKey()
                return true
            } else if (event.modifierFlags.rawValue &
                NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
                == commandKey,
                event.charactersIgnoringModifiers! == "q"
            {
                NSApplication.shared.terminate(self)
                return true
            } else if event.keyCode == 53 {
                resignKey()
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }
}
