import Foundation
import AppKit
@preconcurrency import HotKey

@MainActor
class HotKeyManager: ObservableObject {
    private var hotKey: HotKey?
    private let settingsManager = SettingsManager.shared
    
    init() {
        setupHotKey()
    }
    
    func setupHotKey() {
        // 既存のホットキーを無効化
        hotKey = nil
        
        let shortcut = settingsManager.shortcutKey
        
        // キーコードをHotKey.Keyに変換
        guard let hotKeyKey = convertToHotKeyKey(shortcut.keyCode) else {
            print("Unsupported key code: \(shortcut.keyCode)")
            return
        }
        
        // 修飾子をHotKey.Modifiersに変換
        let hotKeyModifiers = convertToHotKeyModifiers(shortcut.modifiers)
        
        hotKey = HotKey(key: hotKeyKey, modifiers: hotKeyModifiers)
        
        hotKey?.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.handleShortcut()
            }
        }
    }
    
    private func convertToHotKeyKey(_ keyCode: String) -> Key? {
        switch keyCode.lowercased() {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case "0": return .zero
        default: return nil
        }
    }
    
    private func convertToHotKeyModifiers(_ shortcutModifiers: ShortcutModifiers) -> NSEvent.ModifierFlags {
        var hotKeyModifiers: NSEvent.ModifierFlags = []
        
        if shortcutModifiers.contains(.command) {
            hotKeyModifiers.insert(.command)
        }
        if shortcutModifiers.contains(.shift) {
            hotKeyModifiers.insert(.shift)
        }
        if shortcutModifiers.contains(.option) {
            hotKeyModifiers.insert(.option)
        }
        if shortcutModifiers.contains(.control) {
            hotKeyModifiers.insert(.control)
        }
        
        return hotKeyModifiers
    }
    
    func updateShortcut() {
        setupHotKey()
    }
    
    private func handleShortcut() {
        let shortcut = settingsManager.shortcutKey
        print("\(shortcut.displayString) pressed - starting clipboard image save process")
        
        ClipboardManager.shared.saveClipboardImage()
    }
    
    deinit {
        hotKey = nil
    }
}