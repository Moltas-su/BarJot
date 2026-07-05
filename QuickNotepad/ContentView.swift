import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var state: AppState
    @FocusState private var isFocused: Bool
    @State private var isPurgeHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            if state.showClipboardDrawer {
                ClipboardDrawerView(state: state)
                    .frame(width: 250)
                    .transition(.move(edge: .leading))
                
                Divider()
            }
            
            VStack(spacing: 0) {
                TextEditor(text: $state.text)
                    .scrollContentBackground(.hidden)
                    .font(state.fontForCurrentSize())
                    .focused($isFocused)
                    .background(TextViewIntrospector())
                    .padding(.bottom, 4)
                    .foregroundColor(state.colorMode.textColor)
                
                HStack {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                state.showClipboardDrawer.toggle()
                            }
                        }) {
                            Image(systemName: state.showClipboardDrawer ? "sidebar.left" : "list.clipboard")
                                .foregroundColor(state.showClipboardDrawer ? .accentColor : state.colorMode.textColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Toggle Clipboard History Drawer")
                        
                        Text("\(state.text.count) characters  •  \(wordCount) words")
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
            .onAppear {
                isFocused = true
                state.pasteClipboardIfNeeded()
            }
        }
    }
    
    private var wordCount: Int {
        state.text.split { $0.isWhitespace }.count
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
