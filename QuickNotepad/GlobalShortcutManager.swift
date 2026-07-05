import Carbon.HIToolbox
import AppKit

/// Manages a single global hotkey using the Carbon Event API.
/// Opted out of default MainActor isolation since Carbon C callbacks
/// cannot be actor-isolated.
nonisolated class GlobalShortcutManager {
    // nonisolated(unsafe) because the singleton is accessed from both
    // the nonisolated C callback and @MainActor app code.
    nonisolated(unsafe) static let shared = GlobalShortcutManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    /// The callback to invoke when the hotkey fires.
    /// Marked @MainActor since it will toggle the popover on the main thread.
    nonisolated(unsafe) var onHotKey: (() -> Void)?
    
    private init() {
        installEventHandler()
    }
    
    func registerShortcut(keyCode: UInt32, modifiers: UInt32) {
        unregisterShortcut()
        
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x514E5044), // "QNPD"
            id: 1
        )
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("[GlobalShortcut] Failed to register hotkey: \(status)")
        }
    }
    
    func unregisterShortcut() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, _) -> OSStatus in
                // Carbon events on GetApplicationEventTarget() fire on the main thread.
                // Dispatch async to avoid blocking the Carbon event loop.
                DispatchQueue.main.async {
                    GlobalShortcutManager.shared.onHotKey?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
        
        if status != noErr {
            print("[GlobalShortcut] Failed to install event handler: \(status)")
        }
    }
}
