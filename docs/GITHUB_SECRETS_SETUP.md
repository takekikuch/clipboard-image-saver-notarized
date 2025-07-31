# GitHub Secrets設定ガイド

GitHub Actionsで署名・公証を自動化するため、以下のSecretsを設定する必要があります。

## 🔐 必要なSecrets

### 1. Apple ID関連

| Secret Name | Value | 説明 |
|-------------|-------|------|
| `APPLE_ID` | `badrb735@jttk.zaq.ne.jp` | Apple ID メールアドレス |
| `APPLE_APP_SPECIFIC_PASSWORD` | `your-app-specific-password` | App専用パスワード |
| `APPLE_TEAM_ID` | `MDH8A45XTP` | Developer Team ID |

### 2. 証明書関連

| Secret Name | Value | 説明 |
|-------------|-------|------|
| `DEVELOPER_ID_APPLICATION` | `Developer ID Application: Takeru Kikuchi (MDH8A45XTP)` | アプリ署名証明書名 |
| `DEVELOPER_ID_INSTALLER` | `Developer ID Installer: Takeru Kikuchi (MDH8A45XTP)` | インストーラー署名証明書名（オプション） |

## 📝 設定手順

### Step 1: GitHubリポジトリでSecrets設定

1. **GitHub リポジトリ**にアクセス
   - https://github.com/takekikuch/clipboard-image-saver-notarized

2. **Settings** タブをクリック

3. **Secrets and variables** > **Actions** をクリック

4. **New repository secret** をクリック

5. 上記の各Secretを順次追加

### Step 2: 証明書名の確認

```bash
# 正確な証明書名を確認
security find-identity -v -p codesigning | grep "Developer ID"
```

### Step 3: App-Specific Password確認

1. **Apple ID サイト**にログイン (appleid.apple.com)
2. **サインインとセキュリティ** > **App専用パスワード**
3. 既存のパスワードを確認、または新規作成

## 🧪 設定テスト

設定完了後、以下のコマンドでテスト可能：

```bash
# 署名版リリースタグを作成
git tag v1.0.1-signed
git push origin v1.0.1-signed
```

## 📋 Secrets設定値（参考）

現在の環境での設定値：

```bash
APPLE_ID: badrb735@jttk.zaq.ne.jp
APPLE_TEAM_ID: MDH8A45XTP
DEVELOPER_ID_APPLICATION: Developer ID Application: Takeru Kikuchi (MDH8A45XTP)
```

⚠️ **注意**: `APPLE_APP_SPECIFIC_PASSWORD`は実際のパスワードに置き換えてください。

## 🔍 設定確認

GitHub Actions実行時、以下のような出力で設定が正しいか確認できます：

```
✅ 公証プロファイル作成成功
✅ アプリケーション署名完了
✅ 公証申請完了
✅ 公証チケット添付完了
```

## 📞 トラブルシューティング

### エラー: "Invalid credentials"
- Apple IDが正しいか確認
- App-Specific Passwordが有効か確認
- Team IDが正しいか確認

### エラー: "Certificate not found"
- 証明書名が完全に一致しているか確認
- 証明書がGitHub ActionsのmacOS環境で利用可能か確認

### エラー: "Notarization failed"
- アプリが適切に署名されているか確認
- Entitlementsファイルが正しく設定されているか確認