import Foundation
import AppKit

@MainActor
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var currentImage: NSImage?
    @Published var imageInfo: String = ""
    @Published var showUserAlert = false
    @Published var userAlertMessage = ""
    private var lastChangeCount: Int = 0
    private var clipboardTimer: Timer?
    
    private init() {
        print("🔍 ClipboardManager: Initializing...")
        // 初期画像チェック（監視は開始しない）
        updateCurrentImage()
        
        // 設定変更時にサイズ表示を更新
        NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.updateImageInfo()
            }
        }
        
        print("🔍 ClipboardManager: Initialization complete")
    }
    
    func saveClipboardImage() {
        guard let image = getClipboardImage() else {
            print("❌ No image found in clipboard")
            showUserError("クリップボードに画像が見つかりません。画像をコピーしてから再度お試しください。")
            return
        }
        
        let finderIntegration = FinderIntegration.shared
        guard let finderPath = finderIntegration.getCurrentFinderWindowPath() else {
            print("❌ Could not get current Finder window path")
            
            // FinderIntegrationのエラー状態をチェック
            if finderIntegration.showPermissionError {
                // 権限エラーの場合は既にPermissionManagerが処理しているので何もしない
                return
            } else if !finderIntegration.lastError.isEmpty {
                showUserError(finderIntegration.lastError)
                return
            } else {
                showUserError("保存先フォルダを取得できませんでした。Finderでフォルダを開いてから再度お試しください。")
                return
            }
        }
        
        let settings = SettingsManager.shared
        let format = settings.selectedFormat
        
        print("🔍 saveClipboardImage: Converting image \(image.size) to \(format.displayName)")
        
        // 大きな画像の場合は安全な変換を使用
        guard let imageData = convertImageToDataSafely(image: image, format: format, properties: settings.getCompressionProperties()) else {
            print("❌ Could not convert image to \(format.displayName) data")
            return
        }
        
        let fileName = settings.generateFileName()
        let filePath = URL(fileURLWithPath: finderPath).appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: filePath)
            print("✅ Successfully saved \(format.displayName) image to: \(filePath.path) (\(imageData.count) bytes)")
        } catch {
            print("❌ Error saving image: \(error.localizedDescription)")
            showUserError("画像の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func showUserError(_ message: String) {
        print("🔍 Showing user error: \(message)")
        userAlertMessage = message
        showUserAlert = true
    }
    
    func startClipboardMonitoring() {
        guard clipboardTimer == nil else { return } // 既に開始済みの場合はスキップ
        
        lastChangeCount = NSPasteboard.general.changeCount
        print("🔍 Starting clipboard monitoring with changeCount: \(lastChangeCount)")
        
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.checkClipboardChanges()
            }
        }
        print("🔍 Clipboard timer started")
    }
    
    func stopClipboardMonitoring() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
        print("🔍 Clipboard timer stopped")
    }
    
    private func checkClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        // 変更がない場合は静かに（コメントアウトで無効化）
        // print("🔍 Checking clipboard changes: current=\(currentChangeCount), last=\(lastChangeCount)")
        
        if currentChangeCount != lastChangeCount {
            print("🔍 Clipboard changed! Updating...")
            lastChangeCount = currentChangeCount
            updateCurrentImage()
        }
    }
    
    func updateCurrentImage() {
        let newImage = getClipboardImage()
        print("🔍 ClipboardManager: updateCurrentImage called")
        print("🔍 Current image exists: \(currentImage != nil)")
        print("🔍 New image exists: \(newImage != nil)")
        
        // NSImageの比較問題を回避するため、常に更新する
        currentImage = newImage
        updateImageInfo()
        print("🔍 Updated current image and info")
    }
    
    private func updateImageInfo() {
        guard let image = currentImage else {
            print("🔍 updateImageInfo: No image, setting to '画像なし'")
            imageInfo = "画像なし"
            return
        }
        
        let size = image.size
        let width = Int(size.width)
        let height = Int(size.height)
        print("🔍 updateImageInfo: Image size \(width) × \(height)")
        
        // 設定されたフォーマットでの実際のファイルサイズを取得
        let settings = SettingsManager.shared
        let format = settings.selectedFormat
        let properties = settings.getCompressionProperties()
        
        var sizeText = ""
        if let convertedData = convertImageToDataSafely(image: image, format: format, properties: properties) {
            let bytes = convertedData.count
            if bytes < 1024 {
                sizeText = "\(bytes) bytes"
            } else if bytes < 1024 * 1024 {
                sizeText = String(format: "%.1f KB", Double(bytes) / 1024.0)
            } else {
                sizeText = String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
            }
            print("🔍 updateImageInfo: Converted size as \(format.displayName): \(sizeText)")
        } else {
            // フォールバック：TIFFサイズ
            if let tiffData = image.tiffRepresentation {
                let bytes = tiffData.count
                if bytes < 1024 {
                    sizeText = "\(bytes) bytes"
                } else if bytes < 1024 * 1024 {
                    sizeText = String(format: "%.1f KB", Double(bytes) / 1024.0)
                } else {
                    sizeText = String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
                }
                sizeText += " (TIFF)"
            }
            print("🔍 updateImageInfo: Using TIFF fallback size: \(sizeText)")
        }
        
        let newInfo = "\(width) × \(height) (\(sizeText))"
        print("🔍 updateImageInfo: Setting imageInfo to '\(newInfo)'")
        imageInfo = newInfo
    }
    
    func getClipboardImage() -> NSImage? {
        let pasteboard = NSPasteboard.general
        print("🔍 getClipboardImage: Checking clipboard...")
        print("🔍 Available types: \(pasteboard.types ?? [])")
        
        // 詳細なクリップボード内容をデバッグ
        if let types = pasteboard.types {
            for type in types {
                if let data = pasteboard.data(forType: type) {
                    print("🔍 Type \(type): \(data.count) bytes")
                }
            }
        }
        
        // 0. まずファイルURL経由での読み込みを試行（最も確実）
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileURLs {
                print("🔍 Found file URL: \(url)")
                if let image = NSImage(contentsOf: url) {
                    print("🔍 Successfully loaded original image from file URL: \(url), size: \(image.size)")
                    return ensureImageRepresentation(image)
                }
            }
        }
        
        // 1. 大きなTIFFデータを直接使用（アイコン化を回避）
        if let tiffData = pasteboard.data(forType: .tiff) {
            print("🔍 Found TIFF data: \(tiffData.count) bytes, creating image directly...")
            if let image = NSImage(data: tiffData) {
                print("🔍 Successfully created image from TIFF data, size: \(image.size)")
                
                // 元のサイズが取得できた場合は、それを優先
                let totalPixels = image.size.width * image.size.height
                if totalPixels > 1_000_000 { // 100万ピクセル以上の場合は元画像とみなす
                    print("✅ Large original image detected: \(image.size), \(totalPixels) pixels")
                    return ensureImageRepresentation(image)
                }
            }
        }
        
        // 2. NSImageオブジェクトとして直接取得を試行（小さな画像またはアイコン版）
        if let objects = pasteboard.readObjects(forClasses: [NSImage.self], options: nil),
           let image = objects.first as? NSImage {
            print("🔍 Got NSImage from pasteboard (possibly icon version), size: \(image.size)")
            
            // 小さすぎる場合は警告（アイコン版の可能性）
            let totalPixels = image.size.width * image.size.height
            if totalPixels < 1_000_000 && image.size.width == image.size.height {
                print("⚠️ Small square image detected (possibly icon): \(image.size)")
            }
            
            return ensureImageRepresentation(image)
        }
        
        // 2. 画像データフォーマット別に取得を試行（大きなデータに注意）
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .tiff, .png, 
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.png"),
            NSPasteboard.PasteboardType("public.tiff"),
            NSPasteboard.PasteboardType("com.adobe.pdf")
        ]
        
        for type in imageTypes {
            if let data = pasteboard.data(forType: type) {
                print("🔍 Found \(type) data: \(data.count) bytes")
                
                // 非常に大きなデータの場合は警告して処理をスキップ
                let maxDataSize = 100 * 1024 * 1024 // 100MB制限
                if data.count > maxDataSize {
                    print("⚠️ Data too large (\(data.count) bytes), skipping \(type)")
                    continue
                }
                
                // 段階的に画像作成を試行
                if let image = createImageSafely(from: data, type: type) {
                    print("🔍 Successfully created NSImage from \(type)")
                    return ensureImageRepresentation(image)
                }
            }
        }
        
        // 3. より広範な画像フォーマットをチェック
        if let types = pasteboard.types {
            for type in types {
                let typeString = type.rawValue.lowercased()
                if typeString.contains("image") || typeString.contains("png") || 
                   typeString.contains("jpeg") || typeString.contains("jpg") ||
                   typeString.contains("tiff") || typeString.contains("gif") ||
                   typeString.contains("bmp") {
                    print("🔍 Trying image type: \(type)")
                    if let data = pasteboard.data(forType: type),
                       let image = NSImage(data: data) {
                        print("🔍 Successfully created NSImage from \(type)")
                        return ensureImageRepresentation(image)
                    }
                }
            }
        }
        
        
        print("🔍 No image found in clipboard")
        return nil
    }
    
    private func createImageSafely(from data: Data, type: NSPasteboard.PasteboardType) -> NSImage? {
        print("🔍 createImageSafely: Creating image from \(type) data (\(data.count) bytes)")
        
        // まず通常の方法で試行
        if let image = NSImage(data: data) {
            let size = image.size
            let totalPixels = size.width * size.height
            
            print("🔍 Created image successfully, size: \(size), pixels: \(totalPixels)")
            
            // 非常に大きな画像の場合は検証
            if totalPixels > 50_000_000 { // 5000万ピクセル以上
                print("⚠️ Extremely large image, validating...")
                
                // CGImageが作成できるかテスト
                if image.cgImage(forProposedRect: nil, context: nil, hints: nil) == nil {
                    print("⚠️ Cannot create CGImage, image may be corrupted")
                    return nil
                }
            }
            
            return image
        }
        
        print("🔍 Failed to create NSImage from \(type) data")
        return nil
    }
    
    private func ensureImageRepresentation(_ image: NSImage) -> NSImage {
        print("🔍 ensureImageRepresentation: Checking image representations...")
        print("🔍 Image size: \(image.size)")
        print("🔍 Number of representations: \(image.representations.count)")
        
        for (index, rep) in image.representations.enumerated() {
            print("🔍 Representation \(index): \(type(of: rep)), size: \(rep.size)")
        }
        
        let originalSize = image.size
        guard originalSize.width > 0 && originalSize.height > 0 else {
            print("🔍 Invalid image size, returning original")
            return image
        }
        
        // 大きな画像をプレビュー用にリサイズ（最大2048px）
        let maxDimension: CGFloat = 2048
        var targetSize = originalSize
        
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
            targetSize = CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )
            print("🔍 Large image detected, resizing from \(originalSize) to \(targetSize)")
        }
        
        // CGImageを経由してより確実にビットマップを作成
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("🔍 Could not get CGImage, trying alternative method")
            return createBitmapImageAlternative(from: image, targetSize: targetSize)
        }
        
        let newImage = NSImage(cgImage: cgImage, size: targetSize)
        print("🔍 Created new image from CGImage, size: \(newImage.size)")
        print("🔍 New image representations: \(newImage.representations.count)")
        
        return newImage
    }
    
    private func createBitmapImageAlternative(from image: NSImage, targetSize: CGSize) -> NSImage {
        print("🔍 createBitmapImageAlternative: Creating bitmap using NSBitmapImageRep")
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            print("🔍 Failed to create bitmap representation")
            return image
        }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        // 白背景を描画
        NSColor.white.setFill()
        NSRect(origin: .zero, size: targetSize).fill()
        
        // 元の画像を描画（リサイズして）
        image.draw(in: NSRect(origin: .zero, size: targetSize))
        
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: targetSize)
        newImage.addRepresentation(bitmapRep)
        
        print("🔍 Created bitmap image alternative, representations: \(newImage.representations.count)")
        return newImage
    }
    
    func convertImageToDataSafely(image: NSImage, format: ImageFormat, properties: [NSBitmapImageRep.PropertyKey: Any]) -> Data? {
        print("🔍 convertImageToDataSafely: Starting conversion to \(format.displayName)")
        let size = image.size
        let totalPixels = size.width * size.height
        
        print("🔍 Image size: \(size), total pixels: \(totalPixels)")
        
        // まず通常の方法を試行
        if let data = image.imageData(format: format, properties: properties) {
            print("✅ Normal conversion succeeded: \(data.count) bytes")
            return data
        }
        
        print("⚠️ Normal conversion failed, trying alternative methods...")
        
        // 大きな画像の場合は段階的に処理
        if totalPixels > 10_000_000 { // 1000万ピクセル以上
            print("🔍 Large image detected, using chunked processing...")
            return convertLargeImageToData(image: image, format: format, properties: properties)
        }
        
        // CGImageを使った代替変換
        if let data = convertImageViaCGImage(image: image, format: format, properties: properties) {
            print("✅ CGImage conversion succeeded: \(data.count) bytes")
            return data
        }
        
        print("❌ All conversion methods failed, trying emergency fallback...")
        
        // 最後の手段：TIFFで保存してから外部変換
        return convertImageViaEmergencyFallback(image: image, format: format, properties: properties)
    }
    
    private func convertLargeImageToData(image: NSImage, format: ImageFormat, properties: [NSBitmapImageRep.PropertyKey: Any]) -> Data? {
        print("🔍 convertLargeImageToData: Processing large image")
        
        // まず品質を下げて試行（JPEGの場合）
        if format == .jpeg {
            var reducedProperties = properties
            if let currentQuality = properties[.compressionFactor] as? Double {
                let reducedQuality = max(0.3, currentQuality * 0.7) // 品質を70%に下げる
                reducedProperties[.compressionFactor] = reducedQuality
                print("🔍 Reducing JPEG quality from \(currentQuality) to \(reducedQuality)")
                
                if let data = image.imageData(format: format, properties: reducedProperties) {
                    print("✅ Reduced quality conversion succeeded: \(data.count) bytes")
                    return data
                }
            }
        }
        
        // それでも失敗する場合は画像をリサイズ
        print("🔍 Attempting to resize image for conversion...")
        let maxDimension: CGFloat = 4096 // 最大4096px
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        
        if scale < 1.0 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            print("🔍 Resizing from \(image.size) to \(newSize)")
            
            if let resizedImage = resizeImage(image: image, to: newSize) {
                if let data = resizedImage.imageData(format: format, properties: properties) {
                    print("✅ Resized image conversion succeeded: \(data.count) bytes")
                    return data
                }
            }
        }
        
        return nil
    }
    
    private func convertImageViaCGImage(image: NSImage, format: ImageFormat, properties: [NSBitmapImageRep.PropertyKey: Any]) -> Data? {
        print("🔍 convertImageViaCGImage: Using CGImage conversion")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ Cannot create CGImage")
            return nil
        }
        
        let newImage = NSImage(cgImage: cgImage, size: image.size)
        return newImage.imageData(format: format, properties: properties)
    }
    
    private func resizeImage(image: NSImage, to newSize: CGSize) -> NSImage? {
        print("🔍 resizeImage: Resizing to \(newSize)")
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func convertImageViaEmergencyFallback(image: NSImage, format: ImageFormat, properties: [NSBitmapImageRep.PropertyKey: Any]) -> Data? {
        print("🔍 convertImageViaEmergencyFallback: Emergency conversion method")
        
        // 1. まずTIFF保存を試行（最も基本的な形式）
        if let tiffData = image.tiffRepresentation {
            print("✅ TIFF representation available: \(tiffData.count) bytes")
            
            if format == .png {
                // PNG形式が必要な場合、TIFFからPNGに変換
                if let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    print("✅ Emergency PNG conversion succeeded: \(pngData.count) bytes")
                    return pngData
                }
            } else if format == .jpeg {
                // JPEG形式が必要な場合、TIFFからJPEGに変換
                if let bitmapRep = NSBitmapImageRep(data: tiffData) {
                    // より低い品質で試行
                    let emergencyProperties: [NSBitmapImageRep.PropertyKey: Any] = [
                        .compressionFactor: 0.5
                    ]
                    
                    if let jpegData = bitmapRep.representation(using: .jpeg, properties: emergencyProperties) {
                        print("✅ Emergency JPEG conversion succeeded: \(jpegData.count) bytes")
                        return jpegData
                    }
                }
            }
            
            // フォーマット変換が失敗した場合、TIFFデータを直接返す（最後の手段）
            if format == .png {
                print("⚠️ Returning TIFF data as emergency fallback")
                return tiffData
            }
        }
        
        // 2. CGImageを直接使った低レベル変換
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            print("🔍 Trying CoreGraphics direct conversion")
            
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            
            if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) {
                
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
                
                if let newCGImage = context.makeImage() {
                    let newNSImage = NSImage(cgImage: newCGImage, size: image.size)
                    
                    if let finalData = newNSImage.imageData(format: format, properties: properties) {
                        print("✅ CoreGraphics conversion succeeded: \(finalData.count) bytes")
                        return finalData
                    }
                }
            }
        }
        
        print("❌ Emergency fallback also failed")
        return nil
    }
    
    // deinitは削除 - アプリ終了時にタイマーは自動的に無効になる
    
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