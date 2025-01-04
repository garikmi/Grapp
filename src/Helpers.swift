import AppKit
import Carbon
import OSLog

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String("Helpers")
)

struct Program {
    let path: String
    let name: String
    let ext: String
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
    let source = TISCopyInputSourceForLanguage("en-US" as CFString)
        .takeRetainedValue();
    guard let ptr = TISGetInputSourceProperty(source,
        kTISPropertyUnicodeKeyLayoutData)
    else {
        logger.log("Could not get keyboard layout data")
        return nil
    }
    let layoutData = Unmanaged<CFData>.fromOpaque(ptr)
        .takeUnretainedValue() as Data
    let osStatus = layoutData.withUnsafeBytes {
        UCKeyTranslate(
            $0.bindMemory(to: UCKeyboardLayout.self).baseAddress,
            virtualKeyCode, UInt16(kUCKeyActionDown), modifierKeys,
            keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
            &deadKeys, maxNameLength, &nameLength, &nameBuffer)
    }
    guard osStatus == noErr else {
        logger.debug("Code: \(virtualKeyCode) Status: \(osStatus)")
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

func systemImage(_ name: String, _ size: NSFont.TextStyle,
    _ scale: NSImage.SymbolScale,
    _ configuration: NSImage.SymbolConfiguration) -> NSImage?
{
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(
            NSImage.SymbolConfiguration(textStyle: size, scale: scale)
                .applying(configuration)
        )
}

func isDirectory(atPath path: String) -> Bool {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
        return isDir.boolValue
    }
    return false
}

extension String {
    /// This converts string to UInt as a fourCharCode
    public var fourCharCodeValue: Int {
        var result: Int = 0
        if let data = self.data(using: String.Encoding.macOSRoman) {
            data.withUnsafeBytes({ (rawBytes) in
                let bytes = rawBytes.bindMemory(to: UInt8.self)
                for i in 0 ..< data.count {
                    result = result << 8 + Int(bytes[i])
                }
            })
        }
        return result
    }
}
