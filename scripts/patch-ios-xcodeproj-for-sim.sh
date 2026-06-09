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
# Also narrow LIBRARY_SEARCH_PATHS to explicit sim-friendly paths and
# add OTHER_LDFLAGS with the sim Swift library path.
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

python3 - "$PBXPROJ" <<'PY'
import sys, re
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Idempotency: if already patched, skip (look for our telltale per-SDK conditional)
if 'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator' in content:
    print("✓ Already patched (iphonesimulator conditional present)")
    sys.exit(0)

# Patch FRAMEWORK_SEARCH_PATHS wildcard into per-SDK conditional.
old_block = '"FRAMEWORK_SEARCH_PATHS[arch=*]" = (\n\t\t\t\t\t"$(PROJECT_DIR)/**",\n\t\t\t\t);'

new_block = '"FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*][arch=*]" = (\n\t\t\t\t\t"$(PROJECT_DIR)/**",\n\t\t\t\t);\n\t\t\t\t"FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*][arch=*]" = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)",\n\t\t\t\t\t"$(PROJECT_DIR)/MoltenVK.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.release.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.release.xcframework",\n\t\t\t\t\t"$(SDKROOT)/usr/lib/swift",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift-5.5/$(PLATFORM_NAME)",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)",\n\t\t\t\t);'

count = content.count(old_block)
if count == 0:
    print("⚠️  FRAMEWORK_SEARCH_PATHS block not found (format may have changed). Trying fuzzy match...")
    matches = re.findall(r'"FRAMEWORK_SEARCH_PATHS\[arch=\*\]"\s*=\s*\(\s*"\$\(PROJECT_DIR\)/\*\*",?\s*\);', content)
    if not matches:
        print("❌ Could not find FRAMEWORK_SEARCH_PATHS block to patch")
        sys.exit(1)
    for m in matches:
        new_block_local = m.replace('[arch=*]', '[sdk=iphoneos*][arch=*]') + '\n\t\t\t\t"FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*][arch=*]" = (\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"$(PROJECT_DIR)",\n\t\t\t\t\t"$(PROJECT_DIR)/MoltenVK.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.release.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.debug.xcframework",\n\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.release.xcframework",\n\t\t\t\t\t"$(SDKROOT)/usr/lib/swift",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift-5.5/$(PLATFORM_NAME)",\n\t\t\t\t\t"$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)",\n\t\t\t\t);'
        content = content.replace(m, new_block_local, 1)
    count = len(matches)
else:
    content = content.replace(old_block, new_block)

# Patch LIBRARY_SEARCH_PATHS wildcard into per-SDK conditional.
# The /** is the same problem: it makes ld find the device's libswift_Concurrency.
lib_old_pattern = re.compile(
    r'LIBRARY_SEARCH_PATHS\s*=\s*\(\s*"\$\(inherited\)",\s*"\$\(PROJECT_DIR\)(?:/\*\*)?",?\s*\);',
    re.MULTILINE
)
lib_matches = list(lib_old_pattern.finditer(content))
new_lib = '''LIBRARY_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"$(PROJECT_DIR)",
\t\t\t\t\t"$(PROJECT_DIR)/MoltenVK.xcframework/ios-arm64_x86_64-simulator",
\t\t\t\t\t"$(PROJECT_DIR)/tower-defense-ios.xcframework/ios-arm64_x86_64-simulator",
\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.debug.xcframework",
\t\t\t\t\t"$(PROJECT_DIR)/libgodot.ios.release.xcframework",
\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.debug.xcframework",
\t\t\t\t\t"$(PROJECT_DIR)/libgodot.visionos.release.xcframework",
\t\t\t\t);'''
for m in lib_matches:
    content = content.replace(m.group(0), new_lib, 1)

# Patch OTHER_LDFLAGS to add sim Swift library paths using ABSOLUTE paths.
# $(TOOLCHAIN_DIR) has a trailing slash which combined with $(EFFECTIVE_PLATFORM_NAME)
# gives "swift-5.5-iphonesimulator" (wrong) instead of "swift-5.5/iphonesimulator" (right).
# Use absolute paths to sidestep the variable expansion.
ldflags_pattern = re.compile(r'OTHER_LDFLAGS\s*=\s*"([^"]*)";')
matches = list(ldflags_pattern.finditer(content))
new_ldflags = 'OTHER_LDFLAGS = "$(LD_CLASSIC_$(XCODE_VERSION_ACTUAL))   -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.5/$(PLATFORM_NAME) -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM_NAME)";'
for m in matches:
    val = m.group(1)
    if 'swift-5.5/' in val and '$(PLATFORM_NAME)' in val:
        continue  # already patched
    content = content.replace(m.group(0), new_ldflags)

with open(path, 'w') as f:
    f.write(content)

print(f"✓ Patched: {count} FRAMEWORK_SEARCH_PATHS, {len(lib_matches)} LIBRARY_SEARCH_PATHS, {len(matches)} OTHER_LDFLAGS")
PY
