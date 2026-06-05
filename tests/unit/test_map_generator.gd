extends GutTest

# Invariantes da geração procedural de mapas (Etapa 0 — fundação testável).
# Cada invariante roda sobre as 4 fases × vários seeds. É o que separa
# "procedural elegante" de "procedural quebrado".

const PHASES := [1, 2, 3, 4]
const SEEDS := [1, 2, 3, 7, 42, 99, 128, 256, 1001, 31337]

func _gen(phase: int, seed_val: int) -> GeneratedMap:
	var cfg := MapConfig.for_phase(phase)
	var gen := MapGenerator.new()
	return gen.generate(cfg, seed_val)

func _enemy_sig(m: GeneratedMap) -> String:
	var parts: Array = []
	for e: Dictionary in m.enemies:
		parts.append("%s:%d,%d,%s" % [e["id"], e["x"], e["y"], str(e["boss"])])
	return ",".join(parts)

# ── Determinismo: mesmo seed → mapa idêntico (contrato do loop run→arena→volta) ──
func test_determinism_identical_for_same_seed() -> void:
	for phase: int in PHASES:
		var a := _gen(phase, 42)
		var b := _gen(phase, 42)
		assert_eq(a.rows(), b.rows(), "grid idêntico p/ mesmo seed (fase %d)" % phase)
		assert_eq(a.exit_pos, b.exit_pos, "saída idêntica (fase %d)" % phase)
		assert_eq(a.player_start, b.player_start, "spawn idêntico (fase %d)" % phase)
		assert_eq(_enemy_sig(a), _enemy_sig(b), "inimigos idênticos (fase %d)" % phase)
		assert_eq(a.chest_pos, b.chest_pos, "baú idêntico (fase %d)" % phase)
		assert_eq(a.key_pos, b.key_pos, "chave idêntica (fase %d)" % phase)

# ── Dimensões corretas e bordas sempre parede (sem vazamento off-grid) ──
func test_dimensions_and_border_walls() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			assert_eq(m.tiles.size(), Constants.GRID_HEIGHT, "altura do grid")
			assert_eq(m.tiles[0].size(), Constants.GRID_WIDTH, "largura do grid")
			for x: int in Constants.GRID_WIDTH:
				assert_eq(m.char_at(Vector2i(x, 0)), "W", "borda topo parede")
				assert_eq(m.char_at(Vector2i(x, Constants.GRID_HEIGHT - 1)), "W", "borda base parede")
			for y: int in Constants.GRID_HEIGHT:
				assert_eq(m.char_at(Vector2i(0, y)), "W", "borda esquerda parede")
				assert_eq(m.char_at(Vector2i(Constants.GRID_WIDTH - 1, y)), "W", "borda direita parede")

# ── Conectividade: a saída SEMPRE é alcançável do spawn ──
func test_exit_reachable_from_start() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var dist := m.reachable_from(m.player_start)
			assert_true(dist.has(m.exit_pos),
				"saída alcançável (fase %d seed %d)" % [phase, s])

func test_player_start_walkable_and_not_exit() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			assert_true(m.is_walkable(m.player_start), "spawn caminhável")
			assert_ne(m.player_start, m.exit_pos, "spawn != saída")

# ── Paridade de conteúdo: contagem de inimigos casa com a referência ──
func test_enemy_count_matches_config() -> void:
	for phase: int in PHASES:
		var expected := MapConfig.for_phase(phase).enemy_count
		for s: int in SEEDS:
			var m := _gen(phase, s)
			assert_eq(m.enemies.size(), expected,
				"contagem de inimigos (fase %d seed %d)" % [phase, s])

func test_exactly_one_boss() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var bosses := 0
			for e: Dictionary in m.enemies:
				if e["boss"]:
					bosses += 1
			assert_eq(bosses, 1, "exatamente 1 boss (fase %d seed %d)" % [phase, s])

# ── Sanidade de placement: inimigos em chão alcançável, únicos, fora do spawn ──
func test_enemies_walkable_reachable_unique_offspawn() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var dist := m.reachable_from(m.player_start)
			var seen := {}
			for e: Dictionary in m.enemies:
				var p := Vector2i(e["x"], e["y"])
				assert_true(m.is_walkable(p), "inimigo em tile caminhável")
				assert_true(dist.has(p), "inimigo alcançável do spawn")
				assert_ne(p, m.player_start, "inimigo não nasce no spawn")
				assert_false(seen.has(p), "sem inimigos sobrepostos")
				seen[p] = true

# ── Hazards: zero quando a fase não tem; densidade limitada quando tem ──
func test_hazard_density_within_bounds() -> void:
	for phase: int in PHASES:
		var cfg := MapConfig.for_phase(phase)
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var hazards := 0
			var floors := 0
			for y: int in m.tiles.size():
				var row: Array = m.tiles[y]
				for x: int in row.size():
					var ch: String = row[x]
					if ch == "R" or ch == "S":
						hazards += 1
					if ch != "W":
						floors += 1
			if cfg.hazard_chars.is_empty():
				assert_eq(hazards, 0, "fase sem hazard não gera hazard (fase %d)" % phase)
			else:
				var frac := float(hazards) / float(maxi(1, floors))
				assert_lt(frac, cfg.hazard_density + 0.08,
					"densidade de hazard sob controle (fase %d seed %d)" % [phase, s])

