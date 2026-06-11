class_name CampSpirit
extends Node2D

# Presença de um encantado libertado em repouso no acampamento (Santuário dos
# Encantados — PRD-santuario-dos-encantados §4.3). NÃO é mascote: é uma entidade
# antiga descansando — idle mais lento que o combate, respiração sutil, aura calma na
# cor canônica do boss e leitura abatida, para a Caipora seguir dona da tela (lei de
# marca). Montado por código (gotcha #7) e dirigido por DEFS (data-driven, uma entrada
# por encantado). O Jesuíta (P5) não é encantado: não tem entrada aqui.
#
# Contrato: add_child() ANTES de setup() — a aura e a respiração usam a árvore.

# ─── Constants ─────────────────────────────────────
# Repouso: leitura levemente abatida/fria (a dominância da Caipora vem dela estar no
# centro, iluminada — não de apagar os espíritos na mata escura) e idle lento.
const REST_MODULATE := Color(0.92, 0.92, 0.96)
const REST_SPEED: float = 0.6
# Respiração: pulso sutil de escala em loop — vivo, não estátua.
const BREATH_SCALE: float = 1.02
const BREATH_TIME: float = 1.6
# Aura calma: a sombra de combate virou cinza de pira — densidade/velocidade mínimas.
const AURA_AMOUNT: int = 6
const AURA_LIFETIME: float = 2.2
const AURA_RADIUS: float = 22.0
const AURA_RISE: float = -14.0
# Luz própria: poça baixa na cor da aura — o espírito LÊ na mata escura sem perder o
# repouso abatido (a leitura vem da luz, não de clarear o sprite).
const GLOW_ENERGY: float = 0.95
const GLOW_SCALE: float = 1.1
const GLOW_WHITEN: float = 0.5

# Identidade visual de cada espírito: os MESMOS frames premium da arena, em escala de
# set piece (2–4 tiles), com a cor de aura canônica da fase. `flip` vira o encantado
# para dentro da clareira (Mula ao norte olha pro fogo; Saci a sudeste olha pra oeste).
const DEFS := {
	1: { "frames": "res://assets/sprites/mula_sprite_frames.tres",
		"scale": 0.55, "flip": true, "aura": Constants.COLOR_AURA_MULA },
	2: { "frames": "res://assets/sprites/boitata_sprite_frames.tres",
		"scale": 0.7, "flip": true, "aura": Constants.COLOR_AURA_BOITATA },
	3: { "frames": "res://assets/sprites/curupira_sprite_frames.tres",
		"scale": 0.8, "flip": false, "aura": Constants.COLOR_AURA_CURUPIRA },
	4: { "frames": "res://assets/sprites/saci_sprite_frames.tres",
		"scale": 0.8, "flip": true, "aura": Constants.COLOR_AURA_SACI },
}

# ─── State ─────────────────────────────────────────
var phase: int = 0
var _sprite: AnimatedSprite2D

# ─── Public API ────────────────────────────────────
## Monta a presença do encantado da fase. Retorna false para fase sem espírito
## (Jesuíta/inválida) — o caller descarta o nó.
func setup(spirit_phase: int) -> bool:
	if not DEFS.has(spirit_phase):
		return false
	phase = spirit_phase
	var def: Dictionary = DEFS[spirit_phase]
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load(def["frames"])
	_sprite.animation = &"idle"
	_sprite.speed_scale = REST_SPEED
	_sprite.flip_h = def["flip"]
	_sprite.scale = Vector2(def["scale"], def["scale"])
	_sprite.modulate = REST_MODULATE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_sprite.play()
	_spawn_calm_aura(def["aura"])
	_spawn_glow(def["aura"])
	_start_breathing()
	return true

# ─── Private ───────────────────────────────────────
func _spawn_calm_aura(color: Color) -> void:
	var aura := CPUParticles2D.new()
	var vp := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2.ZERO
	aura.amount = maxi(2, int(AURA_AMOUNT * Constants.particle_amount_scale(vp)))
	aura.lifetime = AURA_LIFETIME
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	aura.emission_sphere_radius = AURA_RADIUS
	aura.gravity = Vector2(0, AURA_RISE)
	aura.initial_velocity_min = 2.0
	aura.initial_velocity_max = 6.0
	aura.scale_amount_min = 1.0
	aura.scale_amount_max = 2.0
	aura.color = color
	add_child(aura)

func _spawn_glow(color: Color) -> void:
	add_child(ForestLight.make(color.lerp(Color.WHITE, GLOW_WHITEN), GLOW_ENERGY, GLOW_SCALE))

func _start_breathing() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_sprite, "scale:y", _sprite.scale.y * BREATH_SCALE, BREATH_TIME) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "scale:y", _sprite.scale.y, BREATH_TIME) \
		.set_trans(Tween.TRANS_SINE)
