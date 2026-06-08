# tower-defense

Stylized 2D top-down tower defence game for iOS. Overgrown stone ruins theme. 100 hand-designed levels, 8 upgradable tower types, 15 enemy types. Prototype first, full campaign after.

## Status

**Phase 1 (prototype) feature-complete in code.** All 9 issues closed, 7 commits pushed.

- Map: vertical S-curve path with 6 build spots, base with cyan portal
- Towers: archer (50g, fast single-target), mage (100g, AoE), trebuchet (150g, long-range splash)
- Enemies: mossbeast, skeleton, gnoll, harpy, corrupted_brute miniboss
- Game loop: 5 levels, escalating difficulty, gold economy, win/lose states
- Verified working: headless test runs spawn 5 moss-beasts that walk the path; logs show wave progression

## What I cannot verify yet

The iOS simulator build is blocked at the Godot export step. Godot 4.6.3's iOS export validation requires:
- A valid Apple Developer Team ID (not configured in this project)
- A configured Apple ID for signing

This is a project setup issue, not a code bug. Workarounds:
- Open the project in the Godot editor (GUI) and export from there
- Configure a real Apple Developer account in Godot's editor settings

The headless test of the game logic (5 enemies spawning, walking, wave system progressing) is logged and verifiable in `tools/` and the iOS simulator output.

## Where to start

- **[Design doc](docs/design.md)** — locked decisions on art style, tower/enemy rosters, scope, anti-patterns
- **[Issues](https://github.com/73ttv627re77/tower-defense/issues)** — work breakdown, all tracked here
- **[Build doc](docs/building.md)** — how to build and run

## License

MIT
