import AppKit

@Observable
class ClipboardManager {
    static let shared = ClipboardManager()
    
    var history: [String] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    private let maxItems = 50
    
    private init() {
        // Load history from UserDefaults
        if let saved = UserDefaults.standard.stringArray(forKey: "clipboardHistory") {
            self.history = saved
        }
    }
    
    func startWatching() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let newString = pasteboard.string(forType: .string),
           !newString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            // Don't add if it's already the most recent item
            if history.first != newString {
                DispatchQueue.main.async {
                    // Remove duplicates further down to bring it to top
                    self.history.removeAll { $0 == newString }
                    
                    self.history.insert(newString, at: 0)
                    if self.history.count > self.maxItems {
                        self.history.removeLast()
                    }
                    UserDefaults.standard.set(self.history, forKey: "clipboardHistory")
                }
            }
        }
    }
    
    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: "clipboardHistory")
    }
}
