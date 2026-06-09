#!/bin/bash
# build-ios-sim.sh
# End-to-end build, install, and launch of Tower Defence on the iOS Simulator.
#
# This script:
#   1. Re-exports the iOS preset from Godot (regenerates the pck and xcodeproj)
#   2. Patches the regenerated xcodeproj so sim builds link the sim Swift runtime
#   3. Patches the regenerated xcframework sim slice
#   4. Runs xcodebuild for iphonesimulator (Release, arm64)
#   5. Reinstalls on the sim and launches
#   6. Takes a screenshot of the running game
#
# IMPORTANT: Godot regenerates the .xcodeproj on every export, so the patch
# must run AFTER the export. The pbxproj is gitignored; this script is the
# reproducible way to set it up.
#
# Prerequisites:
#   - Custom sim export template installed (scripts/build-ios-sim-template.sh)
#   - Apple Development cert in keychain (Yura Zaicev, team 56EXG84N59)
#   - iPhone 17 Pro sim (DB94ECCE-F5B6-4F33-AB1F-6EBE5A8576CD) booted

set -e

cd "$(dirname "$0")/.."

SIM="${SIM:-DB94ECCE-F5B6-4F33-AB1F-6EBE5A8576CD}"
GODOT_BUILD="${GODOT_BUILD:-/tmp/godot-4.6.3-build/godot}"
SIM_A="$GODOT_BUILD/bin/libgodot.ios.template_release.arm64.simulator.a"

echo "=== 1. Export iOS preset from Godot ==="
godot --headless --export-debug "iOS" "builds/tower-defense-ios.zip" 2>&1 | tail -3

echo ""
echo "=== 2. Patch the regenerated xcodeproj ==="
./scripts/patch-ios-xcodeproj-for-sim.sh

echo ""
echo "=== 3. Patch the regenerated xcframework sim slice ==="
if [ ! -f "$SIM_A" ]; then
  echo "❌ Sim .a not found at $SIM_A. Run scripts/build-ios-sim-template.sh first."
  exit 1
fi
cp "$SIM_A" builds/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator/libgodot.a
echo "Patched: $(file builds/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator/libgodot.a | awk -F: '{print $2}')"

echo ""
echo "=== 4. xcodebuild for iphonesimulator (Release, arm64) ==="
rm -rf /tmp/td-sim-build
xcodebuild \
  -project builds/tower-defense-ios.xcodeproj \
  -scheme tower-defense-ios \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/td-sim-build \
  -allowProvisioningUpdates \
  CODE_SIGN_IDENTITY="Apple Development: Yura Zaicev (77VA59EFJX)" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=56EXG84N59 \
  ARCHS=arm64 \
  build 2>&1 | tail -3

SIM_APP="/tmp/td-sim-build/Build/Products/Release-iphonesimulator/tower-defense-ios.app"
if [ ! -f "$SIM_APP/tower-defense-ios" ]; then
  echo "❌ Build did not produce $SIM_APP/tower-defense-ios"
  exit 1
fi

echo ""
echo "=== 5. Reinstall and launch on sim ==="
xcrun simctl uninstall "$SIM" com.godotengine.towerdefense 2>&1 || true
xcrun simctl install "$SIM" "$SIM_APP" 2>&1
xcrun simctl launch "$SIM" com.godotengine.towerdefense 2>&1
sleep 4

echo ""
echo "=== 6. Process status and screenshot ==="
xcrun simctl spawn "$SIM" launchctl list 2>&1 | grep -i tower-defense || echo "(process not yet visible)"
xcrun simctl io "$SIM" screenshot /tmp/td-sim-build-result.png 2>&1 | tail -1
ls -la /tmp/td-sim-build-result.png
echo "Done. Screenshot saved to /tmp/td-sim-build-result.png"
