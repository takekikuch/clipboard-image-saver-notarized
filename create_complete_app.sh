#!/bin/bash
# ClipboardImageSaver - 完全なアプリバンドル作成・署名・公証スクリプト

set -e

# 設定
APP_NAME="ClipboardImageSaver"
APP_VERSION="1.0.0"
DEVELOPER_ID="Developer ID Application: Takeru Kikuchi (MDH8A45XTP)"
BUILD_DIR=".build/release"
DIST_DIR="dist"

# カラー出力用
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "🚀 Complete App Bundle Creation"
echo "==============================="

# クリーンアップ
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ビルド
log_info "Building application..."
swift build -c release

# .appバンドル構造作成
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 実行ファイルコピー
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 完全なInfo.plist作成
log_info "Creating complete Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClipboardImageSaver</string>
    <key>CFBundleIdentifier</key>
    <string>com.takekikuch.clipboardimagesaver</string>
    <key>CFBundleName</key>
    <string>Clipboard Image Saver</string>
    <key>CFBundleDisplayName</key>
    <string>Clipboard Image Saver</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>© 2025 takekikuch</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Finderの現在フォルダに画像を保存するために使用します。</string>
    <key>NSAppleScriptEnabled</key>
    <true/>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>画像をここに保存</string>
            </dict>
            <key>NSMessage</key>
            <string>saveImageToCurrentFolder</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSApplicationIdentifier</key>
                <string>com.apple.finder</string>
            </dict>
            <key>NSReturnTypes</key>
            <array>
                <string>NSStringPboardType</string>
            </array>
            <key>NSSendTypes</key>
            <array>
                <string>NSStringPboardType</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# 実行権限設定
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

log_success "Complete app bundle created"

# コード署名
log_info "Signing application..."
codesign --deep --force --verify --verbose \
    --sign "$DEVELOPER_ID" \
    --entitlements ClipboardImageSaver.entitlements \
    --options runtime \
    "$APP_BUNDLE"

log_success "Application signed"

# 署名検証
log_info "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

# ZIP作成
log_info "Creating ZIP for notarization..."
ditto -c -k --keepParent "$APP_BUNDLE" "notarization.zip"

# 公証申請
log_info "Submitting for notarization..."
SUBMISSION_ID=$(xcrun notarytool submit "notarization.zip" --keychain-profile "notarytool-profile" --wait | grep "id:" | tail -1 | awk '{print $2}')

echo "Submission ID: $SUBMISSION_ID"

# 公証結果確認
NOTARY_STATUS=$(xcrun notarytool info "$SUBMISSION_ID" --keychain-profile "notarytool-profile" | grep "status:" | awk '{print $2}')

if [ "$NOTARY_STATUS" = "Accepted" ]; then
    log_success "Notarization accepted!"
    
    # 公証チケット添付
    log_info "Stapling notarization ticket..."
    xcrun stapler staple "$APP_BUNDLE"
    
    # 最終検証
    log_info "Final verification..."
    log_info "Code signature verification:"
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
    
    log_info "Gatekeeper assessment:"
    spctl --assess -vv --type exec "$APP_BUNDLE" || echo "⚠️ spctl assessment failed, but app may still work"
    
    log_success "Complete signed and notarized app ready!"
    echo "Location: $APP_BUNDLE"
    echo ""
    echo "You can now test the app:"
    echo "open $APP_BUNDLE"
    
else
    echo "❌ Notarization failed with status: $NOTARY_STATUS"
    xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "notarytool-profile"
    exit 1
fi