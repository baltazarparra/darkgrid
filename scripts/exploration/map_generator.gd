class_name MapGenerator
extends RefCounted

# Gerador procedural PURO e determinístico. generate(config, seed) sempre devolve
# o MESMO GeneratedMap para o mesmo par (config, seed) — requisito do loop run→arena→
# exploração, onde o mapa não pode ser re-sorteado na volta do combate.
#
# Pipeline em camadas (best-practice de mercado: Spelunky/Brogue/Caves of Qud não
# usam UMA técnica, encadeiam várias):
#   1. TOPOLOGIA   — OPEN: região aberta;  CORRIDOR: drunkard's walk
#   2. SALA DO BOSS — (OPEN) alcova com a saída dentro e porta única
#   3. VALIDAÇÃO    — flood-fill: saída alcançável do spawn? senão regenera
#   4. HAZARDS      — R/S espalhados (são caminháveis → não afetam conectividade)
#   5. ENTIDADES    — inimigos por rejection sampling (espaçados, longe do spawn,
#                     boss guardando a saída/porta), baú e chave
#
# Sem dependência de SceneTree → roda nos testes GUT em headless.

const MAX_ATTEMPTS := 12
const PILLAR_MIN_SPACING := 2
const BOSS_ROOM_W := 7
const BOSS_ROOM_H := 4
const CORRIDOR_TURN_CHANCE := 0.28
const CORRIDOR_MAX_STEPS := 4000
const CARDINALS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# ─── Public API ────────────────────────────────────
func generate(config: MapConfig, p_seed: int) -> GeneratedMap:
	for attempt: int in MAX_ATTEMPTS:
		var rng := RandomNumberGenerator.new()
		rng.seed = _mix(p_seed, attempt)
		# Última tentativa abre mão dos pilares — garante conectividade no OPEN.
		var drop_pillars := attempt == MAX_ATTEMPTS - 1
		var m := _attempt(config, rng, drop_pillars)
		if m != null:
			m.map_seed = p_seed
			return m
	# Inalcançável na prática (a última tentativa sem pilares sempre valida),
	# mas o contrato é nunca retornar null.
	return _attempt(config, RandomNumberGenerator.new(), true)

# ─── Geração (uma tentativa) ───────────────────────
func _attempt(config: MapConfig, rng: RandomNumberGenerator, drop_pillars: bool) -> GeneratedMap:
	var w := config.grid_width
	var h := config.grid_height
	var tiles := _blank(w, h, GeneratedMap.FLOOR)
	_frame_walls(tiles, w, h)

	var player_start := Vector2i(1, 1)
	var exit_pos := Vector2i(-1, -1)
	var boss_cell := Vector2i(-1, -1)
	var in_boss_room: Callable = func(_p: Vector2i) -> bool: return false

	if config.topology_mode == MapConfig.TopologyMode.OPEN:
		var room := _carve_boss_room(tiles, w, h)
		exit_pos = room["exit"]
		boss_cell = room["boss_cell"]
		var room_rect: Rect2i = room["rect"]
		in_boss_room = func(p: Vector2i) -> bool: return room_rect.has_point(p)
		if not drop_pillars:
			var door_cell: Vector2i = room["door"]
			var protect: Array[Vector2i] = [player_start, exit_pos, boss_cell, door_cell]
			_scatter_pillars(tiles, config, rng, protect, room_rect)
	else:
		_fill_interior(tiles, w, h, GeneratedMap.WALL)
		_drunkard_walk(tiles, config, rng, player_start, w, h)

	_set_tile(tiles, player_start, GeneratedMap.FLOOR)

	var m := GeneratedMap.new()
	m.width = w
	m.height = h
	m.tiles = tiles
	m.player_start = player_start

	var dist := m.reachable_from(player_start)

	if config.topology_mode == MapConfig.TopologyMode.CORRIDOR:
		exit_pos = _farthest(dist)
		boss_cell = _near_exit_cell(dist, exit_pos)

	# Validação: saída precisa ser alcançável. Senão, esta tentativa falhou.
	if exit_pos == Vector2i(-1, -1) or not dist.has(exit_pos):
		return null

	_set_tile(tiles, exit_pos, GeneratedMap.EXIT)
	m.exit_pos = exit_pos

	# Pool de chão alcançável (exclui a própria saída).
	var pool: Array[Vector2i] = []
	for p: Vector2i in dist.keys():
		if p != exit_pos:
			pool.append(p)

	var protected: Array[Vector2i] = [player_start, exit_pos, boss_cell]
	var hset := _place_hazards(tiles, config, rng, pool, protected)

	# Pool de posicionamento de entidades: chão alcançável sem spawn nem hazards.
	var place_pool: Array[Vector2i] = []
	for p: Vector2i in pool:
		if p == player_start or hset.has(p):
			continue
		place_pool.append(p)

	m.enemies = _place_enemies(config, rng, dist, place_pool, boss_cell, in_boss_room)

	var taken := {player_start: true, exit_pos: true}
	for e: Dictionary in m.enemies:
		taken[Vector2i(e["x"], e["y"])] = true
	if config.has_chest:
		m.chest_pos = _pick_free(rng, place_pool, taken)
	if config.has_key:
		m.key_pos = _pick_free(rng, place_pool, taken)

	return m

