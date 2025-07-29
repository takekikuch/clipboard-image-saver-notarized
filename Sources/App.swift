import SwiftUI

struct ShortcutKeySelector: View {
    @Binding var selectedShortcut: ShortcutKey
    let hotKeyManager: HotKeyManager
    
    @State private var showingPopover = false
    @State private var tempModifiers: ShortcutModifiers
    @State private var tempKeyCode: String
    
    init(selectedShortcut: Binding<ShortcutKey>, hotKeyManager: HotKeyManager) {
        self._selectedShortcut = selectedShortcut
        self.hotKeyManager = hotKeyManager
        self._tempModifiers = State(initialValue: selectedShortcut.wrappedValue.modifiers)
        self._tempKeyCode = State(initialValue: selectedShortcut.wrappedValue.keyCode)
    }
    
    var availableKeys: [String] {
        return ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
                "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
                "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    }
    
    var body: some View {
        HStack {
            Button(selectedShortcut.displayString) {
                tempModifiers = selectedShortcut.modifiers
                tempKeyCode = selectedShortcut.keyCode
                showingPopover = true
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $showingPopover) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ショートカットキーを設定")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("修飾子")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("⌘ Command", isOn: Binding(
                                get: { tempModifiers.contains(.command) },
                                set: { if $0 { tempModifiers.insert(.command) } else { tempModifiers.remove(.command) } }
                            ))
                            Toggle("⇧ Shift", isOn: Binding(
                                get: { tempModifiers.contains(.shift) },
                                set: { if $0 { tempModifiers.insert(.shift) } else { tempModifiers.remove(.shift) } }
                            ))
                            Toggle("⌥ Option", isOn: Binding(
                                get: { tempModifiers.contains(.option) },
                                set: { if $0 { tempModifiers.insert(.option) } else { tempModifiers.remove(.option) } }
                            ))
                            Toggle("⌃ Control", isOn: Binding(
                                get: { tempModifiers.contains(.control) },
                                set: { if $0 { tempModifiers.insert(.control) } else { tempModifiers.remove(.control) } }
                            ))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("キー")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("キー", selection: $tempKeyCode) {
                            ForEach(availableKeys, id: \.self) { key in
                                Text(key.uppercased()).tag(key)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("プレビュー: \(ShortcutKey(modifiers: tempModifiers, keyCode: tempKeyCode).displayString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("キャンセル") {
                            showingPopover = false
                        }
                        
                        Button("保存") {
                            let newShortcut = ShortcutKey(modifiers: tempModifiers, keyCode: tempKeyCode)
                            selectedShortcut = newShortcut
                            hotKeyManager.updateShortcut()
                            showingPopover = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(tempModifiers.isEmpty)
                    }
                }
                .padding()
                .frame(width: 280)
            }
            
            Spacer()
        }
    }
}

struct FilenameTemplateEditor: View {
    @Binding var template: String
    @State private var showingPopover = false
    @State private var tempTemplate: String
    
    init(template: Binding<String>) {
        self._template = template
        self._tempTemplate = State(initialValue: template.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button("テンプレート編集") {
                    tempTemplate = template
                    showingPopover = true
                }
                .buttonStyle(.bordered)
                .popover(isPresented: $showingPopover) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ファイル名テンプレート設定")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("テンプレート")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("テンプレート", text: $tempTemplate)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 300)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("利用可能な変数")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(FilenameTemplate.availableVariables, id: \.0) { variable, description in
                                    HStack {
                                        Text(variable)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.blue)
                                            .onTapGesture {
                                                tempTemplate += variable
                                            }
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("プレビュー")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(FilenameTemplate.processTemplate(tempTemplate, format: .png) + ".png")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Button("リセット") {
                                tempTemplate = FilenameTemplate.defaultTemplate
                            }
                            
                            Spacer()
                            
                            Button("キャンセル") {
                                showingPopover = false
                            }
                            
                            Button("保存") {
                                template = tempTemplate
                                showingPopover = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .frame(width: 350)
                }
                
                Spacer()
            }
            
            Text("現在: \(SettingsManager.shared.previewFilename())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

@main
struct ClipboardImageSaverApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Clipboard Image Saver", systemImage: "doc.on.clipboard") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Clipboard Image Saver")
                    .font(.headline)
                
                Divider()
                
                Text("\(settingsManager.shortcutKey.displayString) でクリップボード画像を保存")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // ショートカットキー設定セクション
                VStack(alignment: .leading, spacing: 6) {
                    Text("ショートカットキー")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ShortcutKeySelector(selectedShortcut: $settingsManager.shortcutKey, hotKeyManager: hotKeyManager)
                }
                
                Divider()
                
                // ファイル名設定セクション
                VStack(alignment: .leading, spacing: 6) {
                    Text("ファイル名設定")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    FilenameTemplateEditor(template: $settingsManager.filenameTemplate)
                }
                
                Divider()
                
                // フォーマット選択セクション
                VStack(alignment: .leading, spacing: 6) {
                    Text("保存フォーマット")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $settingsManager.selectedFormat) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // JPEG品質設定（JPEGが選択されている場合のみ表示）
                    if settingsManager.selectedFormat == .jpeg {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("JPEG品質: \(Int(settingsManager.jpegQuality * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $settingsManager.jpegQuality, in: 0.1...1.0, step: 0.1)
                                .frame(width: 120)
                        }
                    }
                }
                
                Divider()
                
                Button("終了") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
            .frame(minWidth: 200)
        }
        .menuBarExtraStyle(.window)
    }
}