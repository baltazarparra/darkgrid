class_name ArenaManager
extends Node2D

@export var caipora_combat_scene: PackedScene
@export var criatura_scene: PackedScene

var _caipora: CombatActor
var _criatura: CombatActor
var _timing_system: TimingSystem
var _timing_cue: TimingCue
var _feedback: FeedbackSystem
var _windup_timer: Timer

func _ready() -> void:
	_timing_system = $TimingSystem
	_timing_cue = $TimingCue
	_feedback = $FeedbackSystem
	
	_windup_timer = Timer.new()
	_windup_timer.one_shot = true
	_windup_timer.wait_time = 0.5
	_windup_timer.timeout.connect(_on_windup_finished)
	add_child(_windup_timer)
	
	_spawn_caipora()
	_spawn_criatura()
	_start_caipora_turn()

func _spawn_caipora() -> void:
	if caipora_combat_scene == null:
		push_error("ArenaManager: caipora_combat_scene não atribuído")
		return
	_caipora = caipora_combat_scene.instantiate()
	_caipora.position = Vector2(160, 240)
	add_child(_caipora)
	_caipora.health.died.connect(_on_actor_died.bind(_caipora))

func _spawn_criatura() -> void:
	if criatura_scene == null:
		push_error("ArenaManager: criatura_scene não atribuído")
		return
	_criatura = criatura_scene.instantiate()
	_criatura.position = Vector2(480, 240)
	add_child(_criatura)
	_criatura.health.died.connect(_on_actor_died.bind(_criatura))

# ─── Turno da Caipora (Ataque) ─────────────────────
func _start_caipora_turn() -> void:
	if not _caipora.health.is_alive() or not _criatura.health.is_alive():
		return
	_timing_system.timing_result.connect(_on_attack_timing_result)
	_timing_cue.show_cue(1.5)
	_timing_system.open_window(1.5, 0.35, 0.65)

func _on_attack_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_attack_timing_result)
	
	var is_critical := result == TimingSystem.TimingResult.PERFECT
	if is_critical:
		_feedback.trigger_screenshake(12.0, 0.4)
	else:
		_feedback.trigger_screenshake(5.0, 0.2)

	var damage := _caipora.execute_attack(is_critical)
	_criatura.take_damage(damage)
	_feedback.spawn_impact_particles(_criatura.position)
	
	if _criatura.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_creature_turn()

# ─── Turno da Criatura (Defesa) ────────────────────
func _start_creature_turn() -> void:
	if not _caipora.health.is_alive() or not _criatura.health.is_alive():
		return
	_windup_timer.start()

func _on_windup_finished() -> void:
	if not _caipora.health.is_alive() or not _criatura.health.is_alive():
		return
	_timing_system.timing_result.connect(_on_defense_timing_result)
	_timing_cue.show_cue(1.0)
	_timing_system.open_window(1.0, 0.4, 0.6)

func _on_defense_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_defense_timing_result)
	
	if result == TimingSystem.TimingResult.PERFECT:
		_caipora.dodge_performed.emit()
		var counter_damage := _caipora.execute_attack(true, Constants.DAMAGE_COUNTER_MULTIPLIER)
		_criatura.take_damage(counter_damage)
		_feedback.trigger_screenshake(10.0, 0.35)
		_feedback.spawn_impact_particles(_criatura.position)
	else:
		var damage := _criatura.execute_attack(false)
		_caipora.take_damage(damage)
		_feedback.trigger_screenshake(8.0, 0.3)
		_feedback.spawn_impact_particles(_caipora.position)
	
	if _caipora.health.is_alive():
		await get_tree().create_timer(_criatura.attack_cooldown).timeout
		_start_caipora_turn()

# ─── Morte ─────────────────────────────────────────
func _on_actor_died(actor: CombatActor) -> void:
	var caipora_won := actor == _criatura
	_feedback.trigger_screenshake(20.0, 0.6)
	_feedback.spawn_impact_particles(actor.position)
	
	SignalBus.arena_exited.emit(caipora_won)
	if caipora_won:
		GameState.change_screen(SignalBus.Screen.WIN)
	else:
		GameState.change_screen(SignalBus.Screen.GAME_OVER)
