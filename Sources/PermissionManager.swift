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
    
    private init() {
        // 権限変更を監視するタイマーを設定（初回起動時のみ）
        startPermissionMonitoring()
    }
    
    private var permissionTimer: Timer?
    private var lastAccessibilityStatus = false
    private var lastAppleEventsStatus = false
    
    private func startPermissionMonitoring() {
        // 初期状態を記録
        lastAccessibilityStatus = checkAccessibilityPermission()
        lastAppleEventsStatus = checkAppleEventsPermission()
        
        // 5秒間隔で権限状態をチェック（初回起動後60秒間のみ）
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let currentAccessibility = self.checkAccessibilityPermission()
                let currentAppleEvents = self.checkAppleEventsPermission()
                
                // アクセシビリティ権限が新たに付与された場合
                if !self.lastAccessibilityStatus && currentAccessibility {
                    print("✅ Accessibility permission granted - refreshing hotkey setup")
                    NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
                    self.lastAccessibilityStatus = currentAccessibility
                }
                
                // Apple Events権限が新たに付与された場合
                if !self.lastAppleEventsStatus && currentAppleEvents {
                    print("✅ Apple Events permission granted")
                    NotificationCenter.default.post(name: .appleEventsPermissionGranted, object: nil)
                    self.lastAppleEventsStatus = currentAppleEvents
                }
                
                // 両方の権限が付与されたら監視終了
                if currentAccessibility && currentAppleEvents {
                    print("✅ All permissions granted - stopping permission monitoring")
                    timer.invalidate()
                    self.permissionTimer = nil
                }
            }
        }
        
        // 60秒後に監視を自動終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            Task { @MainActor in
                self?.permissionTimer?.invalidate()
                self?.permissionTimer = nil
                print("⏰ Permission monitoring timeout - stopping")
            }
        }
    }
    
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
    
    deinit {
        permissionTimer?.invalidate()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
    static let appleEventsPermissionGranted = Notification.Name("appleEventsPermissionGranted")
}