# ── Variação: seeds diferentes produzem mapas diferentes ──
func test_seed_variation() -> void:
	for phase: int in PHASES:
		var a := _gen(phase, 1)
		var b := _gen(phase, 2)
		assert_ne(a.rows(), b.rows(),
			"seeds diferentes → mapas diferentes (fase %d)" % phase)

# ── Baú/chave só existem quando a config pede ──
func test_chest_key_only_when_configured() -> void:
	var m1 := _gen(1, 5)  # Fase 1 tem baú + chave
	assert_ne(m1.chest_pos, Vector2i(-1, -1), "fase 1 tem baú")
	assert_ne(m1.key_pos, Vector2i(-1, -1), "fase 1 tem chave")
	for phase: int in [2, 3, 4]:
		var m := _gen(phase, 5)
		assert_eq(m.chest_pos, Vector2i(-1, -1), "fase %d sem baú" % phase)
		assert_eq(m.key_pos, Vector2i(-1, -1), "fase %d sem chave" % phase)

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

# ── Contagem padrão por fase: 4 / 4 / 6 / 6 ──
func test_phase_enemy_counts_are_4_4_6_6() -> void:
	assert_eq(MapConfig.for_phase(1).enemy_count, 4, "fase 1 = 4")
	assert_eq(MapConfig.for_phase(2).enemy_count, 4, "fase 2 = 4")
	assert_eq(MapConfig.for_phase(3).enemy_count, 6, "fase 3 = 6")
	assert_eq(MapConfig.for_phase(4).enemy_count, 6, "fase 4 = 6")

# ── Boss sempre distante do jogador (na metade mais longe do mapa) ──
func test_boss_far_from_player() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var dist := m.reachable_from(m.player_start)
			var max_d := 0
			for d: int in dist.values():
				max_d = maxi(max_d, d)
			var b := m.boss()
			var bd: int = int(dist.get(Vector2i(b["x"], b["y"]), 0))
			assert_gte(bd, int(max_d * 0.5),
				"boss na metade mais distante (fase %d seed %d)" % [phase, s])

# ── Sempre 1+ monstro perto do boss (guardas) ──
func test_at_least_one_enemy_near_boss() -> void:
	for phase: int in PHASES:
		for s: int in SEEDS:
			var m := _gen(phase, s)
			var b := m.boss()
			var bpos := Vector2i(b["x"], b["y"])
			var near := 0
			for e: Dictionary in m.enemies:
				if e["boss"]:
					continue
				if _manhattan(Vector2i(e["x"], e["y"]), bpos) <= MapGenerator.BOSS_GUARD_RADIUS:
					near += 1
			assert_gte(near, 1, "ao menos 1 guarda perto do boss (fase %d seed %d)" % [phase, s])

# ── Baú e chave: longe do jogador e longe um do outro ──
func test_chest_key_distant() -> void:
	for s: int in SEEDS:
		var m := _gen(1, s)  # só a fase 1 tem baú/chave
		var dist := m.reachable_from(m.player_start)
		assert_gte(int(dist.get(m.chest_pos, 0)), MapGenerator.CHEST_KEY_MIN_PLAYER_DIST,
			"baú longe do spawn (seed %d)" % s)
		assert_gte(int(dist.get(m.key_pos, 0)), MapGenerator.CHEST_KEY_MIN_PLAYER_DIST,
			"chave longe do spawn (seed %d)" % s)
		assert_gte(_manhattan(m.chest_pos, m.key_pos), MapGenerator.CHEST_KEY_MIN_SEPARATION,
			"baú e chave separados (seed %d)" % s)

# ── Decorações: quantidade certa, em chão livre, sem sobrepor entidades ──
func test_decorations_valid() -> void:
	for phase: int in PHASES:
		var expected := MapConfig.for_phase(phase).decoration_count
		for s: int in SEEDS:
			var m := _gen(phase, s)
			assert_eq(m.decorations.size(), expected,
				"contagem de decorações (fase %d seed %d)" % [phase, s])
			var occupied := {m.player_start: true, m.exit_pos: true,
				m.chest_pos: true, m.key_pos: true}
			for e: Dictionary in m.enemies:
				occupied[Vector2i(e["x"], e["y"])] = true
			var seen := {}
			for d: Vector2i in m.decorations:
				assert_true(m.is_walkable(d), "decoração em chão caminhável")
				assert_ne(m.char_at(d), "E", "decoração não na saída")
				assert_false(occupied.has(d), "decoração não sobrepõe entidade")
				assert_false(seen.has(d), "decorações sem sobreposição entre si")
				seen[d] = true
