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
