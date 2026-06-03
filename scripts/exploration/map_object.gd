class_name MapObject
extends Node2D

const ForestLight := preload("res://scripts/exploration/forest_light.gd")

enum Type { CHEST, KEY, FIRE, SPIKE, DEAD_TREE, BONES, MOSS, BLOOD_POOL, ROCK, FERN, VINE,
	MUSHROOM, STUMP, TOTEM, ROOTS, PUDDLE }

const T: int = Constants.TILE_SIZE  # 32

# Decorações puramente visuais (não-bloqueantes), renderizadas atrás das entidades.
const DECO_TYPES := [Type.DEAD_TREE, Type.BONES, Type.MOSS, Type.BLOOD_POOL, Type.ROCK, Type.FERN, Type.VINE,
	Type.MUSHROOM, Type.STUMP, Type.TOTEM, Type.ROOTS, Type.PUDDLE]

var _type: Type

# ─── Public API ────────────────────────────────────
## `enhanced` liga luz + partículas na fogueira (chama/brasas/fumaça). Só a Fase 1 usa
## (poucas fogueiras); Fases 2/3 têm dezenas de tiles de fogo e ficam no desenho estático
## por performance no export web.
func setup(type: Type, grid_pos: Vector2i, enhanced: bool = false) -> void:
	_type = type
	position = Vector2(grid_pos) * T
	if type in DECO_TYPES:
		z_index = -1  # ambientação fica embaixo de jogador/inimigos/baú
	if type == Type.FIRE and enhanced:
		_attach_fire_light()
		_attach_fire_particles()
	queue_redraw()

# Poça de luz quente da fogueira, com flicker irregular (chama viva).
func _attach_fire_light() -> void:
	var light := ForestLight.make(Constants.COLOR_FIRE_HOT, 1.0, 0.8)
	light.position = Vector2(T / 2.0, T / 2.0)
	add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy", 1.15, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.82, 0.13).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 1.05, 0.21).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", 0.9, 0.16).set_trans(Tween.TRANS_SINE)

# Chama viva + brasas (aditivo) + fumaça (mix). Tudo CPUParticles2D (web-safe).
func _attach_fire_particles() -> void:
	var base := Vector2(T / 2.0, T / 2.0 + 4.0)

	# Fumaça: cinza translúcido, lenta, sobe e dissipa (atrás da chama).
	var smoke := _make_particles(10, 1.8, base, Vector2(0, -18), 8.0, 20.0, 0.12, 0.25,
		_smoke_ramp(), false)
	smoke.texture = ForestLight.LIGHT_TEXTURE  # puff redondo e suave (não quadrado)
	smoke.spread = 22.0
	smoke.z_index = -1
	add_child(smoke)

	# Chama: gradiente quente, sobe rápido, blend aditivo.
	var flame := _make_particles(18, 0.6, base, Vector2(0, -45), 14.0, 34.0, 2.0, 4.0,
		_flame_ramp(), true)
	flame.spread = 16.0
	add_child(flame)

	# Brasas: poucas, rápidas, sobem alto (faísca da fogueira).
	var embers := _make_particles(8, 1.1, base, Vector2(0, -60), 20.0, 50.0, 1.0, 2.2,
		_ember_ramp(), true)
	embers.spread = 30.0
	embers.z_index = 1
	add_child(embers)

func _make_particles(amount: int, lifetime: float, pos: Vector2, gravity: Vector2,
		vmin: float, vmax: float, smin: float, smax: float, ramp: Gradient,
		additive: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.position = pos
	p.direction = Vector2(0, -1)
	p.gravity = gravity
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.color_ramp = ramp
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = mat
	return p

func _flame_ramp() -> Gradient:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Constants.COLOR_FIRE_HOT)
	grad.set_offset(1, 1.0); grad.set_color(1, Color(Constants.COLOR_FIRE_LOW.r, Constants.COLOR_FIRE_LOW.g, Constants.COLOR_FIRE_LOW.b, 0.0))
	grad.add_point(0.5, Constants.COLOR_FIRE_MID)
	return grad

func _ember_ramp() -> Gradient:
	var amber := Constants.COLOR_AMBER
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(1.0, 0.6, 0.2, 0.9))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(amber.r, amber.g, amber.b, 0.0))
	return grad

