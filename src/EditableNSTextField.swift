import Cocoa

protocol EditableNSTextFieldDelegate: AnyObject {
    func lostFocus()
}

final class EditableNSTextField: NSTextField {
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue |
                                  NSEvent.ModifierFlags.shift.rawValue

    weak var auxiliaryDelegate: EditableNSTextFieldDelegate?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue &
                NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
                == commandKey 
            {
                // TODO: Use virtual key codes instead of characters.
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)),
                        to: nil, from: self)
                    { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)),
                        to: nil, from: self)
                    { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)),
                        to: nil, from: self)
                    { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")),
                        to: nil, from: self)
                    { return true }
                case "a":
                    if NSApp.sendAction(
                        #selector(NSResponder.selectAll(_:)), to: nil,
                        from: self)
                    { return true }
                default:
                    break
                }
            } else if (event.modifierFlags.rawValue &
                NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
                == commandShiftKey
            {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to: nil,
                        from: self)
                    { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    override func textDidEndEditing(_ notification: Notification) {
        auxiliaryDelegate?.lostFocus()
    }
}