# ─── Topologia: OPEN ───────────────────────────────
func _carve_boss_room(tiles: Array, w: int, h: int) -> Dictionary:
	# Alcova retangular no canto inferior-direito, cercada por parede com porta
	# única no topo. Saída no canto interno; boss postado logo dentro da porta.
	var bw := mini(BOSS_ROOM_W, w - 4)
	var bh := mini(BOSS_ROOM_H, h - 4)
	var right := w - 2
	var bottom := h - 2
	var left := right - bw + 1
	var top := bottom - bh + 1
	# Parede em L que, com as bordas direita/inferior, fecha a sala.
	for x: int in range(left - 1, right + 1):
		tiles[top - 1][x] = GeneratedMap.WALL
	for y: int in range(top - 1, bottom + 1):
		tiles[y][left - 1] = GeneratedMap.WALL
	# Interior da sala em chão.
	for y: int in range(top, bottom + 1):
		for x: int in range(left, right + 1):
			tiles[y][x] = GeneratedMap.FLOOR
	# Porta única na parede de cima.
	var door := Vector2i(left + int(bw / 2.0), top - 1)
	tiles[door.y][door.x] = GeneratedMap.FLOOR
	return {
		"exit": Vector2i(right, bottom),
		"boss_cell": Vector2i(door.x, top),  # dentro, guardando a porta
		"door": door,
		"rect": Rect2i(left, top, bw, bh),
	}

func _scatter_pillars(tiles: Array, config: MapConfig, rng: RandomNumberGenerator,
		protect: Array[Vector2i], room_rect: Rect2i) -> void:
	var w: int = tiles[0].size()
	var h: int = tiles.size()
	var cands: Array[Vector2i] = []
	for y: int in range(1, h - 1):
		for x: int in range(1, w - 1):
			var p := Vector2i(x, y)
			if tiles[y][x] != GeneratedMap.FLOOR:
				continue
			if room_rect.has_point(p):
				continue
			if _near_any(p, protect, 1):
				continue
			cands.append(p)
	_shuffle(cands, rng)
	var target := int(cands.size() * config.pillar_density)
	var placed: Array[Vector2i] = []
	for p: Vector2i in cands:
		if placed.size() >= target:
			break
		if _near_any(p, placed, PILLAR_MIN_SPACING - 1):
			continue
		tiles[p.y][p.x] = GeneratedMap.WALL
		placed.append(p)

# ─── Topologia: CORRIDOR ───────────────────────────
func _drunkard_walk(tiles: Array, config: MapConfig, rng: RandomNumberGenerator,
		start: Vector2i, w: int, h: int) -> void:
	# Caminhada aleatória que escava chão — conectividade garantida por construção.
	var width := maxi(1, config.corridor_width)
	var interior := (w - 2) * (h - 2)
	var target := int(interior * config.corridor_openness)
	var carved := {}
	var pos := start
	_carve_block(tiles, pos, width, w, h, carved)
	var dir: Vector2i = CARDINALS[rng.randi_range(0, 3)]
	var steps := 0
	while carved.size() < target and steps < CORRIDOR_MAX_STEPS:
		if rng.randf() < CORRIDOR_TURN_CHANCE:
			dir = CARDINALS[rng.randi_range(0, 3)]
		var np := pos + dir
		if np.x < 1 or np.x > w - 1 - width or np.y < 1 or np.y > h - 1 - width:
			dir = CARDINALS[rng.randi_range(0, 3)]
			steps += 1
			continue
		pos = np
		_carve_block(tiles, pos, width, w, h, carved)
		steps += 1

func _carve_block(tiles: Array, origin: Vector2i, width: int, w: int, h: int,
		carved: Dictionary) -> void:
	for dy: int in width:
		for dx: int in width:
			var c := origin + Vector2i(dx, dy)
			if c.x >= 1 and c.x <= w - 2 and c.y >= 1 and c.y <= h - 2:
				tiles[c.y][c.x] = GeneratedMap.FLOOR
				carved[c] = true

