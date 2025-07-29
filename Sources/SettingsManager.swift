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

// ファイル名テンプレート用の変数定義
struct FilenameTemplate {
    static let defaultTemplate = "Clipboard_{yyyy}-{MM}-{dd}_{HH}-{mm}-{ss}"
    
    static let availableVariables: [(String, String)] = [
        ("{yyyy}", "年（4桁）"),
        ("{MM}", "月（2桁）"),
        ("{dd}", "日（2桁）"),
        ("{HH}", "時（24時間形式）"),
        ("{mm}", "分（2桁）"),
        ("{ss}", "秒（2桁）"),
        ("{format}", "ファイル形式（png/jpeg）")
    ]
    
    static func processTemplate(_ template: String, format: ImageFormat) -> String {
        var result = template
        let now = Date()
        
        let dateFormatter = DateFormatter()
        
        // 年
        dateFormatter.dateFormat = "yyyy"
        result = result.replacingOccurrences(of: "{yyyy}", with: dateFormatter.string(from: now))
        
        // 月
        dateFormatter.dateFormat = "MM"
        result = result.replacingOccurrences(of: "{MM}", with: dateFormatter.string(from: now))
        
        // 日
        dateFormatter.dateFormat = "dd"
        result = result.replacingOccurrences(of: "{dd}", with: dateFormatter.string(from: now))
        
        // 時
        dateFormatter.dateFormat = "HH"
        result = result.replacingOccurrences(of: "{HH}", with: dateFormatter.string(from: now))
        
        // 分
        dateFormatter.dateFormat = "mm"
        result = result.replacingOccurrences(of: "{mm}", with: dateFormatter.string(from: now))
        
        // 秒
        dateFormatter.dateFormat = "ss"
        result = result.replacingOccurrences(of: "{ss}", with: dateFormatter.string(from: now))
        
        // フォーマット
        result = result.replacingOccurrences(of: "{format}", with: format.fileExtension)
        
        return result
    }
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
    
    @Published var filenameTemplate: String {
        didSet {
            UserDefaults.standard.set(filenameTemplate, forKey: "filenameTemplate")
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
        
        // ファイル名テンプレート設定を読み込み
        self.filenameTemplate = UserDefaults.standard.string(forKey: "filenameTemplate") ?? FilenameTemplate.defaultTemplate
    }
    
    func generateFileName(format: ImageFormat? = nil) -> String {
        let useFormat = format ?? selectedFormat
        let processedTemplate = FilenameTemplate.processTemplate(filenameTemplate, format: useFormat)
        return "\(processedTemplate).\(useFormat.fileExtension)"
    }
    
    func previewFilename(format: ImageFormat? = nil) -> String {
        return generateFileName(format: format)
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