import SwiftUI
import AppKit

#if canImport(Sparkle)
import Sparkle
#endif

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    let popover = NSPopover()
    let appState = AppState()
    private var isShowingContextMenu = false
    private var settingsWindow: NSWindow?
    
    #if canImport(Sparkle)
    var updaterController: SPUStandardUpdaterController?
    #endif
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if canImport(Sparkle)
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        #endif
        
        // 1. Configure the popover
        popover.behavior = appState.alwaysOnTop ? .applicationDefined : .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ContentView(state: appState)
        )
        let baseSize = appState.popoverSize.dimensions
        let initialWidth = appState.showClipboardDrawer ? baseSize.width + 250 : baseSize.width
        popover.contentSize = NSSize(width: initialWidth, height: baseSize.height)
        
        // 2. Listen for state changes
        appState.onPopoverSizeChanged = { [weak self] newSize in
            guard let self else { return }
            let baseSize = newSize.dimensions
            let newWidth = self.appState.showClipboardDrawer ? baseSize.width + 250 : baseSize.width
            self.popover.contentSize = NSSize(width: newWidth, height: baseSize.height)
            self.popover.contentViewController = NSHostingController(
                rootView: ContentView(state: self.appState)
            )
        }
        
        appState.onAlwaysOnTopChanged = { [weak self] isAlwaysOnTop in
            guard let self else { return }
            self.popover.behavior = isAlwaysOnTop ? .applicationDefined : .transient
            if isAlwaysOnTop {
                self.popover.contentViewController?.view.window?.level = .floating
            } else {
                self.popover.contentViewController?.view.window?.level = .normal
            }
        }
        
        appState.onDrawerStateChanged = { [weak self] isOpen in
            guard let self else { return }
            let baseSize = self.appState.popoverSize.dimensions
            let newWidth = isOpen ? baseSize.width + 250 : baseSize.width
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.allowsImplicitAnimation = true
                self.popover.contentSize = NSSize(width: newWidth, height: baseSize.height)
            }
        }
        
        // 3. Setup the Menu Bar Icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "✍︎"
            button.image = nil
            button.action = #selector(handleStatusItemAction)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // 4. Setup global shortcut
        setupGlobalShortcut()
    }
    
    // MARK: - Global Shortcut
    
    private func setupGlobalShortcut() {
        GlobalShortcutManager.shared.onHotKey = { [weak self] in
            self?.togglePopover()
        }
        
        // Re-register saved shortcut
        if appState.globalShortcutEnabled, appState.globalShortcutKeyCode != 0 {
            GlobalShortcutManager.shared.registerShortcut(
                keyCode: appState.globalShortcutKeyCode,
                modifiers: appState.globalShortcutModifiers
            )
        }
    }
    
    // MARK: - Status Item Actions
    
    @objc func handleStatusItemAction() {
        guard let button = statusItem?.button else { return }
        
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp ||
                           (event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true)
        
        if isRightClick {
            showContextMenu(from: button)
        } else {
            togglePopover()
        }
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            appState.cancelClear()
            popover.behavior = appState.alwaysOnTop ? .applicationDefined : .transient
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Always-on-top support
            if appState.alwaysOnTop {
                popover.contentViewController?.view.window?.level = .floating
            } else {
                popover.contentViewController?.view.window?.level = .normal
            }
            
            popover.contentViewController?.view.window?.makeKey()
            
            // Play open sound
            if appState.playSoundEffects {
                NSSound(named: "Pop")?.play()
            }
        }
    }
    
    // MARK: - Context Menu
    
    func showContextMenu(from button: NSButton) {
        if popover.isShown {
            isShowingContextMenu = true
            popover.performClose(nil)
        }
        
        let menu = NSMenu()
        
        let headerItem = NSMenuItem(title: "BarJot", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Quick color mode submenu
        let colorMenu = NSMenu()
        for mode in ColorMode.allCases {
            let item = NSMenuItem(title: mode.rawValue, action: #selector(selectColorMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.state = appState.colorMode == mode ? .on : .off
            colorMenu.addItem(item)
        }
        
        let colorSubmenuItem = NSMenuItem(title: "Color Mode", action: nil, keyEquivalent: "")
        colorSubmenuItem.submenu = colorMenu
        menu.addItem(colorSubmenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit BarJot",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        let positioningPoint = NSPoint(x: 0, y: button.bounds.height + 4)
        menu.popUp(positioning: nil, at: positioningPoint, in: button)
        isShowingContextMenu = false
    }
    
    // MARK: - Actions
    
    @objc func selectColorMode(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? ColorMode {
            appState.colorMode = mode
        }
    }
    
    @objc func openSettings() {
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }
        
        let settingsView = SettingsView(state: appState)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "BarJot Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate()
        
        settingsWindow = window
    }
    
    @objc func quitApp() {
        GlobalShortcutManager.shared.unregisterShortcut()
        NSApp.terminate(nil)
    }
    
    // MARK: - Popover Delegate
    
    func popoverDidClose(_ notification: Notification) {
        if !isShowingContextMenu {
            appState.scheduleClear()
        }
    }
}
