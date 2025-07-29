#!/bin/bash
# ClipboardImageSaver - DMG作成スクリプト
# 
# 使用方法:
# ./create_dmg.sh [version] [app_path]
# 例: ./create_dmg.sh 1.0.0 dist/ClipboardImageSaver.app

set -e

# 設定
APP_NAME="ClipboardImageSaver"
DMG_BACKGROUND="assets/dmg_background.png"
DMG_ICON="assets/AppIcon.icns"
DEFAULT_VERSION="1.0.0"
BUILD_DIR="dist"

# 引数処理
VERSION=${1:-$DEFAULT_VERSION}
APP_PATH=${2:-"$BUILD_DIR/$APP_NAME.app"}

# 出力設定
DMG_NAME="$APP_NAME-$VERSION"
TEMP_DMG="$BUILD_DIR/${DMG_NAME}-temp.dmg"
FINAL_DMG="$BUILD_DIR/${DMG_NAME}.dmg"
VOLUME_NAME="$APP_NAME $VERSION"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    
    if [ ! -d "$APP_PATH" ]; then
        log_error "Application not found: $APP_PATH"
        log_info "Please build the application first or specify correct path"
        exit 1
    fi
    
    if ! command -v hdiutil &> /dev/null; then
        log_error "hdiutil command not found"
        exit 1
    fi
    
    # assetsディレクトリ作成
    mkdir -p assets
    
    log_success "Prerequisites check passed"
}

# 背景画像作成（シンプルなテキストベース）
create_dmg_background() {
    if [ ! -f "$DMG_BACKGROUND" ]; then
        log_info "Creating DMG background image..."
        
        # ImageMagickが利用可能な場合
        if command -v convert &> /dev/null; then
            convert -size 600x400 gradient:'#f0f8ff-#e6f3ff' \
                -font 'Helvetica-Bold' -pointsize 24 -fill '#333333' \
                -gravity center -annotate +0-60 "$APP_NAME" \
                -pointsize 16 -fill '#666666' \
                -annotate +0-20 "Drag to Applications folder to install" \
                -annotate +0+20 "クリップボード画像を簡単保存" \
                "$DMG_BACKGROUND"
            log_success "Background image created with ImageMagick"
        else
            log_warning "ImageMagick not found, using system default background"
            # デフォルトの背景を使用
            DMG_BACKGROUND=""
        fi
    else
        log_info "Using existing background image: $DMG_BACKGROUND"
    fi
}

# アプリアイコン作成（シンプルなプレースホルダー）
create_app_icon() {
    if [ ! -f "$DMG_ICON" ]; then
        log_info "Creating application icon..."
        
        # sipsコマンドでシステムアイコンをベースに作成
        if command -v sips &> /dev/null; then
            # システムのドキュメントアイコンを使用
            SYSTEM_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DocumentIcon.icns"
            if [ -f "$SYSTEM_ICON" ]; then
                cp "$SYSTEM_ICON" "$DMG_ICON"
                log_success "Icon created from system icon"
            fi
        fi
        
        if [ ! -f "$DMG_ICON" ]; then
            log_warning "Could not create icon, using default"
            DMG_ICON=""
        fi
    else
        log_info "Using existing icon: $DMG_ICON"
    fi
}

# DMG作成
create_dmg() {
    log_info "Creating DMG file..."
    
    # 既存のDMGファイルを削除
    rm -f "$TEMP_DMG" "$FINAL_DMG"
    
    # DMGサイズ計算（アプリサイズ + マージン）
    APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
    DMG_SIZE=$((APP_SIZE + 50))  # 50MBのマージン
    
    log_info "App size: ${APP_SIZE}MB, DMG size: ${DMG_SIZE}MB"
    
    # 読み書き可能なDMG作成
    hdiutil create -srcfolder /tmp -volname "$VOLUME_NAME" -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"
    
    log_success "Base DMG created"
}

