import Cocoa
import Carbon

protocol EditableNSTextFieldDelegate: AnyObject {
    func lostFocus()
}

final class EditableNSTextField: NSTextField {
    weak var auxiliaryDelegate: EditableNSTextFieldDelegate?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.rawValue
        let key = event.keyCode

        if event.type == NSEvent.EventType.keyDown {
            if modsContains(keys: OSCmd, in: modifiers) {
                if key == kVK_ANSI_X {
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) {
                        return true
                    }
                } else if key == kVK_ANSI_C {
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) {
                        return true
                    }
                } else if key == kVK_ANSI_V {
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) {
                        return true
                    }
                } else if key == kVK_ANSI_Z {
                    if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) {
                        return true
                    }
                } else if key == kVK_ANSI_A {
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) {
                        return true
                    }
                } else if isNumericalCode(key) { // Ignore Command + {1-9}.
                    return true
                }
            } else if modsContains(keys: OSCmd | OSShift, in: modifiers) {
                if key == kVK_ANSI_Z {
                    if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) {
                        return true
                    }
                }
            }
        }

        return super.performKeyEquivalent(with: event)
    }

    override func textDidEndEditing(_ notification: Notification) {
        auxiliaryDelegate?.lostFocus()
    }
}
