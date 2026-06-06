extends GutTest

## Acampamento jogável (Etapa 1 da Fase 9): a cena monta a clareira (chão cercado de mata),
## posiciona a Caipora no spawn e o rastro de saída, e o destino do rastro segue a run
## pendente (entre fases) ou recomeça a caçada (santuário). O D-pad de toque reconhece o HUB
## como gameplay (a Caipora caminha pelo acampamento). Tudo headless.

const HubManagerScript := preload("res://scripts/hub/hub_manager.gd")

var _hub: Node2D
var _saved_run_active: bool
var _saved_pending: int

func before_each() -> void:
	_saved_run_active = GameState.run_active
	_saved_pending = GameState.pending_exploration

func after_each() -> void:
	if is_instance_valid(_hub):
		_hub.queue_free()
	GameState.run_active = _saved_run_active
	GameState.pending_exploration = _saved_pending

func _instantiate() -> void:
	_hub = load("res://scenes/hub/hub.tscn").instantiate()
	add_child_autofree(_hub)
	await wait_frames(1)

# ── A clareira é montada: chão no spawn e na saída, mata (parede) na borda ──
func test_clearing_is_painted() -> void:
	await _instantiate()
	var tm: TileMap = _hub._tilemap
	assert_eq(tm.get_cell_source_id(0, _hub._spawn_pos), 0, "spawn é chão (source 0)")
	assert_eq(tm.get_cell_source_id(0, _hub._exit_pos), 0, "saída é chão (source 0)")
	assert_eq(tm.get_cell_source_id(0, Vector2i(0, 0)), 1, "borda do grid é parede (source 1)")
	assert_true(_hub._is_floor(_hub._spawn_pos), "spawn dentro da clareira")
	assert_false(_hub._is_floor(Vector2i(0, 0)), "canto do grid fora da clareira")

# ── Caipora nasce no spawn, longe do rastro de saída ──
func test_caipora_spawns_at_spawn_tile() -> void:
	await _instantiate()
	assert_eq(_hub._caipora.position, Vector2(_hub._spawn_pos) * Constants.TILE_SIZE,
		"Caipora posicionada no tile de spawn")
	assert_ne(_hub._spawn_pos, _hub._exit_pos, "spawn e saída em tiles distintos")

# ── O rastro de saída pulsante é instanciado (sprite âmbar + luz) ──
func test_exit_marker_spawned() -> void:
	await _instantiate()
	assert_gte(_hub._objects.get_child_count(), 2, "marcador + luz da saída em Objects")

# ── Destino do rastro: run em andamento segue a exploração pendente ──
func test_exit_follows_pending_when_run_active() -> void:
	await _instantiate()
	GameState.run_active = true
	GameState.pending_exploration = SignalBus.Screen.EXPLORATION_PHASE3
	assert_eq(_hub._exit_destination(), SignalBus.Screen.EXPLORATION_PHASE3,
		"entre fases: rastro leva à exploração pendente")

# ── Início da run pelo acampamento: start_run() leva o rastro à Fase 1 ──
# A run começa no HUB (main_menu abre o acampamento antes da mata); como start_run() define
# pending_exploration = EXPLORATION, o rastro de saída cai direto na Exploração da Fase 1.
func test_launch_via_hub_leads_to_phase1() -> void:
	await _instantiate()
	GameState.start_run()
	assert_true(GameState.run_active, "run ativa ao iniciar pelo acampamento")
	assert_eq(_hub._exit_destination(), SignalBus.Screen.EXPLORATION,
		"abertura: do acampamento o rastro leva à Fase 1")

# ── Destino do rastro: santuário pós-derrota recomeça na Fase 1 ──
func test_exit_starts_fresh_when_no_run() -> void:
	await _instantiate()
	GameState.run_active = false
	GameState.pending_exploration = SignalBus.Screen.EXPLORATION_PHASE4
	assert_eq(_hub._exit_destination(), SignalBus.Screen.EXPLORATION,
		"santuário: rastro recomeça a caçada na Fase 1")

# ── O D-pad de toque trata o HUB como gameplay (a Caipora anda no acampamento) ──
func test_hub_is_gameplay_for_dpad() -> void:
	assert_true(TouchControls._is_gameplay_screen(SignalBus.Screen.HUB),
		"D-pad visível no acampamento jogável")
	assert_true(TouchControls._is_gameplay_screen(SignalBus.Screen.EXPLORATION),
		"D-pad visível na exploração (sem regressão)")
	assert_false(TouchControls._is_gameplay_screen(SignalBus.Screen.MAIN_MENU),
		"D-pad oculto no menu (sem regressão)")
