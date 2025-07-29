import Foundation
@preconcurrency import HotKey

@MainActor
class HotKeyManager: ObservableObject {
    private var hotKey: HotKey?
    
    init() {
        setupHotKey()
    }
    
    private func setupHotKey() {
        // ⌘+Shift+V の設定
        hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        
        hotKey?.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.handleShortcut()
            }
        }
    }
    
    private func handleShortcut() {
        print("⌘+Shift+V pressed - starting clipboard image save process")
        
        ClipboardManager.shared.saveClipboardImage()
    }
    
    deinit {
        hotKey = nil
    }
}