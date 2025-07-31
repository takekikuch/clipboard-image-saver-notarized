#!/bin/bash
# ClipboardImageSaver - コード署名・公証スクリプト
# 
# 使用前の設定:
# 1. DEVELOPER_ID を実際の証明書名に変更
# 2. KEYCHAIN_PROFILE を設定 (xcrun notarytool store-credentials で作成)
# 3. APP_VERSION を適切な値に設定

set -e

# 設定
APP_NAME="ClipboardImageSaver"
APP_VERSION="1.0.0"
DEVELOPER_ID="Developer ID Application: Takeru Kikuchi (MDH8A45XTP)"
KEYCHAIN_PROFILE="notarytool-profile"
BUILD_DIR=".build/release"
DIST_DIR="dist"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 事前チェック
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! xcrun --find codesign >/dev/null 2>&1; then
        log_error "codesign not found. Make sure Xcode is installed."
        exit 1
    fi
    
    if ! xcrun --find notarytool >/dev/null 2>&1; then
        log_error "notarytool not found. Make sure Xcode 13+ is installed."
        exit 1
    fi
    
    if [ ! -f "$APP_NAME.entitlements" ]; then
        log_error "Entitlements file not found: $APP_NAME.entitlements"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# アプリケーションビルド
build_app() {
    log_info "Building application..."
    swift build -c release
    
    if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
        log_error "Build failed: $BUILD_DIR/$APP_NAME not found"
        exit 1
    fi
    
    log_success "Build completed"
}

# .appバンドル作成
create_app_bundle() {
    log_info "Creating application bundle..."
    
    # クリーンアップ
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    
    # .appバンドル構造作成
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    
    # 実行ファイルコピー
    cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
    
    # Info.plistの処理
    if [ -f "Info.plist" ]; then
        cp "Info.plist" "$APP_BUNDLE/Contents/"
    else
        log_warning "Info.plist not found, creating minimal version"
        cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Finderの現在フォルダに画像を保存するために使用します。</string>
</dict>
</plist>
EOF
    fi
    
    # アイコンファイルがあればコピー
    if [ -f "AppIcon.icns" ]; then
        cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    fi
    
    log_success "Application bundle created"
}

# コード署名
sign_app() {
    log_info "Signing application..."
    
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    
    # 署名実行
    codesign --deep --force --verify --verbose \
        --sign "$DEVELOPER_ID" \
        --entitlements "$APP_NAME.entitlements" \
        --options runtime \
        "$APP_BUNDLE"
    
    log_success "Application signed"
}

# 署名検証
verify_signature() {
    log_info "Verifying signature..."
    
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    
    # 詳細検証
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
    
    # Gatekeeper検証
    spctl --assess -vv --type exec "$APP_BUNDLE"
    
    log_success "Signature verification passed"
}

# 公証
notarize_app() {
    log_info "Notarizing application (this may take several minutes)..."
    
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    ZIP_FILE="$DIST_DIR/$APP_NAME-$APP_VERSION.zip"
    
    # ZIP作成
    ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_FILE"
    
    # 公証アップロード
    xcrun notarytool submit "$ZIP_FILE" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait
    
    log_success "Notarization completed"
}

# 公証チケット添付
staple_app() {
    log_info "Stapling notarization ticket..."
    
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    
    xcrun stapler staple "$APP_BUNDLE"
    
    log_success "Notarization ticket stapled"
}

# 最終検証
final_verification() {
    log_info "Performing final verification..."
    
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    
    # Gatekeeper最終チェック
    spctl --assess -vv --type exec "$APP_BUNDLE"
    
    # ファイルサイズとハッシュ表示
    APP_SIZE=$(du -h "$APP_BUNDLE" | cut -f1)
    log_info "Application size: $APP_SIZE"
    
    log_success "Final verification passed"
}

# メイン実行
main() {
    echo "=================================="
    echo "  ClipboardImageSaver Code Signing"
    echo "=================================="
    echo ""
    
    check_prerequisites
    build_app
    create_app_bundle
    sign_app
    verify_signature
    notarize_app
    staple_app
    final_verification
    
    echo ""
    echo "=================================="
    log_success "Distribution package ready!"
    echo "Location: $DIST_DIR/$APP_NAME.app"
    echo "=================================="
}

# スクリプト実行
main "$@"