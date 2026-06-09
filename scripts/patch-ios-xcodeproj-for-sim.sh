#!/bin/bash
# patch-ios-xcodeproj-for-sim.sh
# Patch the Godot-generated .xcodeproj so the iOS Simulator build links
# the simulator's Swift runtime instead of the device's libswift_Concurrency.
#
# The issue: the .xcodeproj's FRAMEWORK_SEARCH_PATHS uses $(PROJECT_DIR)/**
# which makes the linker pick up dylibs from tower-defense-ios.xcarchive/
# SwiftSupport/iphoneos/ even when targeting iphonesimulator. That dylib
# was built for iphoneos and can't be linked into a sim build.
#
# The fix: split FRAMEWORK_SEARCH_PATHS into per-SDK conditionals so the
# sim build only sees simulator-side frameworks + the sim Swift runtime.
#
# Run this AFTER every `godot --headless --export-debug iOS` because Godot
# regenerates the .xcodeproj each time.

set -e

XCODEPROJ="${1:-builds/tower-defense-ios.xcodeproj}"
PBXPROJ="$XCODEPROJ/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
  echo "❌ Not found: $PBXPROJ"
  echo "   Run the iOS export first: godot --headless --export-debug iOS builds/tower-defense-ios.zip"
  exit 1
fi

if grep -q "FRAMEWORK_SEARCH_PATHS\[sdk=iphonesimulator" "$PBXPROJ"; then
  echo "✓ Already patched: $PBXPROJ"
  exit 0
fi

python3 <<'PY'
import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

old_block = '"FRAMEWORK_SEARCH_PATHS[arch=*]" = (\n\t\t\t\t\t"$(PROJECT_DIR)/**",\n\t\t\t\t);'

new_block = '"FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*][arch=*]" = (\n\t\t\t\t\t"$(PROJECT_DIR)/**",\n\t\t\t\t);\n\t\t\t\t"FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*][arch=*]" = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)",\n\t\t\t\t\t"$(PROJECT_DIR)/MoltenVK.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.release.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.release.xcframework",\n\t\t\t\t\t"$(SDKROOT)/usr/lib/swift",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift-5.5/$(PLATFORM_NAME)",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)",\n\t\t\t\t);'

count = content.count(old_block)
if count == 0:
    print("⚠️  FRAMEWORK_SEARCH_PATHS block not found (already patched or format changed?)")
    sys.exit(1)

content = content.replace(old_block, new_block)

# Also patch OTHER_LDFLAGS to add sim Swift library paths
import re
for m in re.finditer(r'OTHER_LDFLAGS = "([^"]*)";', content):
    val = m.group(1)
    if 'EFFECTIVE_PLATFORM_NAME' in val and 'swift' in val.lower():
        continue
    new_val = val + ' -L$(TOOLCHAIN_DIR)/usr/lib/swift-5.5$(EFFECTIVE_PLATFORM_NAME) -L$(TOOLCHAIN_DIR)/usr/lib/swift$(EFFECTIVE_PLATFORM_NAME) -L$(DT_TOOLCHAIN_DIR)/usr/lib/swift$(EFFECTIVE_PLATFORM_NAME)'
    content = content.replace(m.group(0), f'OTHER_LDFLAGS = "{new_val}";', 1)

with open(path, 'w') as f:
    f.write(content)
print(f"✓ Patched {count} FRAMEWORK_SEARCH_PATHS blocks + OTHER_LDFLAGS")
PY
"$PBXPROJ"

echo ""
echo "=== Verify ==="
grep -c "FRAMEWORK_SEARCH_PATHS\[sdk=iphonesimulator" "$PBXPROJ"
echo "(should be 2: one in project-level Debug, one in Release)"
