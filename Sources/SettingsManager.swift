import Foundation
import AppKit

// ショートカットキーの修飾子定義
struct ShortcutModifiers: OptionSet, Codable {
    let rawValue: Int
    
    static let command = ShortcutModifiers(rawValue: 1 << 0)
    static let shift = ShortcutModifiers(rawValue: 1 << 1)
    static let option = ShortcutModifiers(rawValue: 1 << 2)
    static let control = ShortcutModifiers(rawValue: 1 << 3)
    
    var displayString: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}

// ショートカットキー設定構造体
struct ShortcutKey: Codable, Equatable {
    let modifiers: ShortcutModifiers
    let keyCode: String
    
    var displayString: String {
        return modifiers.displayString + keyCode.uppercased()
    }
    
    static let defaultShortcut = ShortcutKey(modifiers: [.command, .shift], keyCode: "v")
}

enum ImageFormat: String, CaseIterable {
    case png = "png"
    case jpeg = "jpeg"
    
    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }
    
    var fileExtension: String {
        return self.rawValue
    }
    
    var compressionType: NSBitmapImageRep.FileType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        }
    }
    
    var defaultProperties: [NSBitmapImageRep.PropertyKey: Any] {
        switch self {
        case .jpeg:
            return [.compressionFactor: 0.8] // JPEG品質設定
        default:
            return [:]
        }
    }
}

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var selectedFormat: ImageFormat {
        didSet {
            UserDefaults.standard.set(selectedFormat.rawValue, forKey: "selectedImageFormat")
        }
    }
    
    @Published var jpegQuality: Double {
        didSet {
            UserDefaults.standard.set(jpegQuality, forKey: "jpegQuality")
        }
    }
    
    @Published var shortcutKey: ShortcutKey {
        didSet {
            if let encoded = try? JSONEncoder().encode(shortcutKey) {
                UserDefaults.standard.set(encoded, forKey: "shortcutKey")
            }
        }
    }
    
    private init() {
        // UserDefaultsから設定を読み込み
        let formatString = UserDefaults.standard.string(forKey: "selectedImageFormat") ?? ImageFormat.png.rawValue
        self.selectedFormat = ImageFormat(rawValue: formatString) ?? .png
        
        let jpegQualityValue = UserDefaults.standard.double(forKey: "jpegQuality")
        self.jpegQuality = jpegQualityValue == 0 ? 0.8 : jpegQualityValue
        
        // ショートカットキー設定を読み込み
        if let shortcutData = UserDefaults.standard.data(forKey: "shortcutKey"),
           let decodedShortcut = try? JSONDecoder().decode(ShortcutKey.self, from: shortcutData) {
            self.shortcutKey = decodedShortcut
        } else {
            self.shortcutKey = ShortcutKey.defaultShortcut
        }
    }
    
    func generateFileName(format: ImageFormat? = nil) -> String {
        let useFormat = format ?? selectedFormat
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = formatter.string(from: Date())
        return "Clipboard_\(dateString).\(useFormat.fileExtension)"
    }
    
    func getCompressionProperties(for format: ImageFormat? = nil) -> [NSBitmapImageRep.PropertyKey: Any] {
        let useFormat = format ?? selectedFormat
        
        switch useFormat {
        case .jpeg:
            return [.compressionFactor: jpegQuality]
        default:
            return useFormat.defaultProperties
        }
    }
}