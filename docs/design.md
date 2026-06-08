# Tower Defence — Locked Design

> Source of truth for what we're building. If this file conflicts with code, the code is wrong.

## Project at a glance

- **Platform:** iOS (iPhone 17 Pro primary, iPad secondary)
- **Engine:** Godot 4 (latest stable)
- **Art style:** Stylized 2D top-down with 3/4 perspective, flat shading, painterly textures
- **Theme:** Overgrown ancient stone ruins in a misty forest, golden late afternoon
- **Aspect:** Portrait 9:16 (iPhone native)
- **Path layout:** Vertical S-curve. Top of screen = enemy spawn. Bottom = player keep with cyan portal.

## Two-phase scope

The project is built in two phases.

### Phase 1 — Prototype (current)

- 1 hand-designed map
- 5 levels of escalating difficulty
- 3 tower types (1 tier each)
- 5 enemy types
- 5 waves per level
- Runnable on iPhone 17 Pro simulator

**Goal:** prove the gameplay loop, lock the visual direction, ship a buildable artifact before scaling up.

### Phase 2 — Full campaign (deferred)

- 8 upgradable tower types, 3 tiers each = 24 unique tower sprites
- 15 enemy types across 4 difficulty tiers
- 100 hand-designed unique levels
- 8–10 thematic map sets (forest, swamp, mountain, dungeon, lava, ice, ruins, desert, etc.)
- Boss-tier enemies on levels 95 and 100

## Tower roster

### Prototype (3 types, 1 tier)

| Type | Role | Build cost | Range | Damage | Attack speed | Special |
|---|---|---|---|---|---|---|
| Archer | Basic physical, fast single-target | 50g | 120px | 8 | 1.2s | — |
| Mage | Magical AoE, slow | 100g | 100px | 25 | 2.0s | 40px AoE |
| Ballista | Heavy physical, long range, single-target | 150g | 200px | 60 | 3.0s | +50% crit |

### Full-scope (8 archetypes, 3 tiers each)

1. **Archer** — basic physical, fast single-target
2. **Mage** — magical AoE, slow
3. **Ballista** — heavy physical single-target, long range
4. **Cannon** — siege, AoE, slow
5. **Frost** — magical, slows enemies
6. **Lightning** — magical, chains between enemies
7. **Poison** — magical, DoT, AoE
8. **Barracks** — ground-only, blocks enemies

### Upgrade path (full-scope, design only — not implemented in prototype)

- **Tier 1 → Tier 2:** 75% of build cost. +50% damage, +20% range.
- **Tier 2 → Tier 3:** 150% of build cost. +100% damage, +50% range, special unlock per tower.
- Visual: sprite changes per tier (3 distinct looks per tower = 24 unique tower sprites total).

## Enemy roster

### Prototype (5 types)

| Type | HP | Speed | Gold | Leak damage | Behaviour |
|---|---|---|---|---|---|
| Moss-beast | 50 | 60 px/s | 5 | 1 | Fodder, no special |
| Skeleton | 80 | 70 px/s | 8 | 1 | Fodder, no special |
| Gnoll | 60 | 110 px/s | 7 | 1 | Fast fodder |
| Harpy | 70 | 80 px/s | 12 | 1 | **Flies — only ranged towers can hit** |
| Corrupted brute | 500 | 40 px/s | 50 | 5 | **Miniboss — AoE explosion on death (50px)** |

### Full-scope (15 across 4 tiers)

**Fodder (levels 1–30):** Moss-beast, Skeleton, Gnoll, Cultist
**Mid (levels 31–60):** Armoured knight, Corrupted shaman, Harpy, Assassin
**Elite (levels 61–85):** Golem, Wraith, Siege beast, Plague bearer
**Boss (levels 86–100):** Corrupted treant, Lich king

## Difficulty curve (prototype)

| Level | Enemies | Waves | Total enemies | Twist |
|---|---|---|---|---|
| 1 | Moss-beast | 1 | 5 | Tutorial |
| 2 | Moss-beast, Skeleton | 2 | 8 | Skeletons appear |
| 3 | Moss-beast, Skeleton, Gnoll | 3 | 12 | Gnolls force path coverage |
| 4 | Moss-beast, Skeleton, Gnoll, Harpy | 4 | 15 | Harpies force ballista |
| 5 | All 5 + Corrupted brute miniboss | 5 | 20 | Brute AoE-on-death punishes clustering |

## Art pipeline

- **Image model:** `minimax-portal/image-01` (M3's native image model)
- **Format:** JPEG (M3 does not support transparency)
- **Prompt limit:** 1500 characters
- **Strategy:** Painterly 512px sprites. Opaque path means we don't need transparency in v1. Each sprite is a focused close-up, not a full-scene render.
- **Why this approach:** M3's image-01 is the only configured image model. Real production TDs use pixel-perfect pixel art or hand-drawn vector — out of scope for this project's M3-only constraint.

## Project structure

```
tower-defense/
├── assets/
│   ├── towers/      # Tower sprites (per type, per tier)
│   ├── enemies/     # Enemy sprites
│   ├── environment/ # Map background, path, build spots
│   └── ui/          # Buttons, icons, fonts
├── scenes/          # Godot scene files
├── scripts/         # GDScript
├── docs/            # Design docs, concept art
│   ├── design.md    # This file
│   └── concept-art/ # Reference renders
└── tests/           # Unit tests
```

## Build targets

- **Primary:** iPhone 17 Pro simulator (UUID `4BEA344F-440B-4A28-B4CC-266FFFA1ADF9`)
- **Secondary:** Real iPhone (TestFlight) once prototype is solid
- **Tertiary:** iPad (deferred)

## Open issues (Phase 1)

- #1 — This design doc (this issue, in progress)
- #2 — Godot 4 project skeleton + iOS export
- #3 — Tower close-up art (Archer, Mage, Ballista)
- #4 — Enemy close-up art (Moss-beast, Skeleton, Gnoll, Harpy, Corrupted brute)
- #5 — 5-level prototype campaign
- #6 — Tower implementation (3 types, 1 tier)
- #7 — Enemy implementation (5 types)
- #8 — 1 hand-crafted map
- #9 — Repo skeleton, .gitignore, directory structure

## Anti-patterns (things we will not do)

- Social features, leaderboards, login, accounts — **no**
- Newsfeed, friends, sharing, "send to friend" — **no**
- Ads, IAP, pay-to-skip, gacha — **no**
- Tutorial videos, splash screens, "rate us" popups — **no**
- Anything that isn't pure gameplay

This is a tower defence game. The game is the product.