func _smoke_ramp() -> Gradient:
	var grad := Gradient.new()
	grad.set_offset(0, 0.0); grad.set_color(0, Color(0.15, 0.13, 0.14, 0.0))
	grad.set_offset(1, 1.0); grad.set_color(1, Color(0.10, 0.09, 0.10, 0.0))
	grad.add_point(0.35, Color(0.18, 0.16, 0.17, 0.35))
	return grad

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	var cx: float = T / 2.0
	var cy: float = T / 2.0
	match _type:
		Type.CHEST:      _draw_chest(cx, cy)
		Type.KEY:        _draw_key(cx, cy)
		Type.FIRE:       _draw_fire(cx, cy)
		Type.SPIKE:      _draw_spike(cx, cy)
		Type.DEAD_TREE:  _draw_dead_tree(cx, cy)
		Type.BONES:      _draw_bones(cx, cy)
		Type.MOSS:       _draw_moss(cx, cy)
		Type.BLOOD_POOL: _draw_blood_pool(cx, cy)
		Type.ROCK:       _draw_rock(cx, cy)
		Type.FERN:       _draw_fern(cx, cy)
		Type.VINE:       _draw_vine(cx, cy)
		Type.MUSHROOM:   _draw_mushroom(cx, cy)
		Type.STUMP:      _draw_stump(cx, cy)
		Type.TOTEM:      _draw_totem(cx, cy)
		Type.ROOTS:      _draw_roots(cx, cy)
		Type.PUDDLE:     _draw_puddle(cx, cy)

func _draw_fire(cx: float, cy: float) -> void:
	draw_circle(Vector2(cx, cy), 11.0, Constants.COLOR_FIRE_GLOW)
	var flames: Array = [
		[Vector2(cx - 7, cy + 7), Vector2(cx - 1, cy - 10), Vector2(cx + 5, cy + 7)],
		[Vector2(cx - 4, cy + 7), Vector2(cx - 2, cy - 5), Vector2(cx + 2, cy + 7)],
		[Vector2(cx + 2, cy + 7), Vector2(cx + 5, cy - 8), Vector2(cx + 9, cy + 7)],
	]
	var fire_colors: Array = [
		Constants.COLOR_FIRE_MID,
		Constants.COLOR_FIRE_HOT,
		Constants.COLOR_FIRE_LOW,
	]
	for i: int in 3:
		draw_colored_polygon(PackedVector2Array(flames[i]), fire_colors[i])

func _draw_spike(cx: float, cy: float) -> void:
	draw_rect(Rect2(cx - 12, cy + 4, 24, 4), Constants.COLOR_STONE_DARK)
	var spike_color := Constants.COLOR_STONE
	for i: int in 4:
		var bx: float = cx - 9.0 + i * 6.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 3, cy + 8),
			Vector2(bx,     cy - 8),
			Vector2(bx + 3, cy + 8),
		]), spike_color)

func _draw_key(cx: float, cy: float) -> void:
	var gold := Constants.COLOR_GOLD
	var dark_gold := Constants.COLOR_GOLD_DARK
	draw_circle(Vector2(cx - 4, cy - 3), 6.5, gold)
	draw_circle(Vector2(cx - 4, cy - 3), 3.5, dark_gold)
	draw_rect(Rect2(cx - 4, cy - 4, 13, 3), gold)
	draw_rect(Rect2(cx + 4, cy - 1, 3, 3), gold)
	draw_rect(Rect2(cx + 8, cy - 1, 2, 2), gold)

func _draw_chest(cx: float, cy: float) -> void:
	var wood      := Constants.COLOR_WOOD
	var dark_wood := Constants.COLOR_WOOD_DARK
	var metal     := Constants.COLOR_METAL
	var penta     := Constants.COLOR_PENTAGRAM

	draw_rect(Rect2(cx - 13, cy - 1,  26, 12), dark_wood)
	draw_rect(Rect2(cx - 12, cy,       24, 10), wood)
	draw_rect(Rect2(cx - 13, cy - 11, 26,  10), dark_wood)
	draw_rect(Rect2(cx - 12, cy - 10, 24,  8), wood)
	draw_rect(Rect2(cx - 13, cy - 1,  26,  2), metal)
	draw_rect(Rect2(cx - 3,  cy - 4,   6,  4), metal)
	draw_circle(Vector2(cx, cy - 2), 2.0, dark_wood)

	_draw_inverted_pentagram(Vector2(cx, cy - 6), 4.5, penta)

func _draw_inverted_pentagram(center: Vector2, radius: float, color: Color) -> void:
	var inner_r: float = radius * 0.382
	var pts: PackedVector2Array = []
	for i: int in 10:
		var angle: float = PI / 2.0 + i * PI / 5.0
		var r: float = radius if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

# ─── Decorações (ambientação folk-horror, não-bloqueantes) ──
func _draw_dead_tree(cx: float, cy: float) -> void:
	var bark      := Constants.COLOR_BARK
	var bark_dark := Constants.COLOR_BARK_DARK
	# tronco
	draw_rect(Rect2(cx - 2.5, cy - 4, 5, 16), bark_dark)
	draw_rect(Rect2(cx - 1.5, cy - 4, 3, 16), bark)
	# galhos secos retorcidos
	var branches: Array = [
		[Vector2(cx, cy - 2),  Vector2(cx - 9, cy - 9)],
		[Vector2(cx, cy - 4),  Vector2(cx + 8, cy - 11)],
		[Vector2(cx, cy - 1),  Vector2(cx + 6, cy - 3)],
		[Vector2(cx, cy - 6),  Vector2(cx - 5, cy - 13)],
	]
	for b: Array in branches:
		draw_line(b[0], b[1], bark, 2.0)

