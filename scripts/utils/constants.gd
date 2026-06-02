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
const CAIPORA_MAX_HEALTH := 1
const ENEMY_MAX_HEALTH := 5
const BOSS_MAX_HEALTH := 10

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
