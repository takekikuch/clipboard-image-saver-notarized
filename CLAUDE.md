# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要
macOS用メニューバー常駐アプリ「Clipboard Image Saver」  
⌘+Shift+V でクリップボード画像をFinderの現在フォルダにPNG/JPEG形式で保存  
リアルタイムクリップボード画像プレビューとドラッグ&ドロップ機能付き

**配布方針**: macOS App Store外での公証付き配布向け開発版  
- 元リポジトリ: https://github.com/takekikuch/clipboard-image-saver （App Store版開発用に保持）
- 現リポジトリ: 公証付きdmg/pkg配布用の最適化版

## 開発コマンド
```bash
# ビルド
swift build

# 実行
./.build/debug/ClipboardImageSaver

# Xcode起動（GUI開発時）
open Package.swift

# アプリ停止
pkill -f ClipboardImageSaver
```

## アーキテクチャ概要

### コア設計パターン
- **SwiftUI + MenuBarExtra**: macOS 13.0+のメニューバーアプリ
- **ObservableObject**: 状態管理とリアルタイムUI更新
- **Singleton Pattern**: 共有マネージャー (`SettingsManager.shared`, `ClipboardManager.shared`)
- **Delegate Pattern**: NSServices統合用のAppDelegate

### 主要コンポーネント連携
```
App.swift (メインUI)
├── ClipboardPreviewSection → ClipboardManager (プレビュー・監視)
├── HotKeyManager → ClipboardManager.saveClipboardImage()
├── SettingsManager → ImageFormat設定・永続化・通知
└── AppDelegate → NSServices経由でClipboardManager呼び出し

ClipboardManager (核となるクリップボードハンドリング)
├── リアルタイム監視 (0.5秒間隔Timer, ポップアップ表示時のみ)
├── 大きな画像の段階的処理 (ファイルURL優先 → TIFF → フォールバック)
├── convertImageToDataSafely() (複数段階の変換フォールバック)
└── ドラッグ&ドロップ用ConfiguredImageTransfer
```

### クリップボード画像取得の階層戦略
1. **ファイルURL経由**: 最も確実（元解像度保持）
2. **大きなTIFFデータ**: 100万ピクセル以上を優先
3. **NSImageオブジェクト**: 小さな画像・アイコン版検出
4. **データフォーマット別**: TIFF,PNG,JPEG,PDF対応
5. **広範フォーマット**: 文字列マッチによる画像タイプ検出

### 大きな画像処理の特殊対応
- **プレビュー用リサイズ**: 最大2048px制限
- **変換フォールバック**: 通常変換 → 品質調整 → リサイズ → CGImage → 緊急TIFF
- **メモリ制限**: 100MB超データのスキップ
- **段階的検証**: 5000万ピクセル以上でCGImage作成テスト

### 依存関係
- **HotKey (0.2.1)**: グローバルショートカット監視
- **macOS 13.0+**: MenuBarExtra, @MainActor対応
- **macOS 14.0+**: ドラッグ&ドロップ (.draggable)
- **権限**: Apple Events (AppleScript), Accessibility (HotKey)

## 主要設定ファイル

### Info.plist 重要設定
- `LSUIElement: true` - Dockアイコン非表示
- `NSServices` - 右クリック「画像をここに保存」メニュー
- `NSAppleEventsUsageDescription` - Finder統合用権限

### UserDefaults キー
- `selectedImageFormat`: PNG/JPEG選択状態
- `jpegQuality`: JPEG品質 (0.1-1.0)
- `shortcutKey`: カスタムショートカット設定
- `filenameTemplate`: ファイル名テンプレート

## 並行性 (@MainActor)
- **SettingsManager**: UI更新用・NotificationCenter通知
- **ClipboardManager**: NSPasteboard操作・Timer監視用  
- **HotKeyManager**: HotKeyライブラリとの連携用
- **FinderIntegration**: AppleScript実行用

## ドラッグ&ドロップ実装詳細
- **ConfiguredImageTransfer**: Transferable準拠、設定従属の事前変換
- **DraggableImageModifier**: macOS 14.0+条件付きドラッグ機能
- **同期的データ変換**: MainActorコンフリクト回避のため初期化時変換

## フォーマット拡張
新しい画像フォーマット追加は`SettingsManager.swift`の`ImageFormat` enumに追加し、
`NSImage.imageData()`で対応する`NSBitmapImageRep.FileType`を実装

## デバッグとトラブルシューティング
- 🔍プレフィックスの詳細ログが各段階で出力される
- 大きな画像での問題は`convertImageToDataSafely()`の段階的フォールバックで対処
- クリップボード監視はポップアップ表示時のみ動作（バッテリー最適化）