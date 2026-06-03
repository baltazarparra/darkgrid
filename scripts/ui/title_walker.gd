class_name TitleWalker
extends Node2D

## A Caipora atravessando a tela na abertura, em loop ("atravessa e reaparece",
## sempre no mesmo sentido). Sprite normal (não silhueta), com sombra no chão e um
## leve bob vertical para dar peso/vida. Reusa caipora_sprite_frames.tres (anim
## "walk"). Puramente decorativo — sem física, colisão ou input.

# ─── Exports ───────────────────────────────────────
@export var ground_path: NodePath
@export var foot_y: float = 600.0
@export var layer_z: int = -40

# ─── Constants ─────────────────────────────────────
const FRAMES_PATH: String = "res://assets/sprites/caipora_sprite_frames.tres"
const SPRITE_HALF: float = 32.0  # Caipora é 64×64 (assets/AGENTS.md)
const WALK_SCALE: float = 2.6
const START_X: float = -120.0
const CROSS_DURATION: float = 22.0
const BOB_AMPLITUDE: float = 4.0
const BOB_SPEED: float = 3.4
const WALK_ANIM_SPEED: float = 0.45
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

# ─── State ─────────────────────────────────────────
var _end_x: float = 1400.0
var _sprite: AnimatedSprite2D
var _rest_y: float = 0.0
var _bob_t: float = 0.0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	_end_x = vp.x + abs(START_X)
	z_index = layer_z
	if not ground_path.is_empty():
		var g := get_node_or_null(ground_path)
		if g != null and "crest_y" in g:
			foot_y = g.crest_y
	var eff_foot_y: float = foot_y / 720.0 * vp.y
	position = Vector2(START_X, eff_foot_y)

	_rest_y = -SPRITE_HALF * WALK_SCALE
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(FRAMES_PATH)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(WALK_SCALE, WALK_SCALE)
	_sprite.flip_h = false  # andando para a direita
	_sprite.position = Vector2(0, _rest_y)  # pés na origem (sobre a crista)
	_sprite.speed_scale = WALK_ANIM_SPEED
	_sprite.play("walk")
	add_child(_sprite)

	_start_loop()

func _process(delta: float) -> void:
	_bob_t += delta * BOB_SPEED
	_sprite.position.y = _rest_y + sin(_bob_t) * BOB_AMPLITUDE
	queue_redraw()

# ─── Drawing (sombra) ──────────────────────────────
func _draw() -> void:
	# Elipse achatada sob os pés (origem local). Escala vertical = "esmagamento".
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, SPRITE_HALF * WALK_SCALE * 0.55, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ─── Private helpers ───────────────────────────────
func _start_loop() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:x", _end_x, CROSS_DURATION).from(START_X)
