import SwiftUI
import AppKit
import ServiceManagement
import Carbon.HIToolbox

// MARK: - Color Mode

enum ColorMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
    case nord = "Nord"
    case forest = "Forest"
    case liquidGlass = "Liquid Glass"
    
    nonisolated var id: String { self.rawValue }
    
    var backgroundColor: Color {
        switch self {
        case .system:
            return Color(NSColor.textBackgroundColor)
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .dark:
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .sepia:
            return Color(red: 0.96, green: 0.93, blue: 0.88)
        case .nord:
            return Color(red: 0.18, green: 0.20, blue: 0.25)
        case .forest:
            return Color(red: 0.10, green: 0.15, blue: 0.12)
        case .liquidGlass:
            return Color.clear
        }
    }
    
    var textColor: Color {
        switch self {
        case .system:
            return Color(NSColor.labelColor)
        case .light:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .dark:
            return Color(red: 0.9, green: 0.9, blue: 0.9)
        case .sepia:
            return Color(red: 0.26, green: 0.19, blue: 0.11)
        case .nord:
            return Color(red: 0.88, green: 0.91, blue: 0.93)
        case .forest:
            return Color(red: 0.85, green: 0.90, blue: 0.87)
        case .liquidGlass:
            return Color.primary
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system, .liquidGlass:
            return nil
        case .light, .sepia:
            return .light
        case .dark, .nord, .forest:
            return .dark
        }
    }
}

// MARK: - Font Size

enum FontSize: Int, CaseIterable, Identifiable {
    case small = 13
    case medium = 16
    case large = 20
    case extraLarge = 24
    
    nonisolated var id: Int { self.rawValue }
    
    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

// MARK: - Popover Size

enum PopoverSize: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case standard = "Standard"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    nonisolated var id: String { self.rawValue }
    
    var dimensions: NSSize {
        switch self {
        case .compact: return NSSize(width: 280, height: 200)
        case .standard: return NSSize(width: 320, height: 240)
        case .large: return NSSize(width: 400, height: 320)
        case .extraLarge: return NSSize(width: 480, height: 400)
        }
    }
}

// MARK: - Purge Delay

enum PurgeDelay: Int, CaseIterable, Identifiable {
    case immediate = 0
    case fiveSeconds = 5
    case tenSeconds = 10
    case thirtySeconds = 30
    case never = -1
    
    nonisolated var id: Int { self.rawValue }
    
    var label: String {
        switch self {
        case .immediate: return "Immediately"
        case .fiveSeconds: return "After 5 seconds"
        case .tenSeconds: return "After 10 seconds"
        case .thirtySeconds: return "After 30 seconds"
        case .never: return "Never"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .immediate: return "Purges immediately"
        case .fiveSeconds: return "Purges in 5s"
        case .tenSeconds: return "Purges in 10s"
        case .thirtySeconds: return "Purges in 30s"
        case .never: return "Never purges"
        }
    }
}

// MARK: - App State

@Observable
class AppState {
    var text: String = ""
    
    var colorMode: ColorMode = .liquidGlass {
        didSet {
            UserDefaults.standard.set(colorMode.rawValue, forKey: "colorMode")
        }
    }
    
    private var isUpdatingLaunchAtLogin = false
    var launchAtLogin: Bool = false {
        didSet {
            guard !isUpdatingLaunchAtLogin else { return }
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin(launchAtLogin)
        }
    }
    
    var fontSize: FontSize = .medium {
        didSet {
            UserDefaults.standard.set(fontSize.rawValue, forKey: "fontSize")
        }
    }
    
    var popoverSize: PopoverSize = .standard {
        didSet {
            UserDefaults.standard.set(popoverSize.rawValue, forKey: "popoverSize")
            onPopoverSizeChanged?(popoverSize)
        }
    }
    
    var autoPasteClipboard: Bool = false {
        didSet {
            UserDefaults.standard.set(autoPasteClipboard, forKey: "autoPasteClipboard")
        }
    }
    
    var alwaysOnTop: Bool = false {
        didSet {
            UserDefaults.standard.set(alwaysOnTop, forKey: "alwaysOnTop")
            onAlwaysOnTopChanged?(alwaysOnTop)
        }
    }
    
    var playSoundEffects: Bool = true {
        didSet {
            UserDefaults.standard.set(playSoundEffects, forKey: "playSoundEffects")
        }
    }
    
