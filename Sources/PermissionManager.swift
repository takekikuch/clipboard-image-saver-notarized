import Foundation
import AppKit
import ApplicationServices

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var showPermissionAlert = false
    @Published var permissionAlertMessage = ""
    @Published var permissionAlertType: PermissionType = .accessibility
    
    enum PermissionType {
        case accessibility
        case appleEvents
        
        var title: String {
            switch self {
            case .accessibility:
                return "アクセシビリティ権限"
            case .appleEvents:
                return "Apple Events権限"
            }
        }
        
        var description: String {
            switch self {
            case .accessibility:
                return "グローバルショートカット（⌘+Shift+V）を使用するために必要です。"
            case .appleEvents:
                return "Finderの現在フォルダに画像を保存するために必要です。"
            }
        }
        
        var instructions: String {
            switch self {
            case .accessibility:
                return "システム設定 > プライバシーとセキュリティ > アクセシビリティ で「Clipboard Image Saver」を有効にしてください。"
            case .appleEvents:
                return "システム設定 > プライバシーとセキュリティ > オートメーション で「Clipboard Image Saver」を有効にしてください。"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Permission Checks
    
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func checkAppleEventsPermission() -> Bool {
        // Apple Eventsの権限をテスト用スクリプトで確認
        let testScript = """
        tell application "System Events"
            return "test"
        end tell
        """
        
        let appleScript = NSAppleScript(source: testScript)
        var errorDict: NSDictionary?
        let result = appleScript?.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            print("🔍 Apple Events permission check failed: \(error)")
            return false
        }
        
        return result != nil
    }
    
    // MARK: - Permission Requests
    
    func requestAccessibilityPermissionIfNeeded() {
        if !checkAccessibilityPermission() {
            showPermissionAlert(for: .accessibility)
        }
    }
    
    func requestAppleEventsPermissionIfNeeded() {
        if !checkAppleEventsPermission() {
            showPermissionAlert(for: .appleEvents)
        }
    }
    
    func checkAllPermissions() -> [PermissionType] {
        var missingPermissions: [PermissionType] = []
        
        if !checkAccessibilityPermission() {
            missingPermissions.append(.accessibility)
        }
        
        if !checkAppleEventsPermission() {
            missingPermissions.append(.appleEvents)
        }
        
        return missingPermissions
    }
    
    // MARK: - UI Management
    
    private func showPermissionAlert(for type: PermissionType) {
        permissionAlertType = type
        permissionAlertMessage = "\(type.description)\n\n\(type.instructions)"
        showPermissionAlert = true
    }
    
    func showPermissionAlertFor(_ type: PermissionType) {
        showPermissionAlert(for: type)
    }
    
    func openSystemPreferences(for type: PermissionType) {
        switch type {
        case .accessibility:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        case .appleEvents:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - First Launch Check
    
    func isFirstLaunch() -> Bool {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            return true
        }
        return false
    }
    
    func shouldShowPermissionGuide() -> Bool {
        return isFirstLaunch() || !checkAllPermissions().isEmpty
    }
}