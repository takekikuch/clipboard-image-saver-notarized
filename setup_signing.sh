#!/bin/bash
# ClipboardImageSaver - 署名環境セットアップスクリプト

set -e

echo "🔧 署名環境セットアップ"
echo "========================"

# 環境変数読み込み
source ~/.zshrc

echo "📋 現在の設定確認:"
echo "APPLE_ID: ${APPLE_ID}"
echo "APPLE_TEAM_ID: ${APPLE_TEAM_ID}"
echo "パスワード設定: $([ -n "$APPLE_APP_SPECIFIC_PASSWORD" ] && echo "✅ OK" || echo "❌ 未設定")"
echo ""

# Developer ID証明書確認
echo "🔍 Developer ID証明書確認:"
DEV_ID_CERT=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1)
if [ -n "$DEV_ID_CERT" ]; then
    echo "✅ 証明書発見: $DEV_ID_CERT"
    CERT_NAME=$(echo "$DEV_ID_CERT" | sed 's/.*"\(.*\)"/\1/')
    echo "証明書名: $CERT_NAME"
else
    echo "❌ Developer ID Application証明書が見つかりません"
    exit 1
fi
echo ""

# 公証プロファイル作成
echo "🔐 公証プロファイル作成:"
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ] || [ -z "$APPLE_TEAM_ID" ]; then
    echo "❌ 環境変数が不足しています"
    echo "必要な変数: APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID"
    exit 1
fi

echo "Apple ID: $APPLE_ID でプロファイル作成中..."
xcrun notarytool store-credentials "notarytool-profile" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID"

if [ $? -eq 0 ]; then
    echo "✅ 公証プロファイル 'notarytool-profile' 作成完了"
else
    echo "❌ 公証プロファイル作成失敗"
    echo "以下を確認してください:"
    echo "1. Apple IDが正しいか"
    echo "2. App-Specific Passwordが有効か"
    echo "3. Team IDが正しいか"
    exit 1
fi
echo ""

# 署名スクリプト設定確認
echo "📝 署名スクリプト設定確認:"
SCRIPT_PATH="scripts/sign_and_notarize.sh"
if [ -f "$SCRIPT_PATH" ]; then
    echo "✅ 署名スクリプト存在: $SCRIPT_PATH"
    
    # 証明書名をスクリプトに設定
    sed -i '' "s|DEVELOPER_ID=\".*\"|DEVELOPER_ID=\"$CERT_NAME\"|" "$SCRIPT_PATH"
    echo "✅ 証明書名を更新: $CERT_NAME"
else
    echo "❌ 署名スクリプトが見つかりません: $SCRIPT_PATH"
    exit 1
fi
echo ""

echo "🎉 署名環境セットアップ完了！"
echo "次の手順:"
echo "1. ./scripts/sign_and_notarize.sh でローカル署名テスト"
echo "2. GitHub Secretsを設定してCI対応"
echo "3. 署名版リリースを作成"