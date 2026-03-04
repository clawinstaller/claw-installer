#!/bin/bash
# Build ClawInstaller release artifacts

set -e

VERSION="${1:-0.1.0-beta}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release-build"
RELEASE_DIR="$PROJECT_DIR/release"
APP_NAME="ClawInstaller"

echo "🔨 Building ClawInstaller v$VERSION..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Build release binary
echo "📦 Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

# Create app bundle structure
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp ".build/release/ClawInstaller" "$MACOS/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>ai.openclaw.installer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"

# Create ZIP archive
ZIP_NAME="ClawInstaller-$VERSION-macos.zip"
echo "📦 Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r "$RELEASE_DIR/$ZIP_NAME" "$APP_NAME.app"
echo "✅ ZIP created: $RELEASE_DIR/$ZIP_NAME"

# Create DMG (if create-dmg is available)
if command -v create-dmg &> /dev/null; then
    DMG_NAME="ClawInstaller-$VERSION.dmg"
    echo "📦 Creating DMG..."
    create-dmg \
        --volname "ClawInstaller" \
        --volicon "$RESOURCES/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 185 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 450 185 \
        "$RELEASE_DIR/$DMG_NAME" \
        "$APP_BUNDLE" || echo "⚠️ DMG creation failed (optional)"
else
    echo "⚠️ create-dmg not found, skipping DMG creation"
    echo "   Install with: brew install create-dmg"
fi

# Calculate SHA256
echo ""
echo "📋 SHA256 checksums:"
cd "$RELEASE_DIR"
shasum -a 256 "$ZIP_NAME" | tee "$ZIP_NAME.sha256"

echo ""
echo "🎉 Release build complete!"
echo "   Version: $VERSION"
echo "   Output: $RELEASE_DIR/"
ls -la "$RELEASE_DIR/"