    var enableClipboardHistory: Bool = true {
        didSet {
            UserDefaults.standard.set(enableClipboardHistory, forKey: "enableClipboardHistory")
            if enableClipboardHistory {
                ClipboardManager.shared.startWatching()
            } else {
                ClipboardManager.shared.stopWatching()
            }
        }
    }
    
    var showClipboardDrawer: Bool = false {
        didSet {
            onDrawerStateChanged?(showClipboardDrawer)
        }
    }
    
    var purgeDelay: PurgeDelay = .fiveSeconds {
        didSet {
            UserDefaults.standard.set(purgeDelay.rawValue, forKey: "purgeDelay")
        }
    }
    
    @ObservationIgnored private var purgeWorkItem: DispatchWorkItem?
    
    // Keyboard shortcut components
    var globalShortcutKeyCode: UInt32 = 0 {
        didSet {
            UserDefaults.standard.set(globalShortcutKeyCode, forKey: "globalShortcutKeyCode")
        }
    }
    var globalShortcutModifiers: UInt32 = 0 {
        didSet {
            UserDefaults.standard.set(globalShortcutModifiers, forKey: "globalShortcutModifiers")
        }
    }
    var globalShortcutEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(globalShortcutEnabled, forKey: "globalShortcutEnabled")
        }
    }
    
    /// Callback for when the popover size changes - set by AppDelegate.
    @ObservationIgnored
    var onPopoverSizeChanged: ((PopoverSize) -> Void)?
    
    /// Callback for when always on top changes - set by AppDelegate.
    @ObservationIgnored
    var onAlwaysOnTopChanged: ((Bool) -> Void)?
    
    /// Callback for when clipboard drawer state changes.
    @ObservationIgnored
    var onDrawerStateChanged: ((Bool) -> Void)?
    
    init() {
        if UserDefaults.standard.object(forKey: "hasSeenTutorial") == nil {
            self.text = """
            Welcome to BarJot! 👋
            
            This is your lightning fast scratchpad. It lives in your menu bar so it's always ready when you need to jot something down.
            
            Here are a few pro-tips to get you started:
            
             📋 Clipboard History: Click the sidebar icon below to open your clipboard drawer. It silently saves everything you copy so you can pull it in later!
             📌 Sticky Note: Go to Settings (gear icon) and turn on "Always on Top" to keep this window open while you work in other apps.
             🎨 Themes: Check out Settings (gear icon) to switch between gorgeous themes like Nord, Forest, and Sepia!
             💥 Auto-Purge: Heads up! When you click away to close this window, your text will automatically be deleted. You can also click the "Purges..." text in the bottom right to clear it manually.
            
            Go ahead and delete this text to get started. Happy scribbling!
            """
            UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        }
        
        // Load font size
        if let savedFontSize = FontSize(rawValue: UserDefaults.standard.integer(forKey: "fontSize")),
           savedFontSize != .medium || UserDefaults.standard.object(forKey: "fontSize") != nil {
            self.fontSize = savedFontSize
        }
        
        // Load other persisted settings
        if let savedColorMode = UserDefaults.standard.string(forKey: "colorMode"),
           let mode = ColorMode(rawValue: savedColorMode) {
            self.colorMode = mode
        }
        
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        
        if let savedPopoverSize = UserDefaults.standard.string(forKey: "popoverSize"),
           let pSize = PopoverSize(rawValue: savedPopoverSize) {
            self.popoverSize = pSize
        }
        
        if UserDefaults.standard.object(forKey: "autoPasteClipboard") != nil {
            self.autoPasteClipboard = UserDefaults.standard.bool(forKey: "autoPasteClipboard")
        }
        
        if UserDefaults.standard.object(forKey: "alwaysOnTop") != nil {
            self.alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        }
        
        if UserDefaults.standard.object(forKey: "playSoundEffects") != nil {
            self.playSoundEffects = UserDefaults.standard.bool(forKey: "playSoundEffects")
        } else {
            self.playSoundEffects = true
        }
        
        self.globalShortcutKeyCode = UInt32(UserDefaults.standard.integer(forKey: "globalShortcutKeyCode"))
        self.globalShortcutModifiers = UInt32(UserDefaults.standard.integer(forKey: "globalShortcutModifiers"))
        if UserDefaults.standard.object(forKey: "globalShortcutEnabled") != nil {
            self.globalShortcutEnabled = UserDefaults.standard.bool(forKey: "globalShortcutEnabled")
        }
        
        if let savedPurgeDelay = PurgeDelay(rawValue: UserDefaults.standard.integer(forKey: "purgeDelay")),
           UserDefaults.standard.object(forKey: "purgeDelay") != nil {
            self.purgeDelay = savedPurgeDelay
        }
        
        if UserDefaults.standard.object(forKey: "enableClipboardHistory") != nil {
            self.enableClipboardHistory = UserDefaults.standard.bool(forKey: "enableClipboardHistory")
        }
        
        if self.enableClipboardHistory {
            ClipboardManager.shared.startWatching()
        }
    }
    
    func clear() {
        if !text.isEmpty {
            text = ""
            if playSoundEffects {
                if let customSoundURL = Bundle.main.url(forResource: "Trash_crumble", withExtension: "mp3"),
                   let sound = NSSound(contentsOf: customSoundURL, byReference: true) {
                    sound.play()
                } else {
                    let trashSoundPath = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder/empty trash.aif"
                    if let trashSound = NSSound(contentsOfFile: trashSoundPath, byReference: true) {
                        trashSound.play()
                    } else {
                        NSSound(named: "Tink")?.play()
                    }
                }
            }
        }
    }
    
    func scheduleClear() {
        purgeWorkItem?.cancel()
        
        if purgeDelay == .immediate {
            clear()
        } else if purgeDelay.rawValue > 0 {
            let workItem = DispatchWorkItem { [weak self] in
                self?.clear()
            }
            purgeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(purgeDelay.rawValue), execute: workItem)
        }
    }
    
    func cancelClear() {
        purgeWorkItem?.cancel()
        purgeWorkItem = nil
    }
    
    /// Returns a font for the current fontSize setting.
    func fontForCurrentSize() -> Font {
        let size = CGFloat(fontSize.rawValue)
        if NSFont(name: "Tiempos", size: size) != nil {
            return .custom("Tiempos", size: size)
        } else if NSFont(name: "Tiempos Text", size: size) != nil {
            return .custom("Tiempos Text", size: size)
        } else {
            return .system(size: size, weight: .regular, design: .serif)
        }
    }
    
    /// Returns an NSFont for the current fontSize setting.
    func nsFontForCurrentSize() -> NSFont {
        let size = CGFloat(fontSize.rawValue)
        if let font = NSFont(name: "Tiempos", size: size) {
            return font
        } else if let font = NSFont(name: "Tiempos Text", size: size) {
            return font
        } else {
            return NSFont.systemFont(ofSize: size)
        }
    }
    
    /// Pastes clipboard text content if auto-paste is enabled.
    func pasteClipboardIfNeeded() {
        guard autoPasteClipboard, text.isEmpty else { return }
        if let clipboardString = NSPasteboard.general.string(forType: .string),
           !clipboardString.isEmpty {
            text = clipboardString
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                }
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            isUpdatingLaunchAtLogin = true
            launchAtLogin = service.status == .enabled
            isUpdatingLaunchAtLogin = false
        }
    }
    
    /// Human-readable description of the current global shortcut.
    var globalShortcutDescription: String {
        guard globalShortcutEnabled, globalShortcutKeyCode != 0 else {
            return "Not Set"
        }
        
        var parts: [String] = []
        let mods = globalShortcutModifiers
        if mods & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if mods & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if mods & UInt32(optionKey) != 0 { parts.append("⌥") }
        if mods & UInt32(controlKey) != 0 { parts.append("⌃") }
        
        let keyString = keyCodeToString(globalShortcutKeyCode)
        parts.append(keyString)
        
        return parts.joined()
    }
}

// MARK: - Key Code Mapping

func keyCodeToString(_ keyCode: UInt32) -> String {
    let mapping: [UInt32: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
        0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
        0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
        0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
        0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
        0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
        0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
        0x25: "L", 0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
        0x2E: "M", 0x31: "Space", 0x24: "Return", 0x30: "Tab",
        0x33: "Delete", 0x35: "Esc",
        0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
        0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
        0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
    ]
    return mapping[keyCode] ?? "Key\(keyCode)"
}
