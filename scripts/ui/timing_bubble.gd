class_name TimingBubble
extends Node2D

# ─── Signals ───────────────────────────────────────
signal vulnerable_entered

# ─── Constants ─────────────────────────────────────
const RADIUS_MIN: float = 4.0
const RADIUS_MAX: float = 40.0

const PHASE_GROW: int = 0
const PHASE_VULNERABLE: int = 1
const PHASE_EXPLODE: int = 2
const PHASE_IDLE: int = 3

# ─── State ─────────────────────────────────────────
var _duration: float = 0.8
var _perfect_start: float = 0.65
var _perfect_end: float = 0.85
var _elapsed: float = 0.0
var _phase: int = PHASE_IDLE
var _radius: float = RADIUS_MIN
var _color: Color = Color(1, 1, 1, 0.2)
var _burst_timer: float = -1.0
var _defense_mode: bool = false
var _vuln_color: Color = Color.TRANSPARENT
var _key_hint: String = "up"

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if _burst_timer >= 0.0:
		_burst_timer -= delta
		var t: float = 1.0 - maxf(0.0, _burst_timer / 0.12)
		_color = Color(1, 1, 1, lerpf(0.9, 0.0, t))
		_radius = lerpf(RADIUS_MAX * 0.8, RADIUS_MAX * 1.6, t)
		queue_redraw()
		if _burst_timer <= 0.0:
			_phase = PHASE_IDLE
			visible = false
		return

	if _phase == PHASE_IDLE:
		return

	_elapsed += delta
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)

	match _phase:
		PHASE_GROW:
			if progress >= _perfect_start:
				_phase = PHASE_VULNERABLE
				vulnerable_entered.emit()
			else:
				var t: float = progress / _perfect_start
				_radius = lerpf(RADIUS_MIN, RADIUS_MAX, t)
				_color = Color(1.0, 1.0, 1.0, lerpf(0.2, 0.55, t))

		PHASE_VULNERABLE:
			if progress >= _perfect_end:
				_phase = PHASE_EXPLODE
			else:
				var t: float = (progress - _perfect_start) / (_perfect_end - _perfect_start)
				var pulse: float = sin(t * TAU * 4.0) * 0.15
				_radius = RADIUS_MAX * (1.1 + pulse * 0.1)
				if _vuln_color.a > 0.0:
					_color = Color(_vuln_color.r, _vuln_color.g, _vuln_color.b, 0.85 + pulse)
				elif _defense_mode:
					_color = Color(0.05 + pulse * 0.05, 0.3 + pulse * 0.1, 1.0, 0.85 + pulse)
				else:
					_color = Color(1.0, 0.05 + pulse * 0.1, 0.05 + pulse * 0.1, 0.85 + pulse)

		PHASE_EXPLODE:
			var t: float = (progress - _perfect_end) / (1.0 - _perfect_end)
			_radius = RADIUS_MAX * lerpf(1.1, 3.2, t)
			_color = Color(lerpf(0.5, 0.1, t), 0.0, 0.0, lerpf(0.7, 0.0, t))
			if t >= 1.0:
				_phase = PHASE_IDLE
				visible = false

	queue_redraw()

func _draw() -> void:
	if _phase == PHASE_IDLE and _burst_timer < 0.0:
		return
	draw_circle(Vector2.ZERO, _radius, _color)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 32, Color(1, 1, 1, _color.a * 0.4), 1.5)
	if _phase == PHASE_VULNERABLE:
		_draw_arrow(_key_hint)

# ─── Private helpers ───────────────────────────────
func _draw_arrow(dir: String) -> void:
	const PX: float = 5.0
	var grid: Array
	match dir:
		"up":
			grid = [
				"...X...",
				"..XXX..",
				".XXXXX.",
				"XXXXXXX",
				"...X...",
				"...X...",
				"...X...",
			]
		"down":
			grid = [
				"...X...",
				"...X...",
				"...X...",
				"XXXXXXX",
				".XXXXX.",
				"..XXX..",
				"...X...",
			]
		"left":
			grid = [
				"...X...",
				"..X....",
				".X.....",
				"XXXXXXX",
				".X.....",
				"..X....",
				"...X...",
			]
		"right":
			grid = [
				"...X...",
				"....X..",
				".....X.",
				"XXXXXXX",
				".....X.",
				"....X..",
				"...X...",
			]
	var rows: int = grid.size()
	var cols: int = 7
	var ox: float = -cols * PX * 0.5
	var oy: float = -rows * PX * 0.5
	for row in rows:
		for col in cols:
			if grid[row][col] == "X":
				draw_rect(Rect2(ox + col * PX, oy + row * PX, PX, PX), Color(1.0, 1.0, 1.0, 0.9))

# ─── Public API ────────────────────────────────────
func show_bubble(world_pos: Vector2, duration: float, perfect_start: float, perfect_end: float, defense: bool = false, vuln_color: Color = Color.TRANSPARENT, key_hint: String = "up") -> void:
	_duration = duration
	_perfect_start = perfect_start
	_perfect_end = perfect_end
	_elapsed = 0.0
	_phase = PHASE_GROW
	_burst_timer = -1.0
	_defense_mode = defense
	_vuln_color = vuln_color
	_key_hint = key_hint
	_radius = RADIUS_MIN
	_color = Color(1, 1, 1, 0.2)
	position = world_pos
	visible = true
	queue_redraw()

func hide_bubble() -> void:
	_phase = PHASE_IDLE
	_burst_timer = -1.0
	visible = false

func burst_success() -> void:
	_phase = PHASE_IDLE
	_burst_timer = 0.12
	_color = Color(1, 1, 1, 0.9)
	_radius = RADIUS_MAX * 0.8
	visible = true
	queue_redraw()
