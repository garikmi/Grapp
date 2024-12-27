import AppKit

func systemImage(_ name: String, _ size: NSFont.TextStyle, _ scale: NSImage.SymbolScale, _ configuration: NSImage.SymbolConfiguration) -> NSImage? {
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
