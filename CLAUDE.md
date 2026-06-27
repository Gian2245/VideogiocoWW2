# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ProgettoConAntigravity** is a 2D side-scrolling WW2 shooter/platformer built with **Godot 4.6** (GL Compatibility mode). Written in GDScript. No external build tools — open the folder in Godot 4.6 and press F5 to run.

Main scene: `scenes/game1.tscn`

## Running the Game

1. Open Godot 4.6 and import the project folder.
2. Press **F5** (or "Play") to run `scenes/game1.tscn`.
3. There are no CLI build steps, linters, or test suites.

## Project Structure

```
scenes/       — .tscn scene files (game1, player_1, HUD, enemy_raider_1, TutorialZone, BreakableBlock)
SCRIPTS/      — GDScript (.gd) files attached to scene nodes
assets/       — Sprite sheets and background images
  Soldier_1/  — Player animations (Walk, Run, Idle, Attack, Shot, Recharge, Grenade, Explosion)
  Raider_1/   — Enemy Raider sprites (Idle, Hurt, Dead)
  Raider_2/, Raider_3/ — Future enemy variants (not yet wired up)
  Blocchi/    — Breakable block textures (blocco3-5.png)
```

## Architecture

### Scene Hierarchy (`game1.tscn`)
```
Game1 (Node2D)
├── HUD (CanvasLayer) — hud.gd
├── ParallaxBackground
│   └── Sfondo — sfondo.gd (dual-layer, 80% scroll, texture crossfade)
├── Player (CharacterBody2D) — palyerScript.gd
├── Pavimento (StaticBody2D) — floor at y=910
├── TutorialZone × 6 (Area2D) — tutorial_zone.gd
├── EnemyRaider × N (CharacterBody2D) — enemy_raider.gd
└── BreakableBlock × N (StaticBody2D) — BreakableBlock.gd
```

### Key Scripts

| Script | Node type | Responsibility |
|--------|-----------|----------------|
| `SCRIPTS/palyerScript.gd` | CharacterBody2D | Movement, shooting, melee, grenades, health/armor |
| `SCRIPTS/enemy_raider.gd` | CharacterBody2D | Raider AI: idle anim, facing, hurt/death states, health bar |
| `SCRIPTS/hud.gd` | CanvasLayer | Ammo counter, health/armor bars, grenade count, weapon info |
| `SCRIPTS/sfondo.gd` | Node2D | Parallax background scrolling and texture crossfade |
| `SCRIPTS/BreakableBlock.gd` | StaticBody2D | 2-hit destructible blocks with red-flash feedback |
| `SCRIPTS/tutorial_zone.gd` | Area2D | Fade-in/out hint labels when player enters zones |

### Groups (Godot group system for loose coupling)
- `"player"` — Player node (used by enemies to locate/face the player)
- `"enemies"` — All EnemyRaider nodes (targeted by player attacks)
- `"breakable"` — BreakableBlock nodes (targeted by melee only)
- `"hud"` — HUD CanvasLayer (player script calls into it to update UI)

### Player Combat Numbers
- Walk: 300 px/s — Run (double-tap): 550 px/s
- Melee (Z): 35 damage, 250 px range
- Shoot (X): 20 damage, 400 px range, 8-round magazine; reload with R
- Grenade (G): 2 grenades, 200 px explosion radius, scaling damage
- Health: 100 max — Armor: 50 max (absorbs damage first)

### Input Actions (defined in `project.godot`)
| Action | Key |
|--------|-----|
| `ui_left` / `ui_right` | Arrow keys |
| `ui_accept` | Space (jump) |
| `spara` | X (shoot) |
| `ricarica` | R (reload) |
| `granata` | G (grenade) |
| Melee | Z (hardcoded in script) |

### Display
- Viewport: 1280×720, `canvas_items` stretch mode
- Characters scaled 3.2× for large pixel-art look
- Rendering: GL Compatibility / D3D12 driver on Windows

## Adding New Content

- **New enemy type:** Duplicate `scenes/enemy_raider_1.tscn` + `SCRIPTS/enemy_raider.gd`, change sprite paths to `Raider_2/` or `Raider_3/`, add to `"enemies"` group.
- **New tutorial zone:** Instance `scenes/TutorialZone.tscn` in `game1.tscn`, set the label text and x-position.
- **New breakable block:** Instance `scenes/BreakableBlock.tscn`, assign a texture from `assets/Blocchi/`.
- **Background change:** Swap the two textures referenced in `sfondo.gd` and adjust the crossfade trigger x-coordinate.