# ─── Hazards ───────────────────────────────────────
func _place_hazards(tiles: Array, config: MapConfig, rng: RandomNumberGenerator,
		pool: Array[Vector2i], protect: Array[Vector2i]) -> Dictionary:
	var hset := {}
	if config.hazard_chars.is_empty() or config.hazard_density <= 0.0:
		return hset
	var cands: Array[Vector2i] = []
	for p: Vector2i in pool:
		if p in protect:
			continue
		cands.append(p)
	_shuffle(cands, rng)
	var target := int(cands.size() * config.hazard_density)
	var i := 0
	for p: Vector2i in cands:
		if i >= target:
			break
		var ch: String = config.hazard_chars[rng.randi_range(0, config.hazard_chars.size() - 1)]
		tiles[p.y][p.x] = ch
		hset[p] = true
		i += 1
	return hset

# ─── Entidades ─────────────────────────────────────
func _place_enemies(config: MapConfig, rng: RandomNumberGenerator, dist: Dictionary,
		pool: Array[Vector2i], boss_cell: Vector2i, in_boss_room: Callable) -> Array:
	var count := config.enemy_count
	var result: Array = []
	var taken := {}

	# Boss: posição reservada (porta da sala no OPEN, perto da saída no CORRIDOR).
	var bcell := boss_cell
	if bcell == Vector2i(-1, -1) or not dist.has(bcell):
		bcell = _farthest(dist)
	taken[bcell] = true

	# Regulares: longe do spawn, fora da sala do boss, espaçados entre si.
	var candidates: Array[Vector2i] = []
	for p: Vector2i in pool:
		if p == bcell or in_boss_room.call(p):
			continue
		if int(dist.get(p, 0)) < config.min_spawn_distance:
			continue
		candidates.append(p)
	_shuffle(candidates, rng)

	var chosen: Array[Vector2i] = []
	var want := count - 1
	var spacing := config.min_enemy_spacing
	# Afrouxa o espaçamento se necessário até garantir a contagem da config.
	while chosen.size() < want and spacing >= 0:
		for p: Vector2i in candidates:
			if chosen.size() >= want:
				break
			if taken.has(p):
				continue
			if _near_any(p, chosen, spacing - 1):
				continue
			chosen.append(p)
			taken[p] = true
		spacing -= 1

	var idx := 0
	for p: Vector2i in chosen:
		result.append({"id": "p%d_e%d" % [config.phase, idx], "x": p.x, "y": p.y, "boss": false})
		idx += 1
	result.append({"id": "p%d_e%d" % [config.phase, idx], "x": bcell.x, "y": bcell.y, "boss": true})
	return result

func _pick_free(rng: RandomNumberGenerator, pool: Array[Vector2i], taken: Dictionary) -> Vector2i:
	var cands: Array[Vector2i] = []
	for p: Vector2i in pool:
		if not taken.has(p):
			cands.append(p)
	if cands.is_empty():
		return Vector2i(-1, -1)
	var c: Vector2i = cands[rng.randi_range(0, cands.size() - 1)]
	taken[c] = true
	return c

# ─── Helpers de grid ───────────────────────────────
func _blank(w: int, h: int, ch: String) -> Array:
	var g: Array = []
	for y: int in h:
		var row: Array = []
		for x: int in w:
			row.append(ch)
		g.append(row)
	return g

func _frame_walls(tiles: Array, w: int, h: int) -> void:
	for x: int in w:
		tiles[0][x] = GeneratedMap.WALL
		tiles[h - 1][x] = GeneratedMap.WALL
	for y: int in h:
		tiles[y][0] = GeneratedMap.WALL
		tiles[y][w - 1] = GeneratedMap.WALL

func _fill_interior(tiles: Array, w: int, h: int, ch: String) -> void:
	for y: int in range(1, h - 1):
		for x: int in range(1, w - 1):
			tiles[y][x] = ch

func _set_tile(tiles: Array, p: Vector2i, ch: String) -> void:
	tiles[p.y][p.x] = ch

# ─── Helpers de busca ──────────────────────────────
func _farthest(dist: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := -1
	for p: Vector2i in dist.keys():
		if int(dist[p]) > bd:
			bd = int(dist[p])
			best = p
	return best

func _near_exit_cell(dist: Dictionary, exit_pos: Vector2i) -> Vector2i:
	for d: Vector2i in CARDINALS:
		var nb: Vector2i = exit_pos + d
		if dist.has(nb):
			return nb
	return exit_pos

func _near_any(p: Vector2i, others: Array, radius: int) -> bool:
	# True se p está a <= radius (manhattan) de alguém em others.
	for q: Vector2i in others:
		if _manhattan(p, q) <= radius:
			return true
	return false

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

# ─── Determinismo ──────────────────────────────────
func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	# Fisher-Yates com o RNG semeado (Array.shuffle() usa o RNG global — não-determinístico).
	for i: int in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _mix(s: int, salt: int) -> int:
	# Deriva um sub-seed estável por tentativa, mantendo generate(config, S) determinístico.
	return (s * 1000003) ^ (salt * 2654435761 + 12345)
