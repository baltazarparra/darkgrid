class_name Constants
extends RefCounted

# ─── Grid ──────────────────────────────────────────
const TILE_SIZE := 32
const GRID_WIDTH := 26
const GRID_HEIGHT := 18

# ─── Combat ────────────────────────────────────────
const TIMING_WINDOW_FRAMES := 12
const TIMING_PERFECT_FRAMES := 3
const ATTACK_COOLDOWN_SECONDS := 0.0
const DODGE_COOLDOWN_SECONDS := 0.5
const TIMING_WINDOW_ATTACK := 0.8
const TIMING_PERFECT_START := 0.65
const TIMING_PERFECT_END := 0.85
const TIMING_DOUBLE_CHANCE := 0.30
const TIMING_DOUBLE_INTERVAL := 0.5
const TIMING_DOUBLE_BUBBLE_SPREAD_MIN := 60.0
const TIMING_DOUBLE_BUBBLE_SPREAD_MAX := 80.0
const TIMING_DOUBLE_BLOCK_DURATION := 0.55  # TIMING_WINDOW_ATTACK (0.8) - 0.25

# ─── Damage ────────────────────────────────────────
const DAMAGE_BASE := 1
const DAMAGE_CRIT_MULTIPLIER := 1.0
const DAMAGE_COUNTER_MULTIPLIER := 1.0

# ─── Health ────────────────────────────────────────
const CAIPORA_MAX_HEALTH := 2
const ENEMY_MAX_HEALTH := 5
const BOSS_MAX_HEALTH := 10

# ─── Colors (Horror Folk Palette) ──────────────────
# Fonte ÚNICA de cor do jogo. Qualquer Color() novo deve referenciar/derivar daqui —
# não inventar tons soltos nos scripts. (doom_fire.gd é a única exceção: gradiente próprio.)
#
# Tons-base (paleta amazônica de horror folk):
const COLOR_NIGHT := Color("#0d1117")    # fundo / noite
const COLOR_ARENA_BG := Color("#1a0f0f") # fundo da arena
const COLOR_EARTH := Color("#3d1f1f")    # terra / trilha
const COLOR_MOSS := Color("#1a2f1a")     # folhagem / musgo
const COLOR_BLOOD := Color("#8b0000")    # sangue / dano
const COLOR_AMBER := Color("#ff6b00")    # destaque / fogo / cue
const COLOR_TEXT := Color("#c9d1d9")     # texto / branco sujo

# Vida (ícones): ativo usa COLOR_BLOOD/COLOR_AMBER; "vazio" = tom apagado translúcido.
const COLOR_BLOOD_EMPTY := Color(0.25, 0.04, 0.04, 0.35)
const COLOR_AMBER_EMPTY := Color(0.3, 0.18, 0.02, 0.35)

# Entidades no mapa (encantado/maligno → roxo).
const COLOR_ENEMY_TINT := Color(0.7, 0.5, 0.9, 1.0)   # criatura comum (modulate)
const COLOR_BOSS_TINT := Color(0.08, 0.0, 0.14, 1.0)  # boss bruxo (modulate)
const COLOR_AURA_BOSS := Color(0.18, 0.0, 0.28, 0.75) # aura de partículas do boss
const COLOR_EXIT := Color(1.0, 0.42, 0.0, 0.85)       # marcador de saída (âmbar)

# Fogo procedural (fogueira do mapa) — gradiente quente.
const COLOR_FIRE_GLOW := Color(0.55, 0.08, 0.0, 0.35)
const COLOR_FIRE_HOT := Color(1.00, 0.55, 0.05)
const COLOR_FIRE_MID := Color(0.85, 0.30, 0.0)
const COLOR_FIRE_LOW := Color(0.75, 0.20, 0.0)

# Materiais de props/decoração (derivados intencionais da paleta).
const COLOR_GOLD := Color(0.92, 0.78, 0.12)
const COLOR_GOLD_DARK := Color(0.55, 0.42, 0.04)
const COLOR_WOOD := Color(0.32, 0.17, 0.04)
const COLOR_WOOD_DARK := Color(0.16, 0.07, 0.01)
const COLOR_METAL := Color(0.48, 0.38, 0.10)
const COLOR_BARK := Color(0.18, 0.11, 0.05)
const COLOR_BARK_DARK := Color(0.10, 0.06, 0.02)
const COLOR_BONE := Color(0.78, 0.74, 0.62)
const COLOR_BONE_HOLLOW := Color(0.12, 0.10, 0.08)
const COLOR_STONE := Color(0.34, 0.34, 0.38)
const COLOR_STONE_DARK := Color(0.20, 0.20, 0.24)
const COLOR_MOSS_DECO := Color(0.13, 0.24, 0.10, 0.7)
const COLOR_MOSS_DECO_DARK := Color(0.08, 0.16, 0.06, 0.7)
const COLOR_BLOOD_POOL := Color(0.42, 0.02, 0.02, 0.75)
const COLOR_BLOOD_POOL_DARK := Color(0.24, 0.0, 0.0, 0.8)
const COLOR_PENTAGRAM := Color(0.50, 0.0, 0.0)

# Cues de combate (telegraph/bolhas). Valores >1 são overbright p/ glow intencional.
const COLOR_TELEGRAPH_ENEMY := Color(1.4, 0.4, 0.4)     # wind-up da criatura (vermelho)
const COLOR_TELEGRAPH_ENEMY_ALT := Color(1.4, 0.9, 0.2) # flash de ataque duplo (âmbar)
const COLOR_TELEGRAPH_BOSS := Color(0.5, 0.05, 1.0)     # wind-up do boss (roxo)
const COLOR_BUBBLE_BOSS := Color(0.55, 0.05, 0.95, 1.0) # bolha de timing do boss

# Partículas de feedback de combate (>1 = overbright p/ glow aditivo intencional).
const COLOR_PARTICLE_SPARK := Color(1.0, 0.92, 0.6, 1.0)  # faísca de crítico (dourado)
const COLOR_PARTICLE_DODGE := Color(0.9, 0.95, 1.0, 0.95) # flash de esquiva (azul-claro)
const COLOR_PARTICLE_FAIL := Color(0.20, 0.18, 0.22, 0.9) # estilhaço de erro (cinza-fumaça morto, deriva de COLOR_STONE_DARK)

# ─── UI Design Tokens (escala de espaçamento / tipografia) ──
# Padronização AAA: telas e HUD consomem estes tokens, nunca números soltos.
const SPACE_XS := 8
const SPACE_SM := 16
const SPACE_MD := 24
const SPACE_LG := 40
const SPACE_XL := 64

const FONT_SM := 12
const FONT_MD := 18
const FONT_LG := 28
const FONT_TITLE := 48

# Direção de arte da UI (scenes/AGENTS.md): cantos retos, bordas duras — sem arredondar.
const UI_CORNER_RADIUS := 0
const UI_BORDER_WIDTH := 2
const UI_PADDING_H := 20  # padding horizontal interno de botões/painéis
const UI_PADDING_V := 12  # padding vertical interno

# ─── Physics Layers ────────────────────────────────
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_WALL := 3
const LAYER_TRIGGER := 4
