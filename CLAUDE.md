# CLAUDE.md

## プロジェクト概要
macOS用メニューバー常駐アプリ「Clipboard Image Saver」  
⌘+Shift+V でクリップボード画像をFinderの現在フォルダに保存

## 技術スタック
- Swift + SwiftUI
- HotKey ライブラリ（グローバルショートカット監視）
- AppleScript（Finderパス取得）

## 開発コマンド
```bash
# ビルド
swift build

# テスト実行
swift test

# Xcode起動
open Package.swift
```

## ファイル構成
```
ClipboardImageSaver/
├── Sources/
│   └── ClipboardImageSaver/
│       ├── App.swift              # メインアプリ
│       ├── MenuBarManager.swift   # メニューバー管理
│       ├── ClipboardManager.swift # クリップボード処理
│       └── FinderIntegration.swift # Finder連携
├── Package.swift
└── README.md
```

## 主要機能
1. ⌘+Shift+V 監視
2. クリップボード画像確認
3. Finderアクティブパス取得
4. PNG保存（Clipboard_yyyy-MM-dd_HH-mm-ss.png）

## 実装時の参照
実装時は `.claude/implementation-plan.md` を確認しながら進める