extends GutTest

# Roteamento do avanço de fase pelo acampamento (HUB) — Fase 9, Etapa 0.
# A regra central: SÓ avanços de fase (exploração de fase POSTERIOR) passam pelo hub;
# volta para a mesma fase, ENDING e GAME_OVER seguem diretos. Lógica pura, roda headless.

const ArenaManagerScript := preload("res://scripts/arena/arena_manager.gd")

var _saved_phase: int
var _saved_pending: int
var _saved_player_pos: Vector2i
var _saved_enemy_pos: Dictionary

func before_each() -> void:
	_saved_phase = GameState.active_phase
	_saved_pending = GameState.pending_exploration
	_saved_player_pos = GameState.player_map_pos
	_saved_enemy_pos = GameState.map_enemy_positions.duplicate()

func after_each() -> void:
	GameState.active_phase = _saved_phase
	GameState.pending_exploration = _saved_pending
	GameState.player_map_pos = _saved_player_pos
	GameState.map_enemy_positions = _saved_enemy_pos
	# Mata qualquer transição agendada por change_screen(HUB) ANTES do swap real de cena.
	if SceneTransition._tween != null and SceneTransition._tween.is_valid():
		SceneTransition._tween.kill()

# Instância DESTACADA (fora da árvore): _ready() não roda, então os $nós-filhos da
# arena não são exigidos. _screen_phase/_is_phase_advance são puros (sem @onready).
func _make_arena() -> ArenaManager:
	var am: ArenaManager = ArenaManagerScript.new()
	autofree(am)
	return am

# ── _screen_phase mapeia as 4 explorações; 0 para o resto ──
func test_screen_phase_mapping() -> void:
	var am := _make_arena()
	assert_eq(am._screen_phase(SignalBus.Screen.EXPLORATION), 1, "fase 1")
	assert_eq(am._screen_phase(SignalBus.Screen.EXPLORATION_PHASE2), 2, "fase 2")
	assert_eq(am._screen_phase(SignalBus.Screen.EXPLORATION_PHASE3), 3, "fase 3")
	assert_eq(am._screen_phase(SignalBus.Screen.EXPLORATION_PHASE4), 4, "fase 4")
	assert_eq(am._screen_phase(SignalBus.Screen.EXPLORATION_PHASE5), 5, "fase 5")
	for s: int in [SignalBus.Screen.HUB, SignalBus.Screen.ARENA, SignalBus.Screen.ENDING,
			SignalBus.Screen.GAME_OVER, SignalBus.Screen.MAIN_MENU]:
		assert_eq(am._screen_phase(s), 0, "tela %d não é exploração" % s)

# ── _is_phase_advance: só telas de fase POSTERIOR à atual ──
func test_is_phase_advance() -> void:
	var am := _make_arena()
	# Boss da P2 → P3 e boss da P3 → P4 avançam.
	GameState.active_phase = 2
	assert_true(am._is_phase_advance(SignalBus.Screen.EXPLORATION_PHASE3), "P2→P3 avança")
	GameState.active_phase = 3
	assert_true(am._is_phase_advance(SignalBus.Screen.EXPLORATION_PHASE4), "P3→P4 avança")
	# Boss da P4 → P5 (a igreja) avança pelo acampamento.
	GameState.active_phase = 4
	assert_true(am._is_phase_advance(SignalBus.Screen.EXPLORATION_PHASE5), "P4→P5 avança")
	# Volta para a MESMA fase (boss da P1 / vitória comum) NÃO avança.
	GameState.active_phase = 1
	assert_false(am._is_phase_advance(SignalBus.Screen.EXPLORATION), "P1→P1 não avança")
	GameState.active_phase = 2
	assert_false(am._is_phase_advance(SignalBus.Screen.EXPLORATION_PHASE2), "P2→P2 não avança")
	# ENDING (boss da P5) e GAME_OVER nunca avançam (screen_phase = 0).
	GameState.active_phase = 5
	assert_false(am._is_phase_advance(SignalBus.Screen.ENDING), "P5→ENDING direto")
	assert_false(am._is_phase_advance(SignalBus.Screen.GAME_OVER), "GAME_OVER direto")

# ── advance_phase_via_hub: guarda o destino, zera a continuidade e cai no HUB ──
func test_advance_phase_via_hub() -> void:
	GameState.player_map_pos = Vector2i(5, 7)
	GameState.map_enemy_positions = {"e1": Vector2i(1, 1)}
	GameState.advance_phase_via_hub(SignalBus.Screen.EXPLORATION_PHASE3)
	assert_eq(GameState.pending_exploration, int(SignalBus.Screen.EXPLORATION_PHASE3),
		"próxima exploração pendente guardada")
	assert_eq(GameState.player_map_pos, Vector2i(-1, -1),
		"continuidade do jogador zerada (fase nova começa no spawn)")
	assert_true(GameState.map_enemy_positions.is_empty(),
		"snapshot de inimigos zerado")
	assert_eq(GameState.current_screen, int(SignalBus.Screen.HUB),
		"vai para o acampamento")

# ── start_run reseta o destino pendente para a Fase 1 ──
func test_start_run_resets_pending() -> void:
	GameState.pending_exploration = SignalBus.Screen.EXPLORATION_PHASE4
	GameState.start_run()
	assert_eq(GameState.pending_exploration, int(SignalBus.Screen.EXPLORATION),
		"nova run aponta para a Fase 1")
