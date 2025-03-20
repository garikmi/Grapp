import AppKit
import Carbon
import OSLog

protocol KeyDetectorButtonDelegate: AnyObject {
    func keyWasSet(to keyCode: Int)
}

final class KeyDetectorButton: NSButton {
    var defaultKey: Int?

    weak var delegate: KeyDetectorButtonDelegate?

    override var acceptsFirstResponder: Bool { true }

    // This removes default bahavior from NSButton, thus allowing mouse up
    // events.
    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Escape || event.keyCode == kVK_Return {
            // Ignore escape and return keys.
        } else if event.keyCode == kVK_Delete {
            if let key = defaultKey,
                let character = keyName(virtualKeyCode: UInt16(key))
            {
                title = character
            }
        } else {
            if let character = keyName(virtualKeyCode: UInt16(event.keyCode)) {
                title = character
            }
            delegate?.keyWasSet(to: Int(event.keyCode))
        }
        self.window?.makeFirstResponder(nil)
    }
}
