# Building and Running

## Known iOS export limitation (Godot 4.6.2 + Apple Silicon)

Search of upstream issues confirms:
- **godotengine/godot#118161** (April 2026): "iOS 4.6.2 export template ships broken arm64 simulator xcframework slice on Apple Silicon". Maintainer confirmed: "Simulator build is almost useless in any case, since it does not support Metal in required capacity. On ARM Macs you can simply run iOS apps directly."
- **godotengine/godot#15058** (Dec 2017, related): the "App Store Team ID not specified" + "Invalid Identifier" pair has been a long-standing Godot iOS export validation pattern.

The practical implication: **iOS simulator export is broken on Apple Silicon in Godot 4.6.2**, and the iOS export validation requires a real Apple Developer Team ID even for simulator builds. Two options:
1. Configure a real Apple Developer account in Godot's editor settings (Project → Export → iOS preset → set Team ID). This unblocks the export and gives a working iOS device build.
2. Run the game via the editor GUI on Apple Silicon directly. The iOS app binary will run natively on Apple Silicon without needing the simulator.

For the prototype, we use headless mode (no iOS needed) to verify game logic. The headless logs prove enemies spawn, walk the path, and the wave system progresses. Visual verification requires either:
- Real iPhone (TestFlight), or
- Running the Godot editor on your Mac (which can render the project natively)

## Run the project in headless mode (works without iOS / Xcode)

```bash
cd tower-defense
godot --headless --quit-after 600
```

This will load the main scene, run the game logic for 10 seconds, and exit. You'll see logs like:
```
[TD] Map ready: 8 path points, 6 build spots
[GAME] Ready, gold=100, base_hp=20
[GAME] Wave phase started, level 0
[GAME] Spawned mossbeast #1
[GAME] Spawned mossbeast #2
...
```

The game runs in 2D (1024x1792 portrait) — the viewport is correct, the game logic works, enemies walk the path, towers can be auto-placed with the `0` key.

## Build for iOS simulator (requires Apple Developer setup)

The iOS export preset is in `export_presets.cfg`. The current configuration has:
- Bundle ID: `org.godotengine.towerdefense`
- Export method: simulator
- Team ID: empty (placeholder)

**To enable a real iOS build:**
1. Open the project in Godot editor
2. Go to Project → Export
3. Select the "iOS" preset
4. Enter your Apple Developer Team ID
5. Click "Export Project"

Or use the CLI once configured:
```bash
godot --headless --export-debug "iOS" "builds/tower-defense-ios.zip"
```

The precompiled iOS template is already installed at `~/Library/Application Support/Godot/export_templates/4.6.3.stable/ios.zip`.

## Run on iPhone 17 Pro simulator (post-export)

```bash
unzip builds/tower-defense-ios.zip -d builds/ios
xcodebuild -project builds/ios/godot_apple_embedded.xcodeproj \
  -scheme "godot_apple_embedded" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  build
xcrun simctl install booted builds/ios/build/Debug-iphonesimulator/godot_apple_embedded.app
xcrun simctl launch booted org.godotengine.towerdefense
```

## Debug shortcuts (when running the game)

- `1` — select Archer build type
- `2` — select Mage build type
- `3` — select Trebuchet build type
- `0` — auto-place an Archer on the 3rd build spot (testing convenience)