# DMGマウントと設定
setup_dmg_contents() {
    log_info "Setting up DMG contents..."
    
    # DMGマウント
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | \
        egrep '^/dev/' | sed 1q | awk '{print $3}')
    
    if [ -z "$MOUNT_DIR" ]; then
        log_error "Failed to mount DMG"
        exit 1
    fi
    
    log_info "DMG mounted at: $MOUNT_DIR"
    
    # アプリケーションをDMGにコピー
    cp -R "$APP_PATH" "$MOUNT_DIR/"
    
    # Applicationsフォルダへのシンボリックリンク作成
    ln -s /Applications "$MOUNT_DIR/Applications"
    
    # 隠しファイル・フォルダの設定
    mkdir -p "$MOUNT_DIR/.background"
    
    # 背景画像をコピー（存在する場合）
    if [ -n "$DMG_BACKGROUND" ] && [ -f "$DMG_BACKGROUND" ]; then
        cp "$DMG_BACKGROUND" "$MOUNT_DIR/.background/"
        BACKGROUND_FILE=$(basename "$DMG_BACKGROUND")
    else
        BACKGROUND_FILE=""
    fi
    
    # カスタムアイコンを設定（存在する場合）
    if [ -n "$DMG_ICON" ] && [ -f "$DMG_ICON" ]; then
        cp "$DMG_ICON" "$MOUNT_DIR/.VolumeIcon.icns"
        # CI環境以外でボリュームアイコンを有効化
        if [ -z "$CI" ] && [ -z "$GITHUB_ACTIONS" ] && command -v SetFile &> /dev/null; then
            SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns"
            SetFile -a C "$MOUNT_DIR"
        fi
    fi
    
    log_success "Contents copied to DMG"
    
    # Finder表示設定をAppleScriptで設定
    setup_finder_view "$MOUNT_DIR" "$BACKGROUND_FILE"
    
    # DMGアンマウント
    hdiutil detach "$MOUNT_DIR"
    
    log_success "DMG setup completed"
}

# Finder表示設定（CI環境対応）
setup_finder_view() {
    local mount_dir="$1"
    local background_file="$2"
    
    log_info "Configuring Finder view..."
    
    # CI環境ではAppleScriptをスキップ
    if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
        log_warning "Skipping Finder configuration in CI environment"
        return 0
    fi
    
    # AppleScriptでFinder表示を設定（ローカル環境のみ）
    osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        if "$background_file" is not "" then
            set background picture of viewOptions to file ".background:$background_file"
        end if
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
    
    log_success "Finder view configured"
}

# 最終DMG作成
finalize_dmg() {
    log_info "Creating final DMG..."
    
    # 圧縮されたDMGに変換
    hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"
    
    # 一時ファイル削除
    rm -f "$TEMP_DMG"
    
    # DMG情報表示
    DMG_SIZE_MB=$(du -m "$FINAL_DMG" | cut -f1)
    DMG_CHECKSUM=$(shasum -a 256 "$FINAL_DMG" | cut -d' ' -f1)
    
    log_success "Final DMG created"
    log_info "File: $FINAL_DMG"
    log_info "Size: ${DMG_SIZE_MB}MB"
    log_info "SHA256: $DMG_CHECKSUM"
}

# READMEファイル作成
create_readme() {
    local readme_file="$BUILD_DIR/README.txt"
    
    log_info "Creating README file..."
    
    cat > "$readme_file" << EOF
$APP_NAME $VERSION

【インストール方法】
1. $APP_NAME.app を Applications フォルダにドラッグ&ドロップしてください
2. 初回起動時に権限設定が必要です：
   - アクセシビリティ権限：グローバルショートカット用
   - Apple Events権限：Finder統合用

【使用方法】
- ⌘+Shift+V（デフォルト）でクリップボード画像を保存
- メニューバーアイコンから設定変更可能
- クリップボード画像のプレビュー表示
- ドラッグ&ドロップで保存も可能

【システム要件】
- macOS 13.0 以降
- アクセシビリティ権限
- Apple Events権限

【サポート】
- GitHub: https://github.com/takekikuch/clipboard-image-saver-notarized
- 問題報告: Issues タブから報告してください

【ライセンス】
このソフトウェアは MIT License の下で提供されています。
詳細は LICENSE.txt をご確認ください。

---
Clipboard Image Saver
© 2025 takekikuch
EOF
    
    log_success "README created: $readme_file"
}

# メイン実行
main() {
    echo "=================================="
    echo "  ClipboardImageSaver DMG Creator"
    echo "=================================="
    echo "Version: $VERSION"
    echo "App Path: $APP_PATH"
    echo ""
    
    check_prerequisites
    create_dmg_background
    create_app_icon
    create_dmg
    setup_dmg_contents
    finalize_dmg
    create_readme
    
    echo ""
    echo "=================================="
    log_success "DMG creation completed!"
    echo "Output: $FINAL_DMG"
    echo "=================================="
}

# エラーハンドリング
trap 'log_error "Script failed at line $LINENO"' ERR

# スクリプト実行
main "$@"