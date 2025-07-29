import Foundation
import AppKit

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
    
    private init() {
        // UserDefaultsから設定を読み込み
        let formatString = UserDefaults.standard.string(forKey: "selectedImageFormat") ?? ImageFormat.png.rawValue
        self.selectedFormat = ImageFormat(rawValue: formatString) ?? .png
        
        self.jpegQuality = UserDefaults.standard.double(forKey: "jpegQuality")
        if self.jpegQuality == 0 {
            self.jpegQuality = 0.8 // デフォルト品質
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