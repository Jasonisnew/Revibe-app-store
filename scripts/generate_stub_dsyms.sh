#!/bin/bash
#
# Generate stub dSYMs for prebuilt binary frameworks that ship without debug
# symbols (e.g. MediaPipe's xcframeworks via SwiftTasksVision). Without
# these stubs, App Store Connect emits "Upload Symbols Failed" warnings
# during build upload because it expects a dSYM for every embedded
# framework UUID.
#
# A stub dSYM is a normal .dSYM bundle whose DWARF file is just a copy of
# the framework's Mach-O binary. It carries the same UUID as the framework
# so App Store Connect's UUID check is satisfied. Crashes inside that
# framework still won't be symbolicated (impossible without source debug
# info anyway) but the warning goes away.
#
# This script is invoked from a Run Script build phase. It only does work
# when archiving (ACTION=install); for Debug/Release device builds it
# silently exits.
#

set -e

if [ "${ACTION}" != "install" ]; then
    exit 0
fi

DSYM_DIR="${DWARF_DSYM_FOLDER_PATH}"
FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ -z "$DSYM_DIR" ] || [ -z "$FRAMEWORKS_DIR" ]; then
    exit 0
fi

if [ ! -d "$FRAMEWORKS_DIR" ]; then
    exit 0
fi

mkdir -p "$DSYM_DIR"

for FW_BUNDLE in "$FRAMEWORKS_DIR"/*.framework; do
    [ -d "$FW_BUNDLE" ] || continue

    FW_NAME=$(basename "$FW_BUNDLE" .framework)
    BIN="$FW_BUNDLE/$FW_NAME"
    [ -f "$BIN" ] || continue

    DSYM_BUNDLE="$DSYM_DIR/$FW_NAME.framework.dSYM"
    if [ -d "$DSYM_BUNDLE" ]; then
        continue
    fi

    UUID=$(dwarfdump --uuid "$BIN" 2>/dev/null | head -n 1 | awk '{print $2}')
    if [ -z "$UUID" ]; then
        continue
    fi

    DWARF_DIR_PATH="$DSYM_BUNDLE/Contents/Resources/DWARF"
    mkdir -p "$DWARF_DIR_PATH"
    cp "$BIN" "$DWARF_DIR_PATH/$FW_NAME"

    cat > "$DSYM_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleIdentifier</key>
    <string>com.apple.xcode.dsym.${FW_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>dSYM</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST

    echo "Generated stub dSYM for $FW_NAME ($UUID)"
done
