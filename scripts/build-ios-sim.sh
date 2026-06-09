#!/bin/bash
# build-ios-sim.sh
# Build the Tower Defense iOS Simulator .app and install it on the
# iPhone 17 Pro simulator (DB94ECCE-F5B6-4F33-AB1F-6EBE5A8576CD).
#
# Prerequisites:
#   - Godot 4.6.3-stable export template patched with arm64 sim slice (one-time, see scripts/build-ios-sim-template.sh)
#   - Xcode 26.5+ with iOS 26.5 simulator SDK
#   - Apple Development signing identity in keychain (Yura Zaicev, team 56EXG84N59)
#   - The project has been exported at least once with `godot --export-debug iOS`
#
# This script:
#   1. Re-exports the iOS preset from Godot
#   2. Patches the regenerated .xcodeproj (see patch-ios-xcodeproj-for-sim.sh)
#   3. Patches the regenerated tower-defense-ios.xcframework sim slice
#   4. Runs xcodebuild for iphonesimulator
#   5. Installs on the sim and launches
#   6. Screenshots the result

set -e
cd "$(dirname "$0")/.."

SIM=DB94ECCE-F5B6-4F33-AB1F-6EBE5A8576CD
BUILD_DIR="/tmp/godot-4.6.3-build/godot"
SIM_A="$BUILD_DIR/bin/libgodot.ios.template_release.arm64.simulator.a"
DERIVED=/tmp/td-sim-build

echo "=== 1. Export iOS preset from Godot ==="
godot --headless --export-debug "iOS" "builds/tower-defense-ios.zip" 2>&1 | tail -3

echo ""
echo "=== 2. Patch the regenerated .xcodeproj for sim linking ==="
./scripts/patch-ios-xcodeproj-for-sim.sh builds/tower-defense-ios.xcodeproj

echo ""
echo "=== 3. Patch the regenerated .xcodeproj's xcframework sim slice ==="
if [ ! -f "$SIM_A" ]; then
  echo "❌ Sim .a not found at $SIM_A. Run scripts/build-ios-sim-template.sh first."
  exit 1
fi
cp "$SIM_A" builds/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator/libgodot.a
lipo -info builds/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator/libgodot.a

echo ""
echo "=== 4. xcodebuild for iphonesimulator (Release, arm64) ==="
rm -rf "$DERIVED"
xcodebuild \
  -project builds/tower-defense-ios.xcodeproj \
  -scheme tower-defense-ios \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  CODE_SIGN_IDENTITY="Apple Development: Yura Zaicev (77VA59EFJX)" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=56EXG84N59 \
  ARCHS=arm64 \
  build 2>&1 | tail -3

SIM_APP="$DERIVED/Build/Products/Release-iphonesimulator/tower-defense-ios.app"
if [ ! -f "$SIM_APP/tower-defense-ios" ]; then
  echo "❌ Build did not produce $SIM_APP/tower-defense-ios"
  exit 1
fi

echo ""
echo "=== 5. Install on $SIM and launch ==="
xcrun simctl uninstall "$SIM" com.godotengine.towerdefense 2>&1 || true
xcrun simctl install "$SIM" "$SIM_APP" 2>&1
xcrun simctl launch "$SIM" com.godotengine.towerdefense 2>&1
sleep 4
xcrun simctl spawn "$SIM" launchctl list 2>&1 | grep -i tower-defense

echo ""
echo "=== 6. Screenshot ==="
xcrun simctl io "$SIM" screenshot /tmp/td-sim-build.png 2>&1 | tail -1
ls -la /tmp/td-sim-build.png 2>&1
