# 📋 Clipboard Image Saver

macOS用のメニューバー常駐アプリ。クリップボードの画像をFinderの現在のフォルダに瞬時に保存できます。

## ✨ 機能

- **メニューバー常駐**: シンプルなメニューバーアプリとして動作
- **グローバルショートカット**: `⌘+Shift+V` で画像保存
- **右クリックメニュー**: Finderの「サービス」メニューから「画像をここに保存」
- **自動ファイル名**: `Clipboard_yyyy-MM-dd_HH-mm-ss.png` 形式で保存
- **Finder統合**: アクティブなFinderウィンドウのフォルダに保存

## 🔧 技術スタック

- **Swift + SwiftUI**
- **MenuBarExtra** (macOS 13.0+)
- **HotKey** ライブラリ (グローバルショートカット)
- **NSPasteboard** (クリップボードアクセス)
- **AppleScript** (Finder統合)
- **NSServices** (右クリックメニュー統合)

## 📦 インストール

### 前提条件
- macOS 13.0以降
- Xcode または Swift開発環境

### ビルド手順

```bash
# リポジトリをクローン
git clone <repository-url>
cd clipboard-image-saver

# ビルド
swift build

# 実行
./.build/debug/ClipboardImageSaver
```

## 🚀 使用方法

### 1. ショートカットキーで保存
1. 画像をクリップボードにコピー（スクリーンショットなど）
2. Finderで保存したいフォルダを開く
3. `⌘+Shift+V` を押す
4. 画像がそのフォルダに自動保存される

### 2. 右クリックメニューから保存
1. 画像をクリップボードにコピー
2. Finderで保存したいフォルダを開く
3. フォルダ内で右クリック → 「サービス」 → 「画像をここに保存」

## ⚙️ 権限設定

初回実行時に以下の権限が必要です：

- **Apple Events**: Finder統合のため
- **アクセシビリティ**: グローバルショートカットのため

## 📁 プロジェクト構成

```
Sources/
├── App.swift              # メインアプリ（MenuBarExtra）
├── AppDelegate.swift      # Servicesメニュー処理
├── HotKeyManager.swift    # ⌘+Shift+V 監視
├── ClipboardManager.swift # クリップボード処理
└── FinderIntegration.swift # Finder統合（AppleScript）
```

## 🔒 プライバシー

このアプリは：
- クリップボードの画像データのみにアクセス
- Finderのアクティブウィンドウパスのみを取得
- データの外部送信は一切行わない
- ローカルでのみ動作

## 📄 ライセンス

MIT License

## 🐛 Issue・要望

バグ報告や機能要望はGitHubのIssuesでお願いします。

---

🐱 Created with Claude Code