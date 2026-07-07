import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var state: AppState
    @FocusState private var isFocused: Bool
    @State private var isPurgeHovered: Bool = false
    /// Debounced display values to avoid re-computing stats on every keystroke.
    @State private var displayedCharCount: Int = 0
    @State private var displayedWordCount: Int = 0
    @State private var statsDebounceTask: Task<Void, Never>? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            if state.showClipboardDrawer {
                ClipboardDrawerView(state: state)
                    .frame(width: 250)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                
                Divider()
                    .transition(.opacity)
            }
            
            VStack(spacing: 0) {
                TextEditor(text: $state.text)
                    .scrollContentBackground(.hidden)
                    .font(state.fontForCurrentSize())
                    .focused($isFocused)
                    .background(TextViewIntrospector())
                    .foregroundColor(state.colorMode.textColor)
                
                HStack {
                    HStack(spacing: 12) {
                        Button(action: {
                            state.showClipboardDrawer.toggle()
                        }) {
                            Image(systemName: state.showClipboardDrawer ? "sidebar.left" : "list.clipboard")
                                .foregroundColor(state.showClipboardDrawer ? .accentColor : state.colorMode.textColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Toggle Clipboard History Drawer")
                        
                        Button(action: {
                            state.isHeld.toggle()
                        }) {
                            Image(systemName: state.isHeld ? "pin.fill" : "pin")
                                .foregroundColor(state.isHeld ? .accentColor : state.colorMode.textColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help(state.isHeld ? "Unpin window (currently held open)" : "Pin window open while you copy things")
                        
                        Text("\(displayedCharCount) characters  •  \(displayedWordCount) words")
                            .font(.system(size: 10, weight: .light))
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(state.text, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("Copy all")
                        
                        Button(action: {
                            if let clipboardString = NSPasteboard.general.string(forType: .string) {
                                state.text = clipboardString
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .buttonStyle(.plain)
                        .help("Paste (replaces all)")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.clear()
                    }) {
                        Text(state.purgeDelay.shortLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .underline()
                            .foregroundColor(state.colorMode.textColor.opacity(isPurgeHovered ? 1.0 : 0.6))
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isPurgeHovered = hovering
                    }
                    .help("Clear text immediately and start fresh")
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .frame(
                width: state.popoverSize.dimensions.width,
                height: state.popoverSize.dimensions.height
            )
            .background(state.colorMode.backgroundColor)
            .preferredColorScheme(state.colorMode.colorScheme)
            // Opt the main panel out of the drawer animation so the toolbar
            // and button icon swap stay completely static during the transition.
            .animation(nil, value: state.showClipboardDrawer)
            .onAppear {
                isFocused = true
                state.pasteClipboardIfNeeded()
                updateStats()
            }
            .onChange(of: state.text) { _, _ in
                // Debounce stats update — avoids iterating the full string on every keystroke.
                statsDebounceTask?.cancel()
                statsDebounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    updateStats()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.showClipboardDrawer)
    }
    
    private func updateStats() {
        displayedCharCount = state.text.count
        displayedWordCount = state.text.split { $0.isWhitespace }.count
    }
}

struct ClipboardDrawerView: View {
    var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(state.colorMode.textColor.opacity(0.8))
                
                Spacer()
                
                if state.enableClipboardHistory && !ClipboardManager.shared.history.isEmpty {
                    Button(action: {
                        ClipboardManager.shared.clearHistory()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(state.colorMode.textColor.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Clear clipboard history")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(state.colorMode.backgroundColor.opacity(0.2))
            
            Divider()
            
            if !state.enableClipboardHistory {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("History is disabled in Settings.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else if ClipboardManager.shared.history.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clipboard")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No history yet.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(ClipboardManager.shared.history, id: \.self) { item in
                            Button(action: {
                                if state.text.isEmpty || state.text.hasSuffix(" ") || state.text.hasSuffix("\n") {
                                    state.text += item
                                } else {
                                    state.text += " " + item
                                }
                            }) {
                                Text(item)
                                    .lineLimit(3)
                                    .font(.system(size: 11))
                                    .foregroundColor(state.colorMode.textColor)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .background(state.colorMode.backgroundColor.opacity(0.7))
    }
}

struct TextViewIntrospector: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            findAndConfigureTextView(in: window.contentView)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func findAndConfigureTextView(in view: NSView?) {
        guard let view = view else { return }
        if let scrollView = view as? NSScrollView, let textView = scrollView.documentView as? NSTextView {
            textView.textContainerInset = NSSize(width: 12, height: 12)
            scrollView.drawsBackground = false
            scrollView.scrollerStyle = .overlay
            scrollView.autohidesScrollers = true
            
            // Lazy layout: only lay out the visible portion of a large document,
            // dramatically reducing RAM usage with large notes.
            textView.layoutManager?.allowsNonContiguousLayout = true
            
            // Force layout update so the cursor moves to the new inset position
            if let container = textView.textContainer {
                textView.layoutManager?.textContainerChangedGeometry(container)
            }
            textView.needsDisplay = true
        } else {
            for subview in view.subviews {
                findAndConfigureTextView(in: subview)
            }
        }
    }
}
