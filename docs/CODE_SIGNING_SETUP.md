# コード署名・公証セットアップガイド

## 📋 必要な証明書

### 1. Developer ID Application Certificate (必須)
App Store外配布用のアプリケーション署名証明書

### 2. Developer ID Installer Certificate (DMG署名用)
インストーラーパッケージ署名用証明書

## 🔧 証明書取得手順

### Step 1: Apple Developer サイトで証明書要求

1. **Apple Developer Portal**にログイン
   - https://developer.apple.com/account/

2. **Certificates, Identifiers & Profiles**を選択

3. **Certificates** > **+** (Create a Certificate)

4. **Developer ID Application**を選択
   - App Store外配布用アプリ署名

5. **Developer ID Installer**も同様に作成
   - DMG/PKG署名用

### Step 2: 証明書署名要求(CSR)作成

```bash
# キーチェーンアクセスで証明書署名要求を作成
# 1. キーチェーンアクセス.app を開く
# 2. メニュー: キーチェーンアクセス > 証明書アシスタント > 認証局に証明書を要求
# 3. メールアドレス・通称名を入力
# 4. 「ディスクに保存」「鍵ペア情報を指定」をチェック
# 5. 鍵のサイズ: 2048ビット、アルゴリズム: RSA
```

### Step 3: 証明書ダウンロードとインストール

1. Apple Developer Portalで証明書をダウンロード
2. ダブルクリックでキーチェーンにインストール
3. ターミナルで確認:

```bash
# Developer ID証明書確認
security find-identity -v -p codesigning | grep "Developer ID"
```

## 🔐 App-Specific Password設定

公証には専用のApp-Specific Passwordが必要:

1. **Apple ID サイト**にログイン (appleid.apple.com)
2. **サインインとセキュリティ** > **App専用パスワード**
3. **パスワードを生成** 
4. ラベル: "ClipboardImageSaver Notarization"
5. 生成されたパスワードを保存

## 📝 公証情報設定

```bash
# Apple ID情報を環境変数に設定
export APPLE_ID="your-apple-id@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="your-app-specific-password"
export APPLE_TEAM_ID="your-team-id"

# または ~/.zshrc に追加
echo 'export APPLE_ID="your-apple-id@example.com"' >> ~/.zshrc
echo 'export APPLE_APP_SPECIFIC_PASSWORD="your-app-specific-password"' >> ~/.zshrc
echo 'export APPLE_TEAM_ID="your-team-id"' >> ~/.zshrc
```

## 🧪 署名テスト

```bash
# 署名可能か確認
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
         --options runtime \
         --entitlements ClipboardImageSaver.entitlements \
         /path/to/ClipboardImageSaver.app

# 署名確認
codesign --verify --verbose /path/to/ClipboardImageSaver.app
spctl --assess --verbose /path/to/ClipboardImageSaver.app
```

## 📦 公証テスト

```bash
# ZIP作成
ditto -c -k --keepParent ClipboardImageSaver.app ClipboardImageSaver.zip

# 公証申請
xcrun notarytool submit ClipboardImageSaver.zip \
                  --apple-id "$APPLE_ID" \
                  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
                  --team-id "$APPLE_TEAM_ID" \
                  --wait

# 公証結果を確認
xcrun notarytool info SUBMISSION_ID \
                  --apple-id "$APPLE_ID" \
                  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
                  --team-id "$APPLE_TEAM_ID"
```

## 🔒 GitHub Secrets設定

署名情報をGitHub Actionsで使用するため、以下のSecretsを設定:

```bash
# Repository Settings > Secrets and variables > Actions

APPLE_ID                    # Apple ID メールアドレス
APPLE_APP_SPECIFIC_PASSWORD # App専用パスワード
APPLE_TEAM_ID              # Developer Team ID
DEVELOPER_ID_APPLICATION   # Developer ID Application証明書名
DEVELOPER_ID_INSTALLER     # Developer ID Installer証明書名
```

## 次のステップ

1. 証明書取得完了後、`sign_and_notarize.sh`スクリプトを更新
2. GitHub Actionsワークフローに署名ステップ追加
3. 署名版テストリリース実行