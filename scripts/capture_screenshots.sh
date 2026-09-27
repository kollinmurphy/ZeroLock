#!/bin/bash
set -e

# ZeroLock — Automated Simulator Screenshot Capture Script
# Usage: ./scripts/capture_screenshots.sh

BUNDLE_ID="com.kollinmurphy.zerolock"
OUTPUT_DIR="./screenshots"
SCHEME="Broke"
PROJECT="Broke.xcodeproj"

echo "🚀 Building app for iOS Simulator..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "generic/platform=iOS Simulator" -configuration Debug build CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY="-" > /dev/null

APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "generic/platform=iOS Simulator" -configuration Debug -showBuildSettings | grep "CODESIGNING_FOLDER_PATH" | head -n 1 | awk '{print $3}')

echo "📦 Built App Path: $APP_PATH"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Simulators to capture screenshots for
DEVICES=(
    "iPhone 17 Pro Max"
    "iPhone 17 Pro"
    "iPad Pro 13-inch (M5)"
    "iPad mini (A17 Pro)"
)

for DEVICE in "${DEVICES[@]}"; do
    echo "----------------------------------------"
    echo "📱 Processing device: $DEVICE"
    
    # Pick highest available runtime device matching exact device name
    UDID=$(xcrun simctl list devices available | grep -F "${DEVICE} (" | tail -n 1 | sed -E 's/.*\(([-A-F0-9]+)\).*/\1/' || true)
    
    if [ -z "$UDID" ]; then
        echo "⚠️ Simulator '$DEVICE' not found or available. Skipping..."
        continue
    fi
    
    echo "⚡️ Booting $DEVICE ($UDID)..."
    xcrun simctl boot "$UDID" 2>/dev/null || true
    xcrun simctl bootstatus "$UDID" -b
    sleep 3
    
    echo "📲 Installing app..."
    xcrun simctl install "$UDID" "$APP_PATH"
    
    SAFE_NAME=$(echo "$DEVICE" | tr ' ' '_')
    
    # 1. Screen 1: Ready to Lock (Main Green State)
    echo "📸 Capturing: Ready to Lock Screen..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITest_ReadyToLock -UITest_MockProfiles
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${SAFE_NAME}_01_ReadyToLock.png"
    
    # 2. Screen 2: Shield Active (Main Red Active State)
    echo "📸 Capturing: Shield Active Screen..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITest_ShieldActive -UITest_MockProfiles
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${SAFE_NAME}_02_ShieldActive.png"
    
    # 3. Screen 3: Focus Profile Edit / Configuration
    echo "📸 Capturing: Edit Profile Screen..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITest_ReadyToLock -UITest_MockProfiles -UITest_EditProfile
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${SAFE_NAME}_03_EditProfile.png"
    
    # 4. Screen 4: About / Help View
    echo "📸 Capturing: About & How It Works Screen..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITest_ReadyToLock -UITest_MockProfiles -UITest_OpenHelp
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${SAFE_NAME}_04_About.png"
    
    # 5. Screen 5: Onboarding Setup Walkthrough
    echo "📸 Capturing: Setup Walkthrough Screen..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -UITest_ReadyToLock -UITest_MockProfiles -UITest_OpenOnboarding
    sleep 3
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIR/${SAFE_NAME}_05_SetupWalkthrough.png"
    
    echo "Shutting down $DEVICE..."
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
done

echo "----------------------------------------"
echo "📐 Generating 6.5-inch App Store screenshots (1284x2778)..."
for img in "$OUTPUT_DIR"/iPhone_17_Pro_Max_*.png; do
    if [ -f "$img" ]; then
        target_name=$(basename "$img" | sed 's/iPhone_17_Pro_Max_/iPhone_6.5inch_1284x2778_/')
        sips -z 2778 1284 "$img" --out "$OUTPUT_DIR/$target_name" > /dev/null
    fi
done

echo "========================================"
echo "🎉 Screenshots capture complete!"
echo "📁 Saved to: $(pwd)/screenshots"
echo "========================================"
