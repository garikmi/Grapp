import AppKit
import Carbon

let OSCtrl  = NSEvent.ModifierFlags.control.rawValue
let OSCmd   = NSEvent.ModifierFlags.command.rawValue
let OSOpt   = NSEvent.ModifierFlags.option.rawValue
let OSShift = NSEvent.ModifierFlags.shift.rawValue
let OSMods  = UInt(OSCtrl | OSCmd | OSOpt | OSShift)

func modsContains(keys: UInt, in modifiers: UInt) -> Bool {
    return (modifiers & keys) == keys && ((modifiers ^ keys) & OSMods) == 0
}

func isNumericalCode(_ key: UInt16) -> Bool {
    return (key == kVK_ANSI_1 || key == kVK_ANSI_2 || key == kVK_ANSI_3 || key == kVK_ANSI_4 || key == kVK_ANSI_5 || key == kVK_ANSI_6 || key == kVK_ANSI_7 || key == kVK_ANSI_8 || key == kVK_ANSI_9)
}

func modsContainsNone(in modifiers: UInt) -> Bool {
    return (modifiers & OSMods) == 0
}

func containsFlags(key: Int, in flags: Int) -> Bool {
    return (flags & key) == key
}

enum ViewConstants {
    static let spacing2:  CGFloat =  2
    static let spacing5:  CGFloat =  2
    static let spacing10: CGFloat = 10
    static let spacing15: CGFloat = 15
    static let spacing20: CGFloat = 20
    static let spacing25: CGFloat = 25
    static let spacing30: CGFloat = 30
    static let spacing35: CGFloat = 35
    static let spacing40: CGFloat = 40
}

func keyName(virtualKeyCode: UInt16) -> String? {
    let maxNameLength = 4
    var nameBuffer = [UniChar](repeating: 0, count : maxNameLength)
    var nameLength = 0

    let modifierKeys = UInt32(alphaLock >> 8) & 0xFF // Caps Lock
    var deadKeys: UInt32 = 0
    let keyboardType = UInt32(LMGetKbdType())

    //let source =
    //    TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
    let source = TISCopyInputSourceForLanguage("en-US" as CFString).takeRetainedValue();
    guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else {
        print("Could not get keyboard layout data")
        return nil
    }
    let layoutData = Unmanaged<CFData>.fromOpaque(ptr)
        .takeUnretainedValue() as Data
    let osStatus = layoutData.withUnsafeBytes {
        UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, virtualKeyCode,
                       UInt16(kUCKeyActionDown), modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
                       &deadKeys, maxNameLength, &nameLength, &nameBuffer)
    }
    guard osStatus == noErr else {
        print("Code: \(virtualKeyCode) Status: \(osStatus)")
        return nil
    }

    // NOTE: This is way too specific. This will need an additional func
    //       flag or be re-written to a more generic version if it's going
    //       to be used for something other than hot key representation.
    var character = String(utf16CodeUnits: nameBuffer, count: nameLength)
    if character == " " {
        character = "␣"
    } else {
        character = character.uppercased()
    }
    return character
}

func isDirectory(_ path: String) -> Bool {
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
        return true
    } else {
        return false
    }
}

func systemImage(_ name: String, _ size: NSFont.TextStyle, _ scale: NSImage.SymbolScale, _ configuration: NSImage.SymbolConfiguration) -> NSImage? {
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(NSImage.SymbolConfiguration(textStyle: size, scale: scale).applying(configuration))
}

extension String {
    // This converts string to UInt as a fourCharCode
    public var fourCharCodeValue: Int {
        var result: Int = 0
        if let data = self.data(using: String.Encoding.macOSRoman) {
            data.withUnsafeBytes { (rawBytes) in
                let bytes = rawBytes.bindMemory(to: UInt8.self)
                for i in 0 ..< data.count {
                    result = result << 8 + Int(bytes[i])
                }
            }
        }
        return result
    }
}
