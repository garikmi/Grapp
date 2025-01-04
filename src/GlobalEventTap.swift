import AppKit
import Carbon
import OSLog

fileprivate func handleGlobalEvents(proxy: CGEventTapProxy, 
                                    type: CGEventType, event: CGEvent,
                                    refcon: UnsafeMutableRawPointer?
                                    ) -> Unmanaged<CGEvent>? {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AppDelegate.self)
    )

    switch type {
        case .keyDown:
            //logger.debug(".keyDown")

            let keyCode = "keyCode: \(event.getIntegerValueField(.keyboardEventKeycode))"
            logger.debug("\(keyCode, privacy: .public)")

            //if (event.flags.rawValue & CGEventFlags.maskAlternate.rawValue) == CGEventFlags.maskAlternate.rawValue &&
            //   (event.flags.rawValue & (CGEventFlags.maskShift.rawValue | CGEventFlags.maskControl.rawValue | CGEventFlags.maskCommand.rawValue)) == 0 {
            //    logger.debug("maskAlternate")
            //}
            //logger.debug("Option rawValue=\(CGEventFlags.maskAlternate.rawValue)")

            // var keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            //if keyCode == 49 {
            //    logger.debug("EVENT TAP")
            //    return nil
            //}
        case .keyUp:
            //logger.debug(".keyUp")
            break
        default:
            break
    }


   //event.setIntegerValueField(.keyboardEventKeycode, value: keyCode) // NOTE: ???

    return Unmanaged.passUnretained(event)
}

final class GlobalEventTap {
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: GlobalEventTap.self)
    )

    static let shared = GlobalEventTap()

    private init() {}

    deinit {}

    func enable() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                              place: .headInsertEventTap,
                                              options: .defaultTap,
                                              eventsOfInterest: CGEventMask(eventMask),
                                              callback: handleGlobalEvents,
                                              userInfo: nil) else {
                                                  Self.logger.debug("Failed to create event.")
                                                  return
                                              }

        Self.logger.debug("Event was created.")

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }
}