func _draw_bones(cx: float, cy: float) -> void:
	var bone := Constants.COLOR_BONE
	var hollow := Constants.COLOR_BONE_HOLLOW
	# crânio
	draw_circle(Vector2(cx - 3, cy - 1), 5.0, bone)
	draw_circle(Vector2(cx - 5, cy - 2), 1.3, hollow)
	draw_circle(Vector2(cx - 1, cy - 2), 1.3, hollow)
	draw_rect(Rect2(cx - 4, cy + 2, 3, 2), bone)
	# ossos cruzados
	draw_line(Vector2(cx + 1, cy + 5), Vector2(cx + 10, cy - 2), bone, 2.0)
	draw_line(Vector2(cx + 1, cy - 2), Vector2(cx + 10, cy + 5), bone, 2.0)

func _draw_moss(cx: float, cy: float) -> void:
	var moss      := Constants.COLOR_MOSS_DECO
	var moss_dark := Constants.COLOR_MOSS_DECO_DARK
	var blobs: Array = [
		[Vector2(cx - 6, cy + 4), 6.0], [Vector2(cx + 5, cy + 6), 5.0],
		[Vector2(cx + 7, cy - 4), 4.0], [Vector2(cx - 4, cy - 5), 4.5],
		[Vector2(cx + 1, cy + 1), 5.5],
	]
	for b: Array in blobs:
		draw_circle(b[0], b[1], moss)
	draw_circle(Vector2(cx - 5, cy + 5), 2.5, moss_dark)
	draw_circle(Vector2(cx + 6, cy - 3), 2.0, moss_dark)

func _draw_blood_pool(cx: float, cy: float) -> void:
	var blood      := Constants.COLOR_BLOOD_POOL
	var blood_dark := Constants.COLOR_BLOOD_POOL_DARK
	var pool: PackedVector2Array = [
		Vector2(cx - 9, cy + 1), Vector2(cx - 5, cy - 5), Vector2(cx + 2, cy - 6),
		Vector2(cx + 8, cy - 2), Vector2(cx + 9, cy + 4), Vector2(cx + 3, cy + 8),
		Vector2(cx - 4, cy + 7), Vector2(cx - 10, cy + 5),
	]
	draw_colored_polygon(pool, blood)
	draw_circle(Vector2(cx + 1, cy + 1), 3.5, blood_dark)
	# respingos
	draw_circle(Vector2(cx + 11, cy - 6), 1.5, blood)
	draw_circle(Vector2(cx - 12, cy - 3), 1.2, blood)

func _draw_rock(cx: float, cy: float) -> void:
	var stone      := Constants.COLOR_STONE
	var stone_dark := Constants.COLOR_STONE_DARK
	var rock: PackedVector2Array = [
		Vector2(cx - 8, cy + 6), Vector2(cx - 6, cy - 3), Vector2(cx, cy - 7),
		Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6),
	]
	draw_colored_polygon(rock, stone)
	var shade: PackedVector2Array = [
		Vector2(cx, cy - 7), Vector2(cx + 7, cy - 2), Vector2(cx + 8, cy + 6), Vector2(cx + 2, cy + 2),
	]
	draw_colored_polygon(shade, stone_dark)

func _draw_fern(cx: float, cy: float) -> void:
	# Samambaia amazônica: leque de frondes saindo da base.
	var frond := Constants.COLOR_MOSS_DECO
	var frond_dark := Constants.COLOR_MOSS_DECO_DARK
	var base := Vector2(cx, cy + 9)
	var angles: Array = [-1.15, -0.7, -0.25, 0.25, 0.7, 1.15]
	for a: float in angles:
		var tip := base + Vector2(sin(a), -cos(a)) * 13.0
		draw_line(base, tip, frond_dark, 2.0)
		# folíolos ao longo da fronde
		var dir := (tip - base).normalized()
		var perp := Vector2(-dir.y, dir.x)
		for s: float in [0.4, 0.65, 0.9]:
			var p := base.lerp(tip, s)
			draw_line(p, p + perp * 2.5, frond, 1.0)
			draw_line(p, p - perp * 2.5, frond, 1.0)

