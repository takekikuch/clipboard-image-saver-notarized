import Foundation
import AppKit

@MainActor
class FinderIntegration: ObservableObject {
    static let shared = FinderIntegration()
    
    @Published var lastError: String = ""
    @Published var showPermissionError = false
    
    private init() {
        // Apple Events権限が付与された際の通知を監視
        NotificationCenter.default.addObserver(
            forName: .appleEventsPermissionGranted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔍 FinderIntegration: Apple Events permission granted - clearing errors")
            DispatchQueue.main.async {
                self?.lastError = ""
                self?.showPermissionError = false
            }
        }
    }
    
    func getCurrentFinderWindowPath() -> String? {
        // まず権限をチェック
        let permissionManager = PermissionManager.shared
        if !permissionManager.checkAppleEventsPermission() {
            handlePermissionError()
            return getDesktopPath()
        }
        
        let script = """
        tell application "Finder"
            try
                set dir to the target of the front window
                return POSIX path of (dir as text)
            on error
                return "/"
            end try
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        
        guard let result = appleScript?.executeAndReturnError(&errorDict) else {
            if let error = errorDict {
                print("🔍 AppleScript error: \(error)")
                handleAppleScriptError(error)
            }
            return getDesktopPath()
        }
        
        guard let path = result.stringValue, !path.isEmpty else {
            print("🔍 AppleScript returned empty path, using desktop")
            return getDesktopPath()
        }
        
        // パスが "/"の場合はデスクトップパスを返す
        if path == "/" {
            print("🔍 AppleScript returned root path, using desktop")
            return getDesktopPath()
        }
        
        print("✅ Got Finder path: \(path)")
        clearError() // 成功時はエラーをクリア
        return path
    }
    
    private func handlePermissionError() {
        lastError = "Apple Eventsの権限が必要です。システム設定で「Clipboard Image Saver」を許可してください。"
        showPermissionError = true
        print("❌ Apple Events permission required")
        
        // PermissionManagerに権限要求を委譲
        Task { @MainActor in
            PermissionManager.shared.showPermissionAlertFor(.appleEvents)
        }
    }
    
    private func handleAppleScriptError(_ error: NSDictionary) {
        let errorNumber = error["NSAppleScriptErrorNumber"] as? Int ?? 0
        let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "不明なエラー"
        
        switch errorNumber {
        case -1743: // errAEEventNotHandled
            lastError = "Finderとの通信エラーです。Finderが起動していることを確認してください。"
        case -1708: // errAENoSuchObject
            lastError = "Finderのウィンドウが見つかりません。Finderウィンドウを開いてください。"
        case -1728: // errAENoUserSelection
            lastError = "Finderでフォルダが選択されていません。"
        default:
            if errorMessage.contains("permission") || errorMessage.contains("not allowed") {
                handlePermissionError()
                return
            }
            lastError = "Finder統合エラー: \(errorMessage)"
        }
        
        showPermissionError = false
        print("⚠️ AppleScript error \(errorNumber): \(errorMessage)")
    }
    
    private func clearError() {
        if !lastError.isEmpty {
            lastError = ""
            showPermissionError = false
        }
    }
    
    private func getDesktopPath() -> String {
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path
        return desktopPath ?? NSHomeDirectory() + "/Desktop"
    }
    
    func isFinderActive() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        return frontmostApp.bundleIdentifier == "com.apple.finder"
    }
}