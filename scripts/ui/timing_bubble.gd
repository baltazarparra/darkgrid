class_name TimingBubble
extends Node2D

# ─── Signals ───────────────────────────────────────
signal vulnerable_entered

# ─── Constants ─────────────────────────────────────
## Anel-alvo fixo: marca a janela de acerto. O jogador aperta quando o anel
## convergente se sobrepõe a ele.
const RADIUS_TARGET: float = 40.0
## Maior extensão visual da bolha (raio inicial do anel convergente). Lido
## externamente por arena_manager.gd (_is_under_dpad) para afastar a bolha do
## D-pad — manter como o maior raio que a bolha desenha.
const RADIUS_MAX: float = RADIUS_TARGET * 1.9
## Raio final do colapso na falha (anel encolhe para dentro do alvo).
const RADIUS_COLLAPSE: float = RADIUS_TARGET * 0.12

const PHASE_ACTIVE: int = 0
const PHASE_IDLE: int = 1

## Flash verde-cristal ao ENTRAR na janela perfeita ("o cristal carregou").
## Curto de propósito: o telegraph do Curupira é um modulate sustentado no
## sprite do inimigo (curupira.gd), verde-folha; isto é um pop de 0.12s no anel,
## verde-menta, sempre pareado com o timing_alert_sound — outra linguagem.
const FLASH_S: float = 0.12

# ─── State ─────────────────────────────────────────
var _duration: float = 0.8
var _perfect_start: float = 0.65
var _perfect_end: float = 0.85
var _elapsed: float = 0.0
var _phase: int = PHASE_IDLE
var _outer_radius: float = RADIUS_MAX
var _color: Color = Color(1, 1, 1, 0.2)
var _target_alpha: float = 0.25
var _arrow_alpha: float = 0.35
var _vuln_emitted: bool = false
var _burst_timer: float = -1.0
var _burst_fail: bool = false
var _burst_radius: float = RADIUS_TARGET
var _burst_color: Color = Color(1, 1, 1, 0.9)
var _defense_mode: bool = false
var _vuln_color: Color = Color.TRANSPARENT
var _key_hint: String = "up"
var _frozen: bool = false
var _flash_timer: float = 0.0

# Sprite do glifo de direção (mesma garra tribal do D-pad redesenhado, 64×64).
var _arrow_sprite: Sprite2D

const _ARROW_TEXTURES := {
	"up":    preload("res://assets/sprites/dpad_up.png"),
	"down":  preload("res://assets/sprites/dpad_down.png"),
	"left":  preload("res://assets/sprites/dpad_left.png"),
	"right": preload("res://assets/sprites/dpad_right.png"),
}
# 64px sprite → ~35px dentro do anel-alvo de 40px de raio (PX=5 da versão grid).
const ARROW_SCALE := 0.55

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	visible = false
	_arrow_sprite = Sprite2D.new()
	_arrow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_arrow_sprite.scale = Vector2(ARROW_SCALE, ARROW_SCALE)
	_arrow_sprite.texture = _ARROW_TEXTURES["up"]
	_arrow_sprite.visible = false
	add_child(_arrow_sprite)

func _process(delta: float) -> void:
	if _frozen:
		return
	if _burst_timer >= 0.0:
		_process_burst(delta)
		return

	if _phase == PHASE_IDLE:
		return

	# Decai depois dos early-returns: o hit-stop (_frozen) congela o flash junto.
	_flash_timer = maxf(0.0, _flash_timer - delta)

	_elapsed += delta
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var pc: float = (_perfect_start + _perfect_end) * 0.5

	# Anel convergente: encolhe de RADIUS_MAX até encostar no alvo exatamente no
	# centro da zona perfeita, depois colapsa para dentro (leitura de falha).
	if progress <= pc:
		var t: float = progress / maxf(pc, 0.0001)
		_outer_radius = lerpf(RADIUS_MAX, RADIUS_TARGET, t)
	else:
		var t: float = (progress - pc) / maxf(1.0 - pc, 0.0001)
		_outer_radius = lerpf(RADIUS_TARGET, RADIUS_COLLAPSE, t)

	var in_perfect: bool = progress >= _perfect_start and progress <= _perfect_end
	if in_perfect and not _vuln_emitted:
		_vuln_emitted = true
		_flash_timer = FLASH_S  # sincronizado com o timing_alert_sound do listener
		vulnerable_entered.emit()

	# Cor do anel convergente + brilho do alvo + opacidade da seta.
	var mode_color: Color = _mode_color()
	if in_perfect:
		var t: float = (progress - _perfect_start) / maxf(_perfect_end - _perfect_start, 0.0001)
		var pulse: float = sin(t * TAU * 4.0) * 0.1
		_color = Color(mode_color.r, mode_color.g, mode_color.b, 0.95)
		_target_alpha = 0.7 + pulse
		_arrow_alpha = 0.9
	elif progress < _perfect_start:
		var t: float = progress / maxf(_perfect_start, 0.0001)
		_color = Color(mode_color.r, mode_color.g, mode_color.b, lerpf(0.45, 0.9, t))
		_target_alpha = 0.25
		_arrow_alpha = 0.35
	else:
		# Pós-janela: anel colapsando, esmaece.
		var t: float = (progress - _perfect_end) / maxf(1.0 - _perfect_end, 0.0001)
		_color = Color(mode_color.r * 0.5, mode_color.g * 0.2, mode_color.b * 0.2, lerpf(0.7, 0.0, t))
		_target_alpha = lerpf(0.25, 0.0, t)
		_arrow_alpha = lerpf(0.35, 0.0, t)

	_color = _flashed(_color)
	_update_arrow_sprite()
	queue_redraw()

func _process_burst(delta: float) -> void:
	_burst_timer -= delta
	var t: float = 1.0 - maxf(0.0, _burst_timer / 0.12)
	if _burst_fail:
		# Colapso: encolhe e escurece — leitura "morta" da falha.
		_burst_color = Color(0.2, 0.05, 0.05, lerpf(0.8, 0.0, t))
		_burst_radius = lerpf(RADIUS_TARGET * 0.8, RADIUS_TARGET * 0.3, t)
	else:
		_burst_color = Color(1, 1, 1, lerpf(0.9, 0.0, t))
		_burst_radius = lerpf(RADIUS_TARGET * 0.8, RADIUS_TARGET * 1.6, t)
	queue_redraw()
	if _burst_timer <= 0.0:
		_phase = PHASE_IDLE
		visible = false

func _draw() -> void:
	if _burst_timer >= 0.0:
		draw_circle(Vector2.ZERO, _burst_radius, _burst_color)
		draw_arc(Vector2.ZERO, _burst_radius, 0.0, TAU, 32, Color(1, 1, 1, _burst_color.a * 0.4), 1.5)
		return

	if _phase == PHASE_IDLE:
		return

	# 1. Anel-alvo fixo (a janela de acerto). Acende na zona perfeita.
	var target_col: Color = _flashed(_mode_color())
	draw_circle(Vector2.ZERO, RADIUS_TARGET, Color(target_col.r, target_col.g, target_col.b, _target_alpha * 0.35))
	draw_arc(Vector2.ZERO, RADIUS_TARGET, 0.0, TAU, 40, Color(target_col.r, target_col.g, target_col.b, _target_alpha), 2.0)

	# 2. Anel convergente (o timer): encolhe em direção ao alvo.
	draw_arc(Vector2.ZERO, _outer_radius, 0.0, TAU, 40, _color, 2.5)

	# 3. Glifo da tecla: atualizado via Sprite2D em _update_arrow_sprite (ver _process).

# ─── Private helpers ───────────────────────────────
func _mode_color() -> Color:
	if _vuln_color.a > 0.0:
		return Color(_vuln_color.r, _vuln_color.g, _vuln_color.b, 1.0)
	if _defense_mode:
		return Color(0.1, 0.6, 1.0, 1.0)
	return Color(1.0, 0.15, 0.1, 1.0)

## Lerp para o verde-cristal enquanto o flash da janela perfeita está ativo;
## decai linearmente de volta à cor de modo. Preserva o alpha de entrada.
func _flashed(c: Color) -> Color:
	if _flash_timer <= 0.0:
		return c
	var f: float = _flash_timer / FLASH_S
	var g: Color = Constants.COLOR_CRYSTAL_GLOW
	return Color(lerpf(c.r, g.r, f), lerpf(c.g, g.g, f), lerpf(c.b, g.b, f), c.a)

func _update_arrow_sprite() -> void:
	if _arrow_sprite == null:
		return
	if _burst_timer >= 0.0 or _phase == PHASE_IDLE:
		_arrow_sprite.visible = false
		return
	_arrow_sprite.visible = _arrow_alpha > 0.01
	if _arrow_sprite.visible:
		var tex: Texture2D = _ARROW_TEXTURES.get(_key_hint, _ARROW_TEXTURES["up"]) as Texture2D
		if _arrow_sprite.texture != tex:
			_arrow_sprite.texture = tex
		var col := _flashed(_mode_color())
		_arrow_sprite.modulate = Color(col.r, col.g, col.b, _arrow_alpha)

# ─── Public API ────────────────────────────────────
func show_bubble(world_pos: Vector2, duration: float, perfect_start: float, perfect_end: float, defense: bool = false, vuln_color: Color = Color.TRANSPARENT, key_hint: String = "up") -> void:
	_duration = duration
	_perfect_start = perfect_start
	_perfect_end = perfect_end
	_elapsed = 0.0
	_phase = PHASE_ACTIVE
	_burst_timer = -1.0
	_vuln_emitted = false
	_defense_mode = defense
	_vuln_color = vuln_color
	_key_hint = key_hint
	_outer_radius = RADIUS_MAX
	_target_alpha = 0.25
	_arrow_alpha = 0.35
	_flash_timer = 0.0
	_color = Color(1, 1, 1, 0.45)
	position = world_pos
	visible = true
	if _arrow_sprite != null:
		_arrow_sprite.texture = _ARROW_TEXTURES.get(key_hint, _ARROW_TEXTURES["up"])
		_arrow_sprite.modulate = Color(1, 1, 1, 0.35)
		_arrow_sprite.visible = true
	queue_redraw()

func hide_bubble() -> void:
	_phase = PHASE_IDLE
	_burst_timer = -1.0
	visible = false
	if _arrow_sprite != null:
		_arrow_sprite.visible = false

func burst_success() -> void:
	_phase = PHASE_IDLE
	_burst_fail = false
	_burst_timer = 0.12
	_burst_color = Color(1, 1, 1, 0.9)
	_burst_radius = RADIUS_TARGET * 0.8
	visible = true
	queue_redraw()

func set_frozen(value: bool) -> void:
	_frozen = value

## Estilhaço de erro: a bolha colapsa (encolhe e escurece) em vez de explodir.
func burst_fail() -> void:
	_phase = PHASE_IDLE
	_burst_fail = true
	_burst_timer = 0.12
	_burst_color = Color(0.2, 0.05, 0.05, 0.8)
	_burst_radius = RADIUS_TARGET * 0.8
	visible = true
	queue_redraw()