func _draw_vine(cx: float, cy: float) -> void:
	# Cipó pendente: trança que desce do topo do tile com folhas esparsas.
	var vine := Constants.COLOR_MOSS_DECO_DARK
	var leaf := Constants.COLOR_MOSS_DECO
	var prev := Vector2(cx - 6, cy - 14)
	for i: int in range(1, 9):
		var t := i / 8.0
		var nxt := Vector2(cx - 6 + sin(t * 6.0) * 4.0, cy - 14 + t * 26.0)
		draw_line(prev, nxt, vine, 2.0)
		if i % 2 == 0:
			draw_circle(nxt + Vector2(3, 0), 2.2, leaf)
		prev = nxt

func _draw_mushroom(cx: float, cy: float) -> void:
	# Trio de cogumelos pálidos com leve bioluminescência (encantado/doentio).
	var cap := Constants.COLOR_MUSHROOM
	var glow := Constants.COLOR_MUSHROOM_GLOW
	var stalk := Constants.COLOR_BONE_HOLLOW
	var caps: Array = [
		[Vector2(cx - 5, cy + 3), 4.5], [Vector2(cx + 4, cy + 5), 3.5], [Vector2(cx, cy - 2), 5.5],
	]
	for c: Array in caps:
		var p: Vector2 = c[0]
		var r: float = c[1]
		# pé
		draw_rect(Rect2(p.x - 1, p.y, 2, r * 0.9), stalk)
		# chapéu
		draw_circle(p, r, cap)
		# pintas brilhantes
		draw_circle(p + Vector2(-1.5, -1.0), 0.9, glow)
		draw_circle(p + Vector2(1.6, 0.2), 0.7, glow)

func _draw_stump(cx: float, cy: float) -> void:
	# Toco cortado: anéis de crescimento concêntricos.
	var wood := Constants.COLOR_WOOD
	var wood_dark := Constants.COLOR_WOOD_DARK
	var bark := Constants.COLOR_BARK
	draw_circle(Vector2(cx, cy + 2), 9.0, bark)
	draw_circle(Vector2(cx, cy + 2), 8.0, wood)
	draw_arc(Vector2(cx, cy + 2), 6.0, 0, TAU, 16, wood_dark, 1.0)
	draw_arc(Vector2(cx, cy + 2), 3.5, 0, TAU, 12, wood_dark, 1.0)
	draw_circle(Vector2(cx, cy + 2), 1.2, wood_dark)

func _draw_totem(cx: float, cy: float) -> void:
	# Totem entalhado folk-horror: poste com rosto e marcas de sangue.
	var wood := Constants.COLOR_WOOD
	var wood_dark := Constants.COLOR_WOOD_DARK
	var blood := Constants.COLOR_BLOOD
	draw_rect(Rect2(cx - 5, cy - 12, 10, 26), wood_dark)
	draw_rect(Rect2(cx - 4, cy - 11, 8, 24), wood)
	# olhos ocos
	draw_circle(Vector2(cx - 2, cy - 6), 1.6, wood_dark)
	draw_circle(Vector2(cx + 2, cy - 6), 1.6, wood_dark)
	# boca rasgada
	draw_rect(Rect2(cx - 3, cy - 1, 6, 2), wood_dark)
	# marcas rituais de sangue
	draw_line(Vector2(cx - 3, cy + 4), Vector2(cx + 3, cy + 6), blood, 1.0)
	draw_line(Vector2(cx + 3, cy + 4), Vector2(cx - 3, cy + 6), blood, 1.0)

func _draw_roots(cx: float, cy: float) -> void:
	# Raízes rastejantes pelo chão (textura orgânica, não-bloqueante).
	var bark := Constants.COLOR_BARK
	var bark_dark := Constants.COLOR_BARK_DARK
	var roots: Array = [
		[Vector2(cx - 12, cy - 6), Vector2(cx, cy)], [Vector2(cx, cy), Vector2(cx + 11, cy + 5)],
		[Vector2(cx, cy), Vector2(cx + 9, cy - 7)], [Vector2(cx, cy), Vector2(cx - 8, cy + 8)],
	]
	for r: Array in roots:
		draw_line(r[0], r[1], bark_dark, 3.0)
		draw_line(r[0], r[1], bark, 1.5)

func _draw_puddle(cx: float, cy: float) -> void:
	# Poça d'água escura refletindo a noite (leve brilho da superfície).
	var water := Constants.COLOR_WATER
	var water_light := Constants.COLOR_WATER_LIGHT
	var pool: PackedVector2Array = [
		Vector2(cx - 10, cy + 2), Vector2(cx - 5, cy - 4), Vector2(cx + 3, cy - 5),
		Vector2(cx + 10, cy - 1), Vector2(cx + 8, cy + 5), Vector2(cx, cy + 7), Vector2(cx - 7, cy + 6),
	]
	draw_colored_polygon(pool, water)
	# reflexos na superfície
	draw_line(Vector2(cx - 4, cy + 1), Vector2(cx + 2, cy), water_light, 1.0)
	draw_line(Vector2(cx + 1, cy + 3), Vector2(cx + 6, cy + 2), water_light, 1.0)
