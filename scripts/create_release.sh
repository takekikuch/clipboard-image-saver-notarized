#!/bin/bash
# ClipboardImageSaver - リリース作成スクリプト
# 
# 使用方法:
# ./create_release.sh [version] [release_type]
# 例: ./create_release.sh 1.0.0 stable
# 例: ./create_release.sh 1.1.0-beta prerelease

set -e

# 設定
APP_NAME="ClipboardImageSaver"
DEFAULT_VERSION="1.0.0"
DEFAULT_TYPE="stable"

# 引数処理
VERSION=${1:-$DEFAULT_VERSION}
RELEASE_TYPE=${2:-$DEFAULT_TYPE}

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

# バージョン形式チェック
validate_version() {
    if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        log_error "Invalid version format: $VERSION"
        log_info "Expected format: X.Y.Z or X.Y.Z-suffix (e.g., 1.0.0, 1.1.0-beta)"
        exit 1
    fi
    
    log_success "Version format valid: $VERSION"
}

# Git状態チェック
check_git_status() {
    log_info "Checking Git status..."
    
    if [ ! -d ".git" ]; then
        log_error "Not a Git repository"
        exit 1
    fi
    
    # 未コミットの変更チェック
    if ! git diff-index --quiet HEAD --; then
        log_error "Uncommitted changes detected"
        log_info "Please commit all changes before creating a release"
        exit 1
    fi
    
    # 現在のブランチ確認
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        log_warning "Current branch is not 'main': $CURRENT_BRANCH"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Release cancelled"
            exit 1
        fi
    fi
    
    log_success "Git status check passed"
}

# 既存タグチェック
check_existing_tag() {
    TAG_NAME="v$VERSION"
    
    if git tag --list | grep -q "^$TAG_NAME$"; then
        log_error "Tag already exists: $TAG_NAME"
        log_info "Use a different version or delete the existing tag"
        exit 1
    fi
    
    log_success "Tag name available: $TAG_NAME"
}

# ビルドテスト
test_build() {
    log_info "Testing build..."
    
    # 依存関係解決
    swift package resolve
    
    # ビルドテスト
    swift build -c release
    
    if [ ! -f ".build/release/$APP_NAME" ]; then
        log_error "Build failed: executable not found"
        exit 1
    fi
    
    log_success "Build test passed"
}

# バージョン更新（必要に応じて）
update_version_in_files() {
    log_info "Updating version in files..."
    
    # README.md のバージョンバッジ更新
    if [ -f "README.md" ]; then
        sed -i.bak "s/Version-[0-9]\+\.[0-9]\+\.[0-9]\+[^)]*-blue/Version-$VERSION-blue/g" README.md
        rm -f README.md.bak
        log_success "Updated version in README.md"
    fi
    
    # Package.swiftにバージョン情報があれば更新（オプション）
    if [ -f "Package.swift" ] && grep -q "version:" "Package.swift"; then
        log_info "Package.swift version field detected - manual update may be needed"
    fi
}

# CHANGELOG生成（簡易版）
generate_changelog() {
    log_info "Generating changelog..."
    
    CHANGELOG_FILE="CHANGELOG_v$VERSION.md"
    
    cat > "$CHANGELOG_FILE" << EOF
# Changelog - $APP_NAME $VERSION

## Changed in this version

$(git log --oneline --since="$(git describe --tags --abbrev=0 2>/dev/null || echo '1 week ago')" --pretty=format:"- %s" | head -20)

## Key Features

- 🖼️ **クリップボード画像保存**: グローバルショートカット(⌘+Shift+V)でどこからでも保存
- 👀 **リアルタイムプレビュー**: クリップボード内画像の自動検出・プレビュー表示  
- 🔄 **ドラッグ&ドロップ**: プレビューから直接ドラッグして保存
- ⚙️ **カスタマイズ機能**: ショートカットキー・ファイル名テンプレート変更可能
- 🔧 **システム統合**: Services統合・権限管理・エラーハンドリング

## System Requirements

- macOS 13.0 以降
- アクセシビリティ権限
- Apple Events権限

## Installation

1. DMGファイルをダウンロード
2. $APP_NAME.appをApplicationsフォルダにドラッグ
3. 初回起動時に権限設定を行う

---
Release created on $(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    log_success "Changelog generated: $CHANGELOG_FILE"
}

# タグ作成
create_tag() {
    log_info "Creating Git tag..."
    
    TAG_NAME="v$VERSION"
    TAG_MESSAGE="Release $APP_NAME $VERSION"
    
    # 変更をコミット（バージョン更新があった場合）
    if ! git diff-index --quiet HEAD --; then
        git add .
        git commit -m "Bump version to $VERSION"
        log_success "Committed version updates"
    fi
    
    # タグ作成
    git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"
    
    log_success "Created tag: $TAG_NAME"
}

# リモートプッシュ
push_to_remote() {
    log_info "Pushing to remote repository..."
    
    # 確認
    echo "Ready to push the following:"
    echo "  Branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "  Tag: v$VERSION"
    echo "  Release type: $RELEASE_TYPE"
    echo ""
    read -p "Push to remote and trigger GitHub Actions? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Push cancelled. Tag created locally only."
        log_info "To push later: git push origin main && git push origin v$VERSION"
        exit 1
    fi
    
    # プッシュ実行
    git push origin $(git rev-parse --abbrev-ref HEAD)
    git push origin "v$VERSION"
    
    log_success "Pushed to remote repository"
}

# 完了メッセージ
show_completion_message() {
    log_success "Release creation completed!"
    echo ""
    echo "=================================="
    echo "  Release Summary"
    echo "=================================="
    echo "Version: $VERSION"
    echo "Type: $RELEASE_TYPE"
    echo "Tag: v$VERSION"
    echo ""
    echo "GitHub Actions will now build and create the release."
    echo "Check the progress at:"
    echo "https://github.com/$(git config --get remote.origin.url | sed 's/.*[:/]\([^/]*\/[^/]*\)\.git/\1/')/actions"
    echo ""
    echo "Release will be available at:"
    echo "https://github.com/$(git config --get remote.origin.url | sed 's/.*[:/]\([^/]*\/[^/]*\)\.git/\1/')/releases"
    echo "=================================="
}

# メイン実行
main() {
    echo "=================================="
    echo "  $APP_NAME Release Creator"
    echo "=================================="
    echo "Version: $VERSION"
    echo "Type: $RELEASE_TYPE"
    echo ""
    
    validate_version
    check_git_status
    check_existing_tag
    test_build
    update_version_in_files
    generate_changelog
    create_tag
    push_to_remote
    show_completion_message
}

# エラーハンドリング
trap 'log_error "Script failed at line $LINENO"' ERR

# スクリプト実行
main "$@"