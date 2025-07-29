import Foundation
import AppKit

@MainActor
class FinderIntegration: ObservableObject {
    static let shared = FinderIntegration()
    
    private init() {}
    
    func getCurrentFinderWindowPath() -> String? {
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
                print("AppleScript error: \(error)")
            }
            return getDesktopPath()
        }
        
        guard let path = result.stringValue, !path.isEmpty else {
            return getDesktopPath()
        }
        
        // パスが "/"の場合はデスクトップパスを返す
        if path == "/" {
            return getDesktopPath()
        }
        
        return path
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