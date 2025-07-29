# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-29

### 🎉 Initial Release

#### Added
- **メニューバー常駐アプリ**: macOS 13.0+対応のMenuBarExtraアプリ
- **グローバルショートカット**: ⌘+Shift+V（カスタマイズ可能）でクリップボード画像を保存
- **リアルタイムプレビュー**: クリップボード内画像の自動検出と表示
- **ドラッグ&ドロップ**: プレビューから直接Finderにドラッグして保存
- **複数フォーマット対応**: PNG・JPEG形式での保存（品質調整可能）
- **Finder統合**: 現在のFinderウィンドウのフォルダに自動保存
- **Services統合**: 右クリックメニューから「画像をここに保存」
- **カスタマイズ機能**:
  - ショートカットキーの変更
  - ファイル名テンプレート（日時ベース）
  - JPEG品質調整
- **権限管理システム**: 分かりやすい権限設定ガイド
- **エラーハンドリング**: 詳細なエラー情報とユーザーガイダンス

#### Technical Features
- **SwiftUI + MenuBarExtra**: モダンなmacOS UIフレームワーク
- **@MainActor対応**: スレッドセーフなUI操作
- **Singleton Pattern**: 効率的な状態管理
- **ObservableObject**: リアクティブなUI更新
- **AppleScript統合**: Finder連携
- **NSServices統合**: システムサービス提供

#### System Requirements
- macOS 13.0 以降
- アクセシビリティ権限（グローバルショートカット用）
- Apple Events権限（Finder統合用）

#### Known Limitations
- このバージョンは未署名です
- 初回起動時にGatekeeperの警告が表示されます
- 本格的な配布には Developer ID 証明書による署名が推奨されます

### Security
- ローカルでのみ動作（外部通信なし）
- クリップボードの画像データのみにアクセス
- Finderのアクティブウィンドウパスのみを取得
- オープンソース（GitHubで公開）

---

## Development History

### Beta Releases (0.9.x)
- 0.9.5-beta: GitHub Actions自動化リリースパイプライン完成
- 0.9.4-beta: CI環境対応DMG作成
- 0.9.3-beta: AppleScript CI環境スキップ対応
- 0.9.2-beta: Swift並行性エラー修正
- 0.9.1-beta: MainActor並行性対応
- 0.9.0-beta: Phase 2 パッケージング戦略実装完了

### Implementation Phases
- **Phase 1**: 基盤システム構築（権限管理・エラーハンドリング）
- **Phase 2**: 配布パッケージング（DMG・GitHub Actions・自動化）
- **Phase 3**: プロモーション戦略（予定）