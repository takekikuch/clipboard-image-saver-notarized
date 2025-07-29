import Foundation
import AppKit

@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    private init() {}
    
    func saveClipboardImage() {
        guard let image = getClipboardImage() else {
            print("No image found in clipboard")
            return
        }
        
        guard let finderPath = FinderIntegration.shared.getCurrentFinderWindowPath() else {
            print("Could not get current Finder window path")
            return
        }
        
        let settings = SettingsManager.shared
        let format = settings.selectedFormat
        
        guard let imageData = image.imageData(format: format, properties: settings.getCompressionProperties()) else {
            print("Could not convert image to \(format.displayName) data")
            return
        }
        
        let fileName = settings.generateFileName()
        let filePath = URL(fileURLWithPath: finderPath).appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: filePath)
            print("Successfully saved \(format.displayName) image to: \(filePath.path)")
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
    
    private func getClipboardImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        // TIFFデータから画像を取得
        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData) {
            return image
        }
        
        // PNGデータから画像を取得
        if let pngData = pasteboard.data(forType: .png),
           let image = NSImage(data: pngData) {
            return image
        }
        
        // JPEG/JPGデータから画像を取得（NSPasteboard.PasteboardType.jpeg は存在しないため削除）
        
        return nil
    }
    
}

extension NSImage {
    func imageData(format: ImageFormat, properties: [NSBitmapImageRep.PropertyKey: Any] = [:]) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapImage.representation(using: format.compressionType, properties: properties)
    }
    
    // 後方互換性のためにpngData()メソッドを残す
    func pngData() -> Data? {
        return imageData(format: .png)
    }
}