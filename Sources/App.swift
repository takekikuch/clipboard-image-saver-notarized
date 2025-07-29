import SwiftUI

@main
struct ClipboardImageSaverApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Clipboard Image Saver", systemImage: "doc.on.clipboard") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clipboard Image Saver")
                    .font(.headline)
                
                Divider()
                
                Text("⌘+Shift+V でクリップボード画像を保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Button("終了") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
}