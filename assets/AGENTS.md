# AGENTS.md — assets/

This folder contains all game assets: sprites, tilesets, audio, fonts, and particle textures.

## Structure

```
assets/
  sprites/     — Character and object sprites (.png)
  tilesets/    — Tileset images + .tres tileset resources
  particles/   — Particle textures (.png)
  audio/
    sfx/       — Short sound effects (.ogg / .wav)
    music/     — Background music tracks (.ogg)
  fonts/       — Pixel fonts (.ttf / .otf)
```

## Rules

1. **Sprites:** `.png` with transparent background. Grid-aligned: 16×16 or 32×32 pixels.
2. **Tilesets:** Same grid size as sprites. One `.png` per tileset + one `.tres` Godot TileSet resource.
3. **Audio SFX:** `.wav` for short sounds (under 1 second). `.ogg` for longer sounds.
4. **Music:** `.ogg` only. Loop seamlessly. Keep under 2MB per track for web load.
5. **Fonts:** Pixel fonts with permissive license. Include license file if required.
6. **Import settings:** After adding an asset, open it in Godot and verify import settings (filter mode, compression). Pixel art must use **Nearest** filter.
7. **File naming:** `snake_case` for all asset files. `player_idle.png`, `grass_tileset.png`, `hit_sfx.wav`.

## Pixel Art Import Settings

For every `.png` sprite or tileset:

1. Select the file in Godot's FileSystem dock.
2. In the Import tab, set:
   - **Filter:** Nearest
   - **Compress:** Lossless
   - **Mipmaps:** Off (for pixel art)
3. Click **Reimport**.

These settings prevent blurry scaling in the browser.

## Asset Size Limits (Browser)

- Single sprite: ≤ 64×64 pixels (upscale in-engine if needed)
- Tileset atlas: ≤ 512×512 pixels
- SFX: ≤ 100KB each
- Music track: ≤ 2MB each
- Total project: ≤ 20MB for fast web load
