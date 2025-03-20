import Carbon
import OSLog

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var eventType =
        EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                      eventKind: UInt32(kEventHotKeyPressed))
    private var eventHandlerRef: EventHandlerRef?
    public var handler: EventHandlerUPP?

    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID: EventHotKeyID =
        EventHotKeyID(signature: OSType("grap".fourCharCodeValue), id: 1)

    private init() {}
    deinit {}

    // TODO: Handle errors.
    public func enable() {
        if eventHandlerRef != nil {
            disable()
        }

        let err = InstallEventHandler(GetApplicationEventTarget(), handler,
                                      1, &eventType, nil, &eventHandlerRef)
        if err == noErr {
            print("Installed event handler.")
        } else {
            print("Failed to install event handler.")
        }
    }

    public func disable() {
        guard eventHandlerRef != nil else { return }
        let err = RemoveEventHandler(eventHandlerRef)
        if err == noErr {
            // WARNING: Does it remove no matter what on error?
            eventHandlerRef = nil
            print("Removed event handler.")
        } else {
            print("Failed to remove event handler.")
        }
    }

    // TODO: Handle errors.
    // NOTE: Multiple modifiers should be ORed.
    public func registerHotKey(key: Int, modifiers: Int) {
        if hotKeyRef != nil {
            unregisterHotKey()
        }

        let err = RegisterEventHotKey(UInt32(key), UInt32(modifiers),
                                      hotKeyID, GetApplicationEventTarget(),
                                      UInt32(kEventHotKeyNoOptions),
                                      &hotKeyRef)
        if err == noErr {
            print("Registered hot key.")
        } else {
            print("Failed to register hot key.")
        }
    }

    // TODO: Handle errors.
    public func unregisterHotKey() {
        guard hotKeyRef != nil else { return }
        let err = UnregisterEventHotKey(hotKeyRef)
        if err == noErr {
            // WARNING: Does it unregister no matter what on error?
            hotKeyRef = nil
            print("Successfully unregistered hot key.")
        } else {
            print("Failed to unregistered hot key.")
        }
    }
}
