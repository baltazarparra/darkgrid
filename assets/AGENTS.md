# AGENTS.md — assets/

This folder contains all game assets.

## Philosophy

**MVP-first.** Use ready-made CC0 assets (primarily Kenney) to validate the game loop quickly. Do not use AI-generated sprites for the core game — AI art tends to produce visual inconsistency and requires heavy cleanup on grid alignment, palette, and transparency.

AI makes sense later, for promotional material: itch.io cover, banner, icon.

## Structure

```
assets/
  sprites/     — All sprites: characters, enemies, tiles, items (.png)
  audio/sfx/   — Sound effects (.wav, generated with jsfxr / sfxr)
  fonts/       — Pixel font (.ttf / .otf)
  licenses/    — Licenses and attribution for CC0 assets
```

## Rules

1. **Sprites:** CC0 only. Kenney.nl is the primary source. Pick **one pack** (e.g., Tiny Dungeon) and stick to it for visual consistency.
2. **Grid alignment:** 16×16 or 32×32 pixels. Transparent background. Use `snake_case` filenames.
3. **Audio:** Generate with [jsfxr](https://sfxr.me/) or [sfxr](https://www.drpetter.se/project_sfxr.html). Export as `.wav`. Short, punchy, under 100KB each.
4. **No music in MVP.** SFX only. Music adds complexity and file size we don't need for the first Web build.
5. **UI:** Use Godot's native UI nodes (`Button`, `Panel`, `Label`, `ProgressBar`). Do not create custom UI sprite sheets.
6. **Fonts:** One pixel font with a permissive license. Kenney Fonts or "Press Start 2P" (Google Fonts).
7. **Import settings:** For every `.png`, set Filter to **Nearest**, Compress to **Lossless**, Mipmaps to **Off**.
8. **Licenses:** Every asset pack downloaded must have its license copied into `assets/licenses/`.

## Horror Folk Palette

The visual identity is **dark, humid, and hostile**. Pixel art should evoke:

| Use | Color | Hex |
|-----|-------|-----|
| Background / Night | Deep blue-black | `#0d1117` |
| Earth / Trail | Reddish brown | `#3d1f1f` |
| Foliage / Moss | Rotten green | `#1a2f1a` |
| Blood / Damage | Blood red | `#8b0000` |
| Highlight / Cue | Amber / Fire | `#ff6b00` |
| Text | Dirty white | `#c9d1d9` |

## Kenney Pack Recommendations

| Pack | Use For |
|------|---------|
| Tiny Dungeon | Tileset (floor, wall, arena), items |
| Tiny Town | Environment variations |
| 1-Bit Pack | Minimalist fallback, prototyping |
| RPG Urban | Additional tiles if needed |
| Character packs | Caipora sprite (idle/walk) |
| Monster/Enemy packs | Creature sprite (skeleton, slime, goblin) |

## SFX Checklist (MVP)

Generate these with jsfxr/sfxr:

- [ ] `attack.wav` — Caipora slash/strike
- [ ] `hit.wav` — Damage impact
- [ ] `dodge.wav` — Quick whoosh/swish
- [ ] `timing_perfect.wav` — Reward ding/chime
- [ ] `death.wav` — Defeat/explosion
- [ ] `ui_click.wav` — Menu interaction

## Asset Size Limits (Browser)

- Single sprite: ≤ 64×64 pixels (upscale in-engine if needed)
- Tileset atlas: ≤ 512×512 pixels
- SFX: ≤ 100KB each
- Total project: ≤ 10MB for fast web load (MVP target)
