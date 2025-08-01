# ClipboardImageSaver 1.0.2 (権限問題修正版)

## 🔧 バグ修正 / Bug Fixes

### 初回起動時の権限設定問題を修正
- **問題**: 初回起動でアクセシビリティ権限を設定後、⌘+Shift+V が動作せず、カスタムコマンドを再保存する必要があった
- **修正**: 権限付与を自動検知し、即座にホットキーを再初期化する仕組みを追加

## ✨ 改善点 / Improvements

- **自動権限監視**: 権限付与後5秒以内に自動検知・機能有効化
- **UI改善**: より分かりやすい初回起動時の権限案内
- **リアルタイム更新**: 権限状態変更時の即座なUI反映
- **通知機能**: 「設定後、自動で有効になります」の案内追加

## 📥 ダウンロード / Download

- **DMG (署名・公証済み)**: [ClipboardImageSaver-1.0.2-fixed.dmg](https://github.com/takekikuch/clipboard-image-saver-notarized/releases/download/v1.0.2-signed/ClipboardImageSaver-1.0.2-fixed.dmg)

## 📋 チェックサム / Checksums

- **SHA256**: `317c0ed83e24e360e8155b3755e85145d83b6420419ff3828fd862d0d5ba67a5`
- **ファイルサイズ**: 224K

## 🔧 インストール方法 / Installation

1. DMGファイルをダウンロード
2. DMGをマウントし、ClipboardImageSaver.appをApplicationsフォルダにドラッグ  
3. **通常通りダブルクリックで起動可能**（警告なし🎊）
4. 初回起動時に権限設定を行う（アクセシビリティ・Apple Events）
5. **権限設定後、即座にショートカットが有効になります**（再保存不要）

## ✨ 主な機能 / Features

- **グローバルショートカット**: ⌘+Shift+V でクリップボード画像を保存
- **リアルタイムプレビュー**: クリップボード画像の即座な表示  
- **ドラッグ&ドロップ**: プレビューから直接保存
- **フォーマット選択**: PNG・JPEG形式での保存
- **カスタマイズ**: ショートカットキー・ファイル名テンプレート変更可能

## 🛠️ システム要件 / System Requirements

- macOS 13.0 以降
- アクセシビリティ権限
- Apple Events権限

## 🔒 セキュリティ / Security

- ✅ **Developer ID証明書**による署名
- ✅ **Apple公証済み**（Gatekeeper承認）  
- ✅ **Hardened Runtime**対応
- ✅ **オープンソース**コード公開

## 📞 サポート / Support

バグ報告や機能要望は[Issues](https://github.com/takekikuch/clipboard-image-saver-notarized/issues)からお願いします。

---

**🎊 初回起動時の権限設定問題を完全修正！もう再保存は不要です。**
