# 📋 Clipboard Image Saver

<div align="center">

**macOS用クリップボード画像保存アプリ**

*Easily save clipboard images to the current Finder folder*

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/takekikuch/clipboard-image-saver-notarized/releases/latest)

</div>

## 📖 概要 / Overview

**日本語:**
Clipboard Image Saverは、クリップボードにコピーした画像を現在のFinderウィンドウのフォルダに簡単保存できるmacOS用メニューバーアプリです。

**English:**
Clipboard Image Saver is a macOS menu bar application that allows you to quickly save clipboard images to the current Finder window folder.

## ✨ 主な機能 / Key Features

### 🖼️ クリップボード画像保存
- **グローバルショートカット**: デフォルト `⌘+Shift+V` でどこからでも保存
- **現在フォルダに保存**: Finderで開いているフォルダに直接保存
- **複数フォーマット対応**: PNG・JPEG形式での保存
- **品質調整**: JPEG品質の調整可能

### 👀 リアルタイムプレビュー  
- **クリップボード監視**: 画像の自動検出とプレビュー表示
- **ドラッグ&ドロップ**: プレビューから直接ドラッグして保存
- **サイズ情報**: 画像サイズと保存時のファイルサイズを表示

### ⚙️ カスタマイズ機能
- **ショートカット変更**: お好みのキー組み合わせに変更可能
- **ファイル名テンプレート**: 日時や形式を含む柔軟な命名規則
- **メニューバー統合**: 常駐でアクセスしやすい

### 🔧 システム統合
- **Services統合**: 右クリックメニューから「画像をここに保存」
- **権限管理**: 初回起動時の分かりやすい権限設定ガイド
- **エラーハンドリング**: 問題発生時の詳細な案内

## 🚀 インストール方法 / Installation

### ダウンロード / Download

1. [Releases](https://github.com/takekikuch/clipboard-image-saver-notarized/releases)から最新版をダウンロード
2. `ClipboardImageSaver-x.x.x.dmg` をダウンロード
3. DMGをマウントし、アプリを`Applications`フォルダにドラッグ

### 初回設定 / Initial Setup

アプリ初回起動時に以下の権限設定が必要です：

1. **アクセシビリティ権限**
   - `システム設定` > `プライバシーとセキュリティ` > `アクセシビリティ`
   - `Clipboard Image Saver`にチェックを入れる

2. **Apple Events権限**  
   - `システム設定` > `プライバシーとセキュリティ` > `オートメーション`
   - `Clipboard Image Saver`にチェックを入れる

## 📱 使用方法 / Usage

### 基本的な使い方

1. **画像をコピー**: スクリーンショットや画像ファイルをクリップボードにコピー
2. **Finderでフォルダを開く**: 保存したいフォルダをFinderで開く
3. **ショートカット実行**: `⌘+Shift+V`を押して保存

### プレビュー機能

1. **メニューバーアイコンをクリック**: アプリメニューを開く
2. **プレビュー確認**: クリップボード内の画像を確認
3. **ドラッグ保存**: プレビューをFinderにドラッグして保存

### 設定変更

- **ショートカットキー**: アプリメニューから変更可能
- **保存フォーマット**: PNG/JPEGを選択可能
- **ファイル名**: 日時ベースのテンプレート設定

## 🛠️ 開発者向け情報 / Development

### システム要件 / System Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

### ビルド方法 / Build Instructions

```bash
# リポジトリクローン
git clone https://github.com/takekikuch/clipboard-image-saver-notarized.git
cd clipboard-image-saver-notarized

# 依存関係取得
swift package resolve

# ビルド
swift build

# 実行
./.build/debug/ClipboardImageSaver
```

### アーキテクチャ / Architecture

- **SwiftUI + MenuBarExtra**: モダンなmacOS UIフレームワーク
- **Singleton Pattern**: `SettingsManager`, `ClipboardManager`で状態管理
- **ObservableObject**: リアクティブなUI更新
- **@MainActor**: 並行性安全なUI操作

### 主要コンポーネント / Key Components

- **PermissionManager**: 権限管理・UXガイド
- **ClipboardManager**: クリップボード監視・画像処理
- **FinderIntegration**: AppleScript経由のFinder連携
- **HotKeyManager**: グローバルショートカット処理

## 🤝 コントリビューション / Contributing

プルリクエストやイシュー報告を歓迎します！

1. このリポジトリをフォーク
2. 機能ブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを開く

## 🔒 プライバシー / Privacy

このアプリは：
- クリップボードの画像データのみにアクセス
- Finderのアクティブウィンドウパスのみを取得
- データの外部送信は一切行わない
- ローカルでのみ動作

## 📄 ライセンス / License

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 🙏 謝辞 / Acknowledgments

- [HotKey](https://github.com/soffes/HotKey) - グローバルショートカット機能
- [Claude Code](https://claude.ai/code) - 開発支援AI

## 📞 サポート / Support

- **バグ報告**: [GitHub Issues](https://github.com/takekikuch/clipboard-image-saver-notarized/issues)
- **機能要望**: [GitHub Discussions](https://github.com/takekikuch/clipboard-image-saver-notarized/discussions)
- **質問**: GitHubのIssueまたはDiscussionをご利用ください

---

<div align="center">

**🚀 生産性向上にお役立てください！ / Boost your productivity!**

[⬆️ ページトップに戻る](#-clipboard-image-saver)

</div>