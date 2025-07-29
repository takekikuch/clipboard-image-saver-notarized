# 📋 Clipboard Image Saver v1.0.0 - 正式リリース

**リリース日**: 2025年7月29日  
**対応OS**: macOS 13.0 以降

---

## 🎉 正式リリースのお知らせ

Clipboard Image Saverの**初回正式版**をリリースしました！クリップボード画像を現在のFinderフォルダに瞬時に保存できるmacOS用メニューバーアプリです。

## ✨ 主な機能

### 📸 **画像保存機能**
- **⌘+Shift+V** で瞬時にクリップボード画像を保存
- **現在のFinderウィンドウ**のフォルダに自動保存
- **PNG・JPEG**形式をサポート（品質調整可能）
- **カスタムファイル名**テンプレート対応

### 👀 **プレビュー機能**
- **リアルタイム**クリップボード画像表示
- **ドラッグ&ドロップ**でFinderに直接保存
- **画像サイズ・ファイルサイズ**の即座表示
- **フォーマット別**サイズプレビュー

### ⚙️ **カスタマイズ**
- **ショートカットキー**の自由変更
- **ファイル名テンプレート**のカスタマイズ
- **JPEG品質**の細かい調整
- **メニューバー**から簡単設定

### 🔧 **システム統合**
- **Services統合**: 右クリックメニューに追加
- **権限管理**: 分かりやすい設定ガイド
- **エラーハンドリング**: 詳細な問題解決案内

## 🛠️ システム要件

- **macOS 13.0** 以降
- **アクセシビリティ権限** (グローバルショートカット用)
- **Apple Events権限** (Finder統合用)

## 📥 インストール方法

### 1. ダウンロード
[**ClipboardImageSaver-1.0.0.dmg**](https://github.com/takekikuch/clipboard-image-saver-notarized/releases/latest) をダウンロード

### 2. インストール
1. DMGファイルを開く
2. `ClipboardImageSaver.app` を `Applications` フォルダにドラッグ

### 3. 初回起動
⚠️ **重要**: 未署名アプリのため、以下の手順が必要です：

**方法1 (推奨)**: 
- アプリを**右クリック** → **「開く」**を選択
- 警告ダイアログで**「開く」**をクリック

**方法2 (ターミナル)**:
```bash
sudo xattr -rd com.apple.quarantine /Applications/ClipboardImageSaver.app
```

### 4. 権限設定
初回起動時に以下の権限設定を行ってください：

1. **アクセシビリティ権限**
   - `システム設定` > `プライバシーとセキュリティ` > `アクセシビリティ`
   - `ClipboardImageSaver` にチェック

2. **Apple Events権限**
   - `システム設定` > `プライバシーとセキュリティ` > `オートメーション`
   - `ClipboardImageSaver` にチェック

## 🚀 使用方法

### 基本操作
1. **画像をコピー** (スクリーンショット、ブラウザから画像など)
2. **Finderで保存先フォルダを開く**
3. **⌘+Shift+V** を押す
4. **画像が保存されます！**

### プレビュー機能
- メニューバーアイコンをクリック
- クリップボード画像のプレビューを確認
- プレビューをドラッグしてFinderに保存

## 🔒 セキュリティとプライバシー

- **ローカル動作**: インターネット通信なし
- **最小限アクセス**: クリップボード画像とFinderパスのみ
- **オープンソース**: 全コードをGitHubで公開
- **データ収集なし**: 個人情報の収集・送信一切なし

## 📋 チェックサム

**SHA256**: `検証用チェックサムは各リリースページで確認してください`

## 🐛 既知の制限事項

- **未署名**: 初回起動時にmacOSの警告が表示されます
- **macOS 13.0未満**: 対応していません
- **権限必須**: アクセシビリティとApple Events権限が必要です

## 📞 サポート

- **バグ報告**: [GitHub Issues](https://github.com/takekikuch/clipboard-image-saver-notarized/issues)
- **機能要望**: [GitHub Discussions](https://github.com/takekikuch/clipboard-image-saver-notarized/discussions)
- **ドキュメント**: [README](https://github.com/takekikuch/clipboard-image-saver-notarized#readme)

## 🙏 謝辞

このアプリの開発にあたり、以下のオープンソースプロジェクトを使用させていただきました：

- [HotKey](https://github.com/soffes/HotKey) - グローバルショートカット機能
- [Claude Code](https://claude.ai/code) - 開発支援AI

## 🔄 今後の予定

- **Developer ID証明書**による署名対応
- **公証（Notarization）**対応  
- **App Store**配布検討
- **追加機能**の継続的開発

---

## 🎯 クイックスタート

1. [DMGをダウンロード](https://github.com/takekikuch/clipboard-image-saver-notarized/releases/latest)
2. アプリを右クリック → 「開く」
3. 権限設定（アクセシビリティ・Apple Events）
4. **⌘+Shift+V** でクリップボード画像を保存！

**🚀 あなたの作業効率向上にお役立てください！**