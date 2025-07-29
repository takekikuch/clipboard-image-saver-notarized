import Foundation
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // サービスプロバイダーとして登録
        NSApp.servicesProvider = self
    }
    
    // MARK: - Services Menu Handler
    
    @objc func saveImageToCurrentFolder(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        print("Services menu: saveImageToCurrentFolder called")
        
        // メインスレッドで実行
        Task { @MainActor in
            // ClipboardManagerを使用して画像保存処理を実行
            ClipboardManager.shared.saveClipboardImage()
        }
    }
}