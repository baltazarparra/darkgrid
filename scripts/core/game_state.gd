extends Node

# Manages high-level game state: current screen and pause.
# Emits changes through SignalBus so UI and scenes react.

# ─── State ─────────────────────────────────────────
var current_screen: SignalBus.Screen = SignalBus.Screen.MAIN_MENU
var is_paused: bool = false

# Inimigo do próximo combate. Se != null, o ArenaManager o usa e reseta.
# Ponto único para a Fase 4 (hub) escolher encontros (ex: Boss).
var next_enemy_scene: PackedScene = null
var active_phase: int = 1

# ─── Estado de Run (volátil; HP não vai para o save) ──
var run_active: bool = false
var caipora_max_hp: float = Constants.CAIPORA_MAX_HEALTH
var caipora_current_hp: float = Constants.CAIPORA_MAX_HEALTH

# Seed da run: define os mapas procedurais. Sorteado por run → mapa novo a cada vez.
# Determinístico por fase: a volta da arena regenera o MESMO mapa (mix run_seed+fase).
var run_seed: int = 0

# ─── Exploration State ─────────────────────────────
var defeated_enemy_ids: Array[String] = []
var active_map_enemy_id: String = ""
var active_combat_is_boss: bool = false
var has_key: bool = false
var chest_opened: bool = false
var player_map_pos: Vector2i = Vector2i(-1, -1)

## Inicia uma nova run: HP cheio.
func start_run() -> void:
	run_active = true
	active_phase = 1
	defeated_enemy_ids.clear()
	active_map_enemy_id = ""
	active_combat_is_boss = false
	has_key = false
	chest_opened = false
	player_map_pos = Vector2i(-1, -1)
	run_seed = randi()
	caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_health_bonus()
	caipora_current_hp = caipora_max_hp

## Seed determinística do mapa de uma fase nesta run. Mesma run+fase → mesmo mapa,
## então voltar da arena para a exploração regenera o mapa idêntico.
func map_seed_for_phase(phase: int) -> int:
	return (run_seed * 1000003) ^ (phase * 2654435761 + 12345)

## Recupera HP cheio (chamado ao entrar no Hub).
func heal_to_full() -> void:
	caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_health_bonus()
	caipora_current_hp = caipora_max_hp

## Encerra a run, registra estatísticas e persiste.
func end_run(won: bool) -> void:
	run_active = false
	MetaProgression.total_runs += 1
	if won:
		MetaProgression.total_wins += 1
	MetaProgression.save_progress()

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	SignalBus.screen_changed.connect(_on_screen_changed)

# ─── Public API ────────────────────────────────────
func change_screen(new_screen: SignalBus.Screen) -> void:
	current_screen = new_screen
	SignalBus.screen_changed.emit(new_screen)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

# ─── Private ───────────────────────────────────────
func _on_screen_changed(new_screen: SignalBus.Screen) -> void:
	match new_screen:
		SignalBus.Screen.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		SignalBus.Screen.HUB:
			get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")
		SignalBus.Screen.ARENA:
			get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
		SignalBus.Screen.EXPLORATION:
			get_tree().change_scene_to_file("res://scenes/exploration/exploration.tscn")
		SignalBus.Screen.WIN:
			get_tree().change_scene_to_file("res://scenes/ui/win.tscn")
		SignalBus.Screen.GAME_OVER:
			get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
		SignalBus.Screen.EXPLORATION_PHASE2:
			get_tree().change_scene_to_file("res://scenes/exploration/exploration_phase2.tscn")
		SignalBus.Screen.ARENA_PHASE2:
			get_tree().change_scene_to_file("res://scenes/arena/arena_phase2.tscn")
		SignalBus.Screen.EXPLORATION_PHASE3:
			get_tree().change_scene_to_file("res://scenes/exploration/exploration_phase3.tscn")
		SignalBus.Screen.ARENA_PHASE3:
			get_tree().change_scene_to_file("res://scenes/arena/arena_phase3.tscn")
		SignalBus.Screen.EXPLORATION_PHASE4:
			get_tree().change_scene_to_file("res://scenes/exploration/exploration_phase4.tscn")
		SignalBus.Screen.ARENA_PHASE4:
			get_tree().change_scene_to_file("res://scenes/arena/arena_phase4.tscn")
		SignalBus.Screen.ENDING:
			get_tree().change_scene_to_file("res://scenes/ui/ending_screen.tscn")
