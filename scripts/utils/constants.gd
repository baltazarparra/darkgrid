class_name Constants
extends RefCounted

# ─── Grid ──────────────────────────────────────────
const TILE_SIZE := 32
const GRID_WIDTH := 20
const GRID_HEIGHT := 15

# ─── Combat ────────────────────────────────────────
const TIMING_WINDOW_FRAMES := 12
const TIMING_PERFECT_FRAMES := 3
const ATTACK_COOLDOWN_SECONDS := 1.5
const DODGE_COOLDOWN_SECONDS := 0.5

# ─── Damage ────────────────────────────────────────
const DAMAGE_BASE := 10
const DAMAGE_CRIT_MULTIPLIER := 2.5
const DAMAGE_COUNTER_MULTIPLIER := 1.5

# ─── Health ────────────────────────────────────────
const CAIPORA_MAX_HEALTH := 100
const ENEMY_MAX_HEALTH := 80
const BOSS_MAX_HEALTH := 200

# ─── Colors (Horror Folk Palette) ──────────────────
const COLOR_NIGHT := Color("#0d1117")
const COLOR_ARENA_BG := Color("#1a0f0f")
const COLOR_EARTH := Color("#3d1f1f")
const COLOR_MOSS := Color("#1a2f1a")
const COLOR_BLOOD := Color("#8b0000")
const COLOR_AMBER := Color("#ff6b00")
const COLOR_TEXT := Color("#c9d1d9")

# ─── Physics Layers ────────────────────────────────
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_WALL := 3
const LAYER_TRIGGER := 4
