# 📋 Clipboard Image Saver 実装計画

## 🎯 最新技術スタック確認結果

- [x] **SwiftUI MenuBarExtra** (macOS 13.0+): ✅ 最新かつ最適
- [x] **HotKey 0.2.1**: ✅ SPM対応、安定版
- [x] **NSPasteboard + AppleScript**: ✅ 現行推奨手法

## 📋 実装手順

### 1. プロジェクト初期化
- [x] Swift Package作成（`swift package init --type executable`）
- [x] Package.swiftにHotKey依存関係追加
- [x] Info.plistで必要entitlements設定（Apple Events）

### 2. メインアプリ構造
- [x] SwiftUI App with MenuBarExtra実装
- [x] `systemImage: "doc.on.clipboard"`でアイコン設定
- [x] 「終了」メニューのみ表示

### 3. HotKey設定
- [x] ⌘+Shift+V (Command+Shift+V) 監視
- [x] keyDownHandlerでクリップボード処理トリガー
- [x] メインスレッドで実行

### 4. クリップボード処理
- [x] NSPasteboard.generalでクリップボードアクセス
- [x] `data(forType: .tiff)`で画像データ取得
- [x] NSImageで画像変換・検証

### 5. Finder統合
- [x] NSAppleScriptでFinderアクティブウィンドウパス取得
- [x] エラーハンドリング（Finderが非アクティブ時）
- [x] POSIXパス形式で取得

### 6. PNG保存機能
- [x] 現在時刻でファイル名生成 (`Clipboard_yyyy-MM-dd_HH-mm-ss.png`)
- [x] NSImageからPNGデータ変換
- [x] FileManagerでファイル書き込み

### 7. エラーハンドリング・権限
- [x] アクセシビリティ権限チェック
- [x] Apple Eventsエンタイトルメント設定
- [ ] ユーザー通知（UserNotifications）

### 8. ファイル構成
- [x] Sources/ClipboardImageSaver/App.swift（MenuBarExtra + main）
- [ ] Sources/ClipboardImageSaver/MenuBarManager.swift（メニューバー管理）※不要
- [x] Sources/ClipboardImageSaver/HotKeyManager.swift（⌘+Shift+V 監視）
- [x] Sources/ClipboardImageSaver/ClipboardManager.swift（クリップボード処理）
- [x] Sources/ClipboardImageSaver/FinderIntegration.swift（AppleScript統合）
- [ ] Sources/ClipboardImageSaver/FileManager.swift（PNG保存処理）※不要

### 9. テスト・検証
- [ ] 各機能の単体テスト
- [ ] 権限フロー確認
- [ ] エラーケーステスト

この計画で最新のmacOS開発手法に準拠した堅牢なアプリが作成できるにゃ！