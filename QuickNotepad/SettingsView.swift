import SwiftUI
import Carbon.HIToolbox

#if canImport(Sparkle)
import Sparkle
#endif

// MARK: - Helper Views

struct SettingLabel: View {
    let title: String
    let helpText: String?
    
    init(_ title: String, help: String? = nil) {
        self.title = title
        self.helpText = help
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            if helpText != nil {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
            }
        }
        .help(helpText ?? "")
    }
}

// MARK: - Settings Window

struct SettingsView: View {
    @Bindable var state: AppState
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case appearance = "Appearance"
        case about = "About"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintpalette"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab(state: state)
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)
            
            AppearanceSettingsTab(state: state)
                .tabItem {
                    Label(SettingsTab.appearance.rawValue, systemImage: SettingsTab.appearance.icon)
                }
                .tag(SettingsTab.appearance)
            
            AboutSettingsTab(state: state)
                .tabItem {
                    Label(SettingsTab.about.rawValue, systemImage: SettingsTab.about.icon)
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 460, height: 340)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @Bindable var state: AppState
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $state.launchAtLogin) {
                    SettingLabel("Launch at Login", help: "Automatically start BarJot when you turn on your Mac.")
                }
                
                Toggle(isOn: $state.alwaysOnTop) {
                    SettingLabel("Always on Top", help: "Keep the notepad floating above all other apps, so it stays open even when you click away.")
                }
                
                Toggle(isOn: $state.autoPasteClipboard) {
                    SettingLabel("Auto-paste Clipboard", help: "If your notepad is empty, automatically paste whatever you most recently copied when opening BarJot.")
                }
                
                Toggle(isOn: $state.playSoundEffects) {
                    SettingLabel("Sound Effects", help: "Play a satisfying crunch when purging text, and a pop when opening the window.")
                }
                
                Picker(selection: $state.purgeDelay) {
                    ForEach(PurgeDelay.allCases) { delay in
                        Text(delay.label)
                            .tag(delay)
                    }
                } label: {
                    SettingLabel("Clear Note on Close", help: "Choose how long to wait before permanently deleting your note after closing the window.")
                }
            } header: {
                Text("Behavior")
            }
            
            Section {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    ShortcutRecorderView(state: state)
                        .frame(width: 160)
                }
            } header: {
                Text("Keyboard")
            } footer: {
                Text("Click the field and press your desired key combination to set a global shortcut.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Toggle(isOn: $state.enableClipboardHistory) {
                    SettingLabel("Enable Clipboard History", help: "Continuously saves copied text in the background so you can access it later from the drawer.")
                }
                
                if state.enableClipboardHistory {
                    Button("Clear History") {
                        ClipboardManager.shared.clearHistory()
                    }
                }
            } header: {
                Text("Clipboard")
            } footer: {
                Text("History is saved locally and only keeps the last 50 items to save memory.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Tab

struct AppearanceSettingsTab: View {
    @Bindable var state: AppState
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $state.colorMode) {
                    ForEach(ColorMode.allCases) { mode in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(mode.backgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5)
                                )
                                .frame(width: 16, height: 16)
                            Text(mode.rawValue)
                        }
                        .tag(mode)
                    }
                } label: {
                    SettingLabel("Color Mode", help: "Choose a beautiful theme. Liquid Glass uses the native macOS transparent blur effect.")
                }
                
                Picker(selection: $state.popoverSize) {
                    ForEach(PopoverSize.allCases) { size in
                        Text("\(size.rawValue) (\(Int(size.dimensions.width))×\(Int(size.dimensions.height)))")
                            .tag(size)
                    }
                } label: {
                    SettingLabel("Popover Size", help: "Change the physical dimensions of the notepad window.")
                }
            } header: {
                Text("Theme")
            }
            
            Section {
                Picker(selection: $state.fontSize) {
                    ForEach(FontSize.allCases) { size in
                        Text("\(size.label) (\(size.rawValue)pt)")
                            .tag(size)
                    }
                } label: {
                    SettingLabel("Font Size", help: "Adjust the size of the text in the editor.")
                }
            } header: {
                Text("Typography")
            } footer: {
                Text("Uses Tiempos if installed, otherwise falls back to the system serif font.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                ThemePreviewView(state: state)
                    .frame(height: 80)
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Theme Preview

struct ThemePreviewView: View {
    var state: AppState
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(state.colorMode.backgroundColor)
            .overlay(
                VStack(alignment: .leading, spacing: 6) {
                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(state.fontForCurrentSize())
                        .foregroundColor(state.colorMode.textColor)
                    HStack {
                        Text("47 characters  •  9 words")
                            .font(.system(size: 9, weight: .light))
                        Spacer()
                        Text(state.purgeDelay.shortLabel)
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(state.colorMode.textColor.opacity(0.4))
                }
                .padding(12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
}



// MARK: - About Tab

struct AboutSettingsTab: View {
    @Bindable var state: AppState
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("✍︎")
                .font(.system(size: 64, weight: .light))
                .padding(.bottom, 8)
            
            VStack(spacing: 4) {
                Text("BarJot")
                    .font(.title2.bold())
                Text("Version \(appVersion)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            #if canImport(Sparkle)
            VStack(spacing: 6) {
                Button("Check for Updates…") {
                    if let appDelegate = NSApp.delegate as? AppDelegate,
                       let updaterController = appDelegate.updaterController {
                        updaterController.checkForUpdates(nil)
                    }
                }
                .buttonStyle(.link)
                
                Toggle(isOn: $state.autoCheckForUpdates) {
                    Text("Automatically check for updates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }
            .padding(.top, -8)
            #endif
            
            Text("A lightweight menu bar notepad for quick notes that purge automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Spacer()
            
            Text("Made by Moltas")
                .font(.caption)
                .foregroundStyle(.quaternary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shortcut Recorder

struct ShortcutRecorderView: View {
    @Bindable var state: AppState
    @State private var isRecording = false
    
    var body: some View {
        HStack(spacing: 6) {
            if isRecording {
                Text("Press keys…")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
            } else if state.globalShortcutEnabled {
                Text(state.globalShortcutDescription)
                    .font(.system(size: 12, design: .rounded).bold())
            } else {
                Text("Click to record")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))
            }
            
            Spacer()
            
            if state.globalShortcutEnabled && !isRecording {
                Button {
                    state.globalShortcutEnabled = false
                    state.globalShortcutKeyCode = 0
                    state.globalShortcutModifiers = 0
                    GlobalShortcutManager.shared.unregisterShortcut()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isRecording ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isRecording ? Color.accentColor : Color.primary.opacity(0.15), lineWidth: 1)
        )
        .onTapGesture {
            isRecording = true
        }
        .background {
            if isRecording {
                ShortcutKeyListener { keyCode, modifierFlags in
                    // Escape cancels recording
                    if keyCode == 0x35 {
                        isRecording = false
                        return
                    }
                    
                    // Require at least one modifier
                    let carbonMods = nsEventToCarbonModifiers(modifierFlags)
                    guard carbonMods != 0 else { return }
                    
                    state.globalShortcutKeyCode = UInt32(keyCode)
                    state.globalShortcutModifiers = carbonMods
                    state.globalShortcutEnabled = true
                    isRecording = false
                    
                    GlobalShortcutManager.shared.registerShortcut(
                        keyCode: UInt32(keyCode),
                        modifiers: carbonMods
                    )
                }
            }
        }
    }
}

// MARK: - Key Listener (NSEvent based)

struct ShortcutKeyListener: NSViewRepresentable {
    let onKey: @MainActor (_ keyCode: UInt16, _ modifierFlags: NSEvent.ModifierFlags) -> Void
    
    func makeNSView(context: Context) -> KeyListenerView {
        let view = KeyListenerView()
        view.onKey = onKey
        // Schedule first responder assignment for after the view is in the window
        Task { @MainActor in
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: KeyListenerView, context: Context) {
        nsView.onKey = onKey
    }
}

class KeyListenerView: NSView {
    var onKey: ((_ keyCode: UInt16, _ modifierFlags: NSEvent.ModifierFlags) -> Void)?
    
    override nonisolated var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        onKey?(event.keyCode, event.modifierFlags)
    }
}

// MARK: - Modifier Conversion

func nsEventToCarbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
    var carbonMods: UInt32 = 0
    if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
    if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
    if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
    if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
    return carbonMods
}
