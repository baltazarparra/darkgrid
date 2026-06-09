# AGENTS.md — assets/

This folder contains all game assets.

## Philosophy

**Coesão acima de tudo.** A identidade visual é um horror folclórico amazônico,
sombrio e hostil. A coesão vem de uma **paleta única forçada** (`scripts/utils/constants.gd`)
+ uma **camada de atmosfera** (vinheta/grão/color-grade) que faz arte de origens
diferentes parecer do mesmo mundo.

**Fontes de arte permitidas:**
- **Pixel art autoral procedural** (geradores em `scripts/tools/gen_*.py`) — abordagem
  atual: determinística, na paleta, zero dependência externa. Caipora, caçador, bruxo
  e tiles foram gerados assim.
- **Packs CC0** (ex. Kenney) como base, recoloridos na paleta. Copie a licença para
  `assets/licenses/`.
- **IA permitida no core** (personagens/props), desde que passe pelo **pipeline de
  limpeza obrigatório** (ver Rules). IA também serve a material promocional (capa,
  banner, ícone).

## Structure

```
assets/
  sprites/     — All sprites: characters, enemies, tiles, items (.png)
  shaders/     — Shaders de atmosfera/efeito (.gdshader)
  audio/sfx/   — Sound effects (.wav, generated with jsfxr / sfxr)
  fonts/       — Pixel font (.ttf / .otf) + theme.tres (design system da UI)
  licenses/    — Licenses and attribution for CC0 assets
```

## Rules

1. **Sprites:** autoral procedural (preferido), CC0 recolorido, ou IA limpa (ver pipeline).
   Sempre `snake_case`, fundo transparente, na paleta.
2. **Tamanho:** **personagens 48×48**, **tiles/itens 32×32** (grid lógico = 32).
   Sprites de 48px transbordam o tile pra cima (offset.y = -8 no AnimatedSprite2D;
   pés na base). Background transparente.
   **Exceção — Caipora (protagonista/guardiã): 64×64** (dentro do limite ≤64×64),
   por ser imponente (maior que os caçadores). Usa offset/scale próprios por cena
   (arena vs exploração) para os pés assentarem na base do tile.
2b. **Pipeline de limpeza para IA (obrigatório):** quantizar para a paleta
   (`constants.gd`), alinhar ao grid, garantir alpha limpo (sem halos), ≤ 64×64.
   Sprite que não passar por isso não entra.
2c. **Protagonista é especial:** os `player_*.png` saem SOMENTE de
   `scripts/tools/gen_caipora.py` (pipeline premium: supersample 8× → snap de
   paleta → selout → rim light térmico). NUNCA editar esses PNGs à mão nem
   recriá-los pelo `gen_chars.py`. O design é lei: `docs/CONCEITO-protagonista.md`.
3. **Audio:** Generate with [jsfxr](https://sfxr.me/) or [sfxr](https://www.drpetter.se/project_sfxr.html). Export as `.wav`. Short, punchy, under 100KB each.
4. **No music in MVP.** SFX only. Music adds complexity and file size we don't need for the first Web build.
5. **UI:** Use Godot's native UI nodes (`Button`, `Panel`, `Label`, `ProgressBar`). Do not create custom UI sprite sheets.
6. **Fonts:** One pixel font with a permissive license. Kenney Fonts or "Press Start 2P" (Google Fonts).
7. **Import settings:** For every `.png`, set Filter to **Nearest**, Compress to **Lossless**, Mipmaps to **Off**.
8. **Licenses:** Every asset pack downloaded must have its license copied into `assets/licenses/`.

## Horror Folk Palette

A fonte de verdade em runtime é `scripts/utils/constants.gd` (`COLOR_*`); a tabela abaixo
é referência. A UI segue `assets/fonts/theme.tres` (bordas duras, sem cantos arredondados).

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
