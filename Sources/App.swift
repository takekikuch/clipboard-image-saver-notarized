import SwiftUI

@main
struct ClipboardImageSaverApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Clipboard Image Saver", systemImage: "doc.on.clipboard") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Clipboard Image Saver")
                    .font(.headline)
                
                Divider()
                
                Text("⌘+Shift+V でクリップボード画像を保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // フォーマット選択セクション
                VStack(alignment: .leading, spacing: 6) {
                    Text("保存フォーマット")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $settingsManager.selectedFormat) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // JPEG品質設定（JPEGが選択されている場合のみ表示）
                    if settingsManager.selectedFormat == .jpeg {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("JPEG品質: \(Int(settingsManager.jpegQuality * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $settingsManager.jpegQuality, in: 0.1...1.0, step: 0.1)
                                .frame(width: 120)
                        }
                    }
                }
                
                Divider()
                
                Button("終了") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
            .frame(minWidth: 200)
        }
        .menuBarExtraStyle(.window)
    }
}