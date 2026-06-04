class_name WeaponVisual
extends Node2D

## Visual da erva de guerra `forca_3` ("Raiz-de-Ira"): a fumaça dela manifesta o Tronco
## Buster + aura de ouro dark + fumaça. Componente reutilizável: a mesma
## lógica é usada na exploração (Caipora) e na arena (ArenaManager), eliminando a
## duplicação que existia nos dois call-sites.
##
## CPUParticles2D obrigatório (export web em GL Compatibility, sem GPUParticles).
## Espelha o padrão de aura de Curupira._spawn_shadow_aura().

const WEAPON_TEXTURE := preload("res://assets/sprites/weapon_forca3.png")

## Offset do centro do sprite (64×112) relativo ao AnimatedSprite2D. Calibrado para
## o cabo encostar na mão da Caipora e a lâmina subir acima da cabeça.
const WEAPON_OFFSET := Vector2(22, -47)

## Anexa o tronco + partículas a `parent` (o AnimatedSprite2D da Caipora), se a erva
## "Raiz-de-Ira" (`forca_3`) estiver desbloqueada. No-op caso contrário.
static func attach_to(parent: Node2D) -> void:
	if MetaProgression.get_upgrade_level("forca_3") < 1:
		return

	var weapon := Sprite2D.new()
	weapon.name = "WeaponSprite"
	weapon.texture = WEAPON_TEXTURE
	weapon.position = WEAPON_OFFSET
	weapon.z_index = 1
	parent.add_child(weapon)

	# Fumaça atrás + aura dourada na frente, acompanhando o tronco.
	weapon.add_child(_build_smoke())
	weapon.add_child(_build_gold_aura())

	# Respiro dourado sutil: pulso lento no modulate (desejável, discreto).
	var pulse := weapon.create_tween().set_loops()
	pulse.tween_property(weapon, "modulate", Color(1.08, 1.05, 0.96), 1.6)
	pulse.tween_property(weapon, "modulate", Color(1.0, 1.0, 1.0), 1.6)


static func _build_smoke() -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.name = "Smoke"
	smoke.position = Vector2(0, -28)            # centrada sobre a lâmina
	smoke.z_index = -1                          # atrás do tronco
	smoke.amount = 14
	smoke.lifetime = 1.8
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(12, 44)
	smoke.direction = Vector2(0, -1)
	smoke.spread = 28.0
	smoke.gravity = Vector2(0, -18)             # sobe
	smoke.initial_velocity_min = 4.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 3.0
	smoke.scale_amount_max = 7.0
	smoke.color = Constants.COLOR_SMOKE_DARK
	smoke.color_ramp = _smoke_ramp()
	smoke.emitting = true
	return smoke


static func _build_gold_aura() -> CPUParticles2D:
	var aura := CPUParticles2D.new()
	aura.name = "GoldAura"
	aura.position = Vector2(0, -28)
	aura.z_index = 1                            # brilho na frente
	aura.amount = 20
	aura.lifetime = 1.4
	aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	aura.emission_rect_extents = Vector2(16, 46)
	aura.direction = Vector2(0, -1)
	aura.spread = 35.0
	aura.gravity = Vector2(0, -10)
	aura.initial_velocity_min = 6.0
	aura.initial_velocity_max = 16.0
	aura.scale_amount_min = 1.5
	aura.scale_amount_max = 3.5
	aura.color = Constants.COLOR_GOLD
	aura.color_ramp = _gold_ramp()
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	aura.material = glow
	aura.emitting = true
	return aura


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
