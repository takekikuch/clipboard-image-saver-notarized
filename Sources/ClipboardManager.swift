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
        
        guard let pngData = image.pngData() else {
            print("Could not convert image to PNG data")
            return
        }
        
        let fileName = generateFileName()
        let filePath = URL(fileURLWithPath: finderPath).appendingPathComponent(fileName)
        
        do {
            try pngData.write(to: filePath)
            print("Successfully saved image to: \(filePath.path)")
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
    
    private func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = formatter.string(from: Date())
        return "Clipboard_\(dateString).png"
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapImage.representation(using: .png, properties: [:])
    }
}