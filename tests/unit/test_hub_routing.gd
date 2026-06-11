extends GutTest

# Roteamento pós-combate e avanço de fase pelo acampamento (HUB).
# A regra central: vitória na arena NUNCA avança a fase — boss ou comum, volta à
# exploração da MESMA fase; avançar é pisar no tile de saída (que passa pelo hub).
# Exceção única: o boss FINAL (P5) → ENDING. Lógica pura, roda headless.

const ArenaManagerScript := preload("res://scripts/arena/arena_manager.gd")

var _saved_phase: int
var _saved_is_boss: bool
var _saved_pending: int
var _saved_player_pos: Vector2i
var _saved_enemy_pos: Dictionary

func before_each() -> void:
	_saved_phase = GameState.active_phase
	_saved_is_boss = GameState.active_combat_is_boss
	_saved_pending = GameState.pending_exploration
	_saved_player_pos = GameState.player_map_pos
	_saved_enemy_pos = GameState.map_enemy_positions.duplicate()

func after_each() -> void:
	GameState.active_phase = _saved_phase
	GameState.active_combat_is_boss = _saved_is_boss
	GameState.pending_exploration = _saved_pending
	GameState.player_map_pos = _saved_player_pos
	GameState.map_enemy_positions = _saved_enemy_pos
	# Mata qualquer transição agendada por change_screen(HUB) ANTES do swap real de cena.
	if SceneTransition._tween != null and SceneTransition._tween.is_valid():
		SceneTransition._tween.kill()

# Instância DESTACADA (fora da árvore): _ready() não roda, então os $nós-filhos da
# arena não são exigidos. _resolve_next_screen é puro (só lê GameState).
func _make_arena() -> ArenaManager:
	var am: ArenaManager = ArenaManagerScript.new()
	autofree(am)
	return am

const SAME_PHASE_SCREEN := {
	1: SignalBus.Screen.EXPLORATION,
	2: SignalBus.Screen.EXPLORATION_PHASE2,
	3: SignalBus.Screen.EXPLORATION_PHASE3,
	4: SignalBus.Screen.EXPLORATION_PHASE4,
	5: SignalBus.Screen.EXPLORATION_PHASE5,
}

# ── Derrota → GAME_OVER, boss ou comum ──
func test_resolve_defeat_goes_to_game_over() -> void:
	var am := _make_arena()
	for phase: int in SAME_PHASE_SCREEN.keys():
		GameState.active_phase = phase
		for is_boss: bool in [false, true]:
			GameState.active_combat_is_boss = is_boss
			assert_eq(am._resolve_next_screen(false), SignalBus.Screen.GAME_OVER,
				"derrota na P%d (boss=%s) → GAME_OVER" % [phase, is_boss])

# ── Vitória comum → exploração da MESMA fase ──
func test_resolve_common_win_returns_to_same_phase() -> void:
	var am := _make_arena()
	GameState.active_combat_is_boss = false
	for phase: int in SAME_PHASE_SCREEN.keys():
		GameState.active_phase = phase
		assert_eq(am._resolve_next_screen(true), SAME_PHASE_SCREEN[phase],
			"vitória comum na P%d volta à mesma fase" % phase)

# ── Vitória de BOSS (P1–P4) → MESMA fase: o avanço é só pelo tile de saída ──
func test_resolve_boss_win_never_advances_phase() -> void:
	var am := _make_arena()
	GameState.active_combat_is_boss = true
	for phase: int in [1, 2, 3, 4]:
		GameState.active_phase = phase
		assert_eq(am._resolve_next_screen(true), SAME_PHASE_SCREEN[phase],
			"boss da P%d morto → volta à exploração da P%d (sem avanço)" % [phase, phase])

# ── Boss FINAL (Jesuíta, P5) → ENDING direto ──
func test_resolve_final_boss_win_goes_to_ending() -> void:
	var am := _make_arena()
	GameState.active_combat_is_boss = true
	GameState.active_phase = 5
	assert_eq(am._resolve_next_screen(true), SignalBus.Screen.ENDING,
		"Jesuíta morto encerra o jogo")

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
