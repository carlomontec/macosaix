#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PACKAGE_DIR/.." && pwd)"

echo "==> Building MacOSaiXApp in release mode..."
cd "$PACKAGE_DIR"
swift build -c release

APP_NAME="MacOSaiX Remake.app"
APP_DIR="$PACKAGE_DIR/build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Preparing $APP_NAME bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
echo "==> Copying binary..."
cp "$PACKAGE_DIR/.build/release/MacOSaiXApp" "$MACOS_DIR/MacOSaiX Remake"
chmod +x "$MACOS_DIR/MacOSaiX Remake"

# Copy Icon
ICON_SRC="$REPO_ROOT/Icon work/Application Icon/Application Icon.icns"
if [ -f "$ICON_SRC" ]; then
    echo "==> Copying classic Application Icon..."
    cp "$ICON_SRC" "$RESOURCES_DIR/AppIcon.icns"
fi

# Write Info.plist
echo "==> Generating Info.plist..."
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacOSaiX Remake</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.carlomontec.macosaix-remake</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacOSaiX Remake</string>
    <key>CFBundleDisplayName</key>
    <string>MacOSaiX Remake</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>3.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Ad-hoc code signing for local execution without gatekeeper hurdles
echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

# Also symlink / copy to project root for convenience
rm -rf "$REPO_ROOT/MacOSaiX Remake.app" "$REPO_ROOT/MacOSaiX.app"
cp -R "$APP_DIR" "$REPO_ROOT/MacOSaiX Remake.app"

echo "==> Successfully created $APP_NAME!"
echo "    Location: $REPO_ROOT/MacOSaiX Remake.app"
echo "    You can launch it via: open \"$REPO_ROOT/MacOSaiX Remake.app\""
