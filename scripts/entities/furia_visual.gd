class_name WeaponVisual
extends Node2D

## Visual evolutivo da arma da Caipora por tier de Fúria (forca_1..forca_6).
## Cada tier desbloqueia um sprite mais imponente + partículas escalonadas.
## Componente reutilizável: usado na exploração (Caipora) e na arena (ArenaManager).
##
## CPUParticles2D obrigatório (export web em GL Compatibility, sem GPUParticles).

const WEAPON_OFFSET := Vector2(33, -70.5)

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/weapon_forca1.png"),   # T1
	preload("res://assets/sprites/weapon_forca2.png"),   # T2
	preload("res://assets/sprites/weapon_forca3.png"),   # T3
	preload("res://assets/sprites/weapon_forca4.png"),   # T4
	preload("res://assets/sprites/weapon_forca5.png"),   # T5
	preload("res://assets/sprites/weapon_forca6.png"),   # T6
]

const TEXTURES_FIRE: Array[Texture2D] = [
	preload("res://assets/sprites/weapon_forca1_fogo.png"),
	preload("res://assets/sprites/weapon_forca2_fogo.png"),
	preload("res://assets/sprites/weapon_forca3_fogo.png"),
	preload("res://assets/sprites/weapon_forca4_fogo.png"),
	preload("res://assets/sprites/weapon_forca5_fogo.png"),
	preload("res://assets/sprites/weapon_forca6_fogo.png"),
]

## Retorna o tier máximo de Fúria desbloqueado (1–6), ou 0 se nenhum.
static func _max_furia_tier() -> int:
	var tier := 0
	for i in range(MetaProgression.FURIA_KEYS.size()):
		if MetaProgression.get_upgrade_level(MetaProgression.FURIA_KEYS[i]) >= 1:
			tier = i + 1
	return tier

## Anexa o sprite de arma + partículas escalonadas ao `parent` (AnimatedSprite2D).
## No-op se nenhum tier de Fúria estiver desbloqueado.
static func attach_to(parent: Node2D) -> void:
	var tier := _max_furia_tier()
	if tier < 1:
		return

	var on_fire := MetaProgression.has_chama
	var textures: Array[Texture2D] = TEXTURES_FIRE if on_fire else TEXTURES
	var weapon := Sprite2D.new()
	weapon.name = "WeaponSprite"
	weapon.texture = textures[tier - 1]
	weapon.position = WEAPON_OFFSET
	weapon.z_index = 1
	parent.add_child(weapon)

	# Partículas escalonadas por tier
	if tier >= 2:
		weapon.add_child(_build_smoke(tier))
	if tier >= 3:
		weapon.add_child(_build_gold_aura(tier))
	if tier >= 4:
		weapon.add_child(_build_residue(tier))
	if tier >= 5:
		weapon.add_child(_build_bone_fragments(tier))
	if tier >= 6:
		weapon.add_child(_build_flesh_spines(tier))

	# CHAMA: chama viva somada às partículas do tier
	if on_fire:
		weapon.add_child(_build_flame(tier))

	# Respiro sutil: pulso lento no modulate
	var pulse := weapon.create_tween().set_loops()
	var peak := Color(1.08, 1.05, 0.96) if tier < 6 else Color(1.12, 1.0, 0.95)
	pulse.tween_property(weapon, "modulate", peak, 1.6)
	pulse.tween_property(weapon, "modulate", Color(1.0, 1.0, 1.0), 1.6)


# ─── Partículas escalonadas ──────────────────────────────────────────────────

static func _build_smoke(tier: int) -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.name = "Smoke"
	smoke.position = Vector2(0, -28)
	smoke.z_index = -1
	smoke.amount = 8 + tier * 2          # T2=12, T3=14, … T6=20
	smoke.lifetime = 1.4 + tier * 0.1
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(10 + tier, 38 + tier * 2)
	smoke.direction = Vector2(0, -1)
	smoke.spread = 20.0 + tier * 3.0
	smoke.gravity = Vector2(0, -14 - tier * 2)
	smoke.initial_velocity_min = 3.0
	smoke.initial_velocity_max = 8.0 + tier * 2.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 5.0 + tier * 0.8
	smoke.color = Constants.COLOR_SMOKE_DARK
	smoke.color_ramp = _smoke_ramp()
	smoke.emitting = true
	return smoke


static func _build_gold_aura(tier: int) -> CPUParticles2D:
	var aura := CPUParticles2D.new()
	aura.name = "GoldAura"
	aura.position = Vector2(0, -28)
	aura.z_index = 1
	aura.amount = 12 + tier * 3          # T3=21, T4=24, … T6=30
	aura.lifetime = 1.2 + tier * 0.05
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	aura.emission_rect_extents = Vector2(12 + tier * 2, 40 + tier * 3)
	aura.direction = Vector2(0, -1)
	aura.spread = 30.0 + tier * 2.5
	aura.gravity = Vector2(0, -8 - tier)
	aura.initial_velocity_min = 5.0
	aura.initial_velocity_max = 12.0 + tier * 2.0
	aura.scale_amount_min = 1.2
	aura.scale_amount_max = 2.8 + tier * 0.5
	aura.color = Constants.COLOR_GOLD
	aura.color_ramp = _gold_ramp()
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	aura.material = glow
	aura.emitting = true
	return aura


## Resíduos de breu/resina (T4+): partículas escuras que caem lentamente.
static func _build_residue(tier: int) -> CPUParticles2D:
	var res := CPUParticles2D.new()
	res.name = "BreuResidue"
	res.position = Vector2(0, -20)
	res.z_index = -1
	res.amount = 6 + (tier - 3) * 3
	res.lifetime = 1.6
	res.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	res.emission_rect_extents = Vector2(14, 36)
	res.direction = Vector2(0, 1)
	res.spread = 45.0
	res.gravity = Vector2(0, 25)
	res.initial_velocity_min = 2.0
	res.initial_velocity_max = 8.0
	res.scale_amount_min = 1.5
	res.scale_amount_max = 3.5
	res.color = Color(0.18, 0.14, 0.08, 0.55)
	var fade := Gradient.new()
	fade.set_offset(0, 0.0)
	fade.set_color(0, Color(0.18, 0.14, 0.08, 0.55))
	fade.add_point(1.0, Color(0.18, 0.14, 0.08, 0.0))
	res.color_ramp = fade
	res.emitting = true
	return res


## Fragmentos de osso/sangue seco (T5+): partículas pálidas/vermelhas.
static func _build_bone_fragments(tier: int) -> CPUParticles2D:
	var frag := CPUParticles2D.new()
	frag.name = "BoneFragments"
	frag.position = Vector2(0, -24)
	frag.z_index = 1
	frag.amount = 8 + (tier - 4) * 4
	frag.lifetime = 1.0
	frag.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	frag.emission_rect_extents = Vector2(16, 42)
	frag.direction = Vector2(0, -1)
	frag.spread = 55.0
	frag.gravity = Vector2(0, -20)
	frag.initial_velocity_min = 6.0
	frag.initial_velocity_max = 18.0
	frag.scale_amount_min = 1.0
	frag.scale_amount_max = 2.5
	frag.color = Color(0.75, 0.55, 0.45, 0.7)
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.85, 0.65, 0.55, 0.75))
	ramp.add_point(0.5, Color(0.55, 0.25, 0.18, 0.5))
	ramp.add_point(1.0, Color(0.35, 0.12, 0.08, 0.0))
	frag.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	frag.material = glow
	frag.emitting = true
	return frag


## Espinhos de carne viva (T6): partículas carmim escuras, pulsantes.
static func _build_flesh_spines(tier: int) -> CPUParticles2D:
	var sp := CPUParticles2D.new()
	sp.name = "FleshSpines"
	sp.position = Vector2(0, -28)
	sp.z_index = 2
	sp.amount = 14
	sp.lifetime = 0.9
	sp.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sp.emission_rect_extents = Vector2(18, 48)
	sp.direction = Vector2(0, -1)
	sp.spread = 25.0
	sp.gravity = Vector2(0, -35)
	sp.initial_velocity_min = 10.0
	sp.initial_velocity_max = 28.0
	sp.scale_amount_min = 1.5
	sp.scale_amount_max = 3.5
	sp.color = Color(0.72, 0.18, 0.18, 0.8)
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.92, 0.22, 0.22, 0.85))
	ramp.add_point(0.4, Color(0.68, 0.15, 0.15, 0.6))
	ramp.add_point(1.0, Color(0.25, 0.05, 0.05, 0.0))
	sp.color_ramp = ramp
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = glow
	sp.emitting = true
	return sp


## Chama viva da CHAMA (elemento fogo): sobe rápido, blend aditivo, gradiente quente.
## Escalona com o tier: quanto maior o tier, mais intensa a chama.
static func _build_flame(tier: int) -> CPUParticles2D:
	var flame := CPUParticles2D.new()
	flame.name = "ChamaFlame"
	flame.position = Vector2(0, -28)
	flame.z_index = 1
	flame.amount = 16 + tier * 3       # T1=19, … T6=34
	flame.lifetime = 0.6 + tier * 0.03
	flame.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flame.emission_rect_extents = Vector2(10 + tier * 2, 38 + tier * 3)
	flame.direction = Vector2(0, -1)
	flame.spread = 15.0 + tier * 2.0
	flame.gravity = Vector2(0, -40 - tier * 4)
	flame.initial_velocity_min = 12.0
	flame.initial_velocity_max = 28.0 + tier * 3.0
	flame.scale_amount_min = 1.8
	flame.scale_amount_max = 3.5 + tier * 0.4
	flame.color = Constants.COLOR_FIRE_HOT
	flame.color_ramp = _flame_ramp()
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flame.material = glow
	flame.emitting = true
	return flame


# ─── Ramps ───────────────────────────────────────────────────────────────────

static func _flame_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Constants.COLOR_FIRE_HOT)
	g.add_point(0.5, Constants.COLOR_FIRE_MID)
	g.add_point(1.0, Color(Constants.COLOR_FIRE_LOW.r, Constants.COLOR_FIRE_LOW.g, Constants.COLOR_FIRE_LOW.b, 0.0))
	return g


static func _smoke_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(Constants.COLOR_SMOKE_DARK.r, Constants.COLOR_SMOKE_DARK.g, Constants.COLOR_SMOKE_DARK.b, 0.42))
	g.add_point(1.0, Color(Constants.COLOR_SMOKE_DARK.r, Constants.COLOR_SMOKE_DARK.g, Constants.COLOR_SMOKE_DARK.b, 0.0))
	return g


static func _gold_ramp() -> Gradient:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Constants.COLOR_GOLD)
	g.add_point(0.55, Constants.COLOR_GOLD_DARK)
	g.add_point(1.0, Constants.COLOR_AURA_BUSTER_DARK)
	return g
