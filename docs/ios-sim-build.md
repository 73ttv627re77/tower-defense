# iOS Simulator Build — Tower Defence (WORKING ✅)

**Status (2026-06-09 12:05 BST):** The iOS Simulator build now works end-to-end. The game runs on the iPhone 17 Pro simulator (`DB94ECCE-F5B6-4F33-AB1F-6EBE5A8576CD`) — the Tower Defense map renders, enemies move along the path, the UI shows boss + spawn + tower buttons. Screenshot at `/tmp/td-sim-build.png` after a successful build.

## What it took (4 layers, all fixed)

The official Godot 4.6 docs say "iOS sim is not supported as per GH-102149", but with two source-built template patches + a generated-xcodeproj patch, it builds and runs on Apple Silicon.

### 1. Official 4.6.3 export template's sim slice is broken

`libgodot.ios.release.xcframework/ios-arm64_x86_64-simulator/libgodot.a` is `x86_64` only, not `arm64`. On Apple Silicon, the sim picks the arm64 slice and gets nothing. Tracked as [godotengine/godot#118161](https://github.com/godotengine/godot/issues/118161).

**Fix:** build a custom sim template from Godot 4.6.3-stable source and patch the official `ios.zip` to swap the broken sim slice for a real arm64 sim `.a`. Script: `scripts/build-ios-sim-template.sh`.

### 2. The Godot iOS export bundles Mac Catalyst shim code

The device-built `tower-defense-ios.app` contains both `OS_IOS` / `UIApplicationDelegate` and `OS_MacOS_NSApp` / `NSApplication` / `NSMenuBarPresentationInstance` symbols. On the iOS Simulator (no Catalyst runtime), the Catalyst path is taken, `_RegisterApplication` aborts. Example live crash: `~/Library/Logs/DiagnosticReports/tower-defense-ios-2026-06-09-090717.ips`.

**Fix:** force the build to target `iphonesimulator` SDK with our source-built arm64 sim engine. Catalyst code isn't in the sim-targeted engine. Verified — the new sim .app has no `OS_MacOS_NSApp` / `NSApplication` strings (pure iOS).

### 3. Building a custom sim template from source

`scons platform=ios target=template_release ios_simulator=yes` succeeds (2157 .o files, 160 MB `libgodot.ios.template_release.arm64.simulator.a`). PR #102179 is in 4.6.3-stable and disables Metal/Vulkan for sim. The sim `.a` is arm64 only, which is what Apple Silicon sims need.

### 4. The Godot-generated .xcodeproj links the wrong Swift runtime

After exporting, `xcodebuild -destination 'generic/platform=iOS Simulator'` fails with:

```
Undefined symbols for architecture arm64:
  "dispatch thunk of Swift.Actor.unownedExecutor.getter : Swift.UnownedSerialExecutor"
  "static Swift.MainActor.shared.getter : Swift.MainActor"
  "type metadata accessor for Swift.MainActor"
  "_swift_task_isCurrentExecutor"
  "_swift_task_reportUnexpectedExecutor"
  in libgodot.a[1057](app.ios.template_release.arm64.simulator.o)
```

Cause: the Godot-generated `.xcodeproj` sets `FRAMEWORK_SEARCH_PATHS[arch=*] = $(PROJECT_DIR)/**`, which makes the linker pick up `tower-defense-ios.xcarchive/SwiftSupport/iphoneos/libswift_Concurrency.dylib` (a device build) even when the active SDK is `iphonesimulator`. That dylib can't link into a sim build.

**Fix:** patch the `.xcodeproj` to split `FRAMEWORK_SEARCH_PATHS` into per-SDK conditionals:

```xcconfig
"FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*][arch=*]" = ("$(PROJECT_DIR)/**",);
"FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*][arch=*]" = (
    "$(inherited)",
    "$(PROJECT_DIR)",
    "$(SDKROOT)/usr/lib/swift",
    "$(TOOLCHAIN_DIR)/usr/lib/swift-5.5/$(PLATFORM_NAME)",
    "$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)",
);
```

And add `OTHER_LDFLAGS` with the sim Swift library path using `$(EFFECTIVE_PLATFORM_NAME)`. Script: `scripts/patch-ios-xcodeproj-for-sim.sh`.

## Workflow — what to run to build + run on sim

```bash
# One-time: build the custom sim export template (~30 min, output goes to
#   ~/Library/Application Support/Godot/export_templates/4.6.3.stable/ios.zip)
scripts/build-ios-sim-template.sh

# Per-iteration: re-export + patch + build + install + launch
scripts/build-ios-sim.sh
```

`build-ios-sim.sh` does:
1. `godot --headless --export-debug iOS` — regenerates the iOS export
2. `scripts/patch-ios-xcodeproj-for-sim.sh` — patches the regenerated .xcodeproj
3. Patches the regenerated `builds/tower-defense-ios.xcframework` sim slice
4. `xcodebuild -destination 'generic/platform=iOS Simulator' -configuration Release ARCHS=arm64 build`
5. `xcrun simctl install/launch` on `DB94ECCE`
6. Screenshot to `/tmp/td-sim-build.png`

## Known issues / caveats

- The game is rendered in landscape orientation, but the project design spec is portrait 9:16. The renderer is treating the sim's portrait screen as if it were landscape. Fixable in `project.godot` (display/window/size/viewport settings) or in a scene-level canvas transform. Not a sim-build blocker.
- The `mouse_get_position()` error in the log is benign — Godot's display server on iOS doesn't have a mouse concept; the code path is defensive and returns `Point2i()`.
- The patched `.xcodeproj` is regenerated on every `godot --export-debug iOS`, so re-run `scripts/patch-ios-xcodeproj-for-sim.sh` after each Godot export.
- The sim .a was built with `template_release` only; the .xcodeproj's `Debug` config still won't link. Use `Release` for sim builds until we build a `template_debug` sim `.a` too.

## What was changed outside the repo

- Patched `~/Library/Application Support/Godot/export_templates/4.6.3.stable/ios.zip` to have an arm64 sim slice (was x86_64 only — the upstream bug). Backup: `ios.zip.bak.20260609-094735`. iOS device builds unaffected.

## Files in this repo

- `scripts/build-ios-sim-template.sh` — one-time setup, builds Godot 4.6.3-stable sim template from source and patches the official `ios.zip`
- `scripts/patch-ios-xcodeproj-for-sim.sh` — applies the .xcodeproj patch needed after each Godot export
- `scripts/build-ios-sim.sh` — end-to-end: export, patch, build, install, launch, screenshot
- `docs/ios-sim-build.md` — this file

## Tracked issues

- [Issue #10](https://github.com/73ttv627re77/tower-defense/issues/10) — original SBMainWorkspace / NSApplication-init crash, root-caused to the Catalyst shim in the device-built engine binary
- [godotengine/godot#118161](https://github.com/godotengine/godot/issues/118161) — upstream xcframework sim slice x86_64-only bug
- [godotengine/godot#102149](https://github.com/godotengine/godot/issues/102149) — original "iOS sim not supported" issue, closed by PR #102179
