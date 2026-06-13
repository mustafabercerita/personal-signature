import AppKit
import Carbon

final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()
    
    private var hotKeyRef: EventHotKeyRef?
    var action: (() -> Void)?
    
    private init() {
        setupHotKey()
    }
    
    private func setupHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.signature == OSType(1) {
                DispatchQueue.main.async {
                    GlobalShortcutManager.shared.action?()
                }
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
        
        // Register Option + Command + S
        // kVK_ANSI_S is 0x01
        let keyCode: UInt32 = 0x01
        let modifiers = UInt32(cmdKey | optionKey)
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1)
        hotKeyID.id = UInt32(1)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
