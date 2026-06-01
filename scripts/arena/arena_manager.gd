class_name ArenaManager
extends Node2D

@export var caipora_combat_scene: PackedScene
## Cena do inimigo. Default = Criatura; pode ser trocada por Boss (ou qualquer
## CombatActor com EnemyStateMachine) sem o ArenaManager conhecer a classe.
@export var enemy_scene: PackedScene

var _caipora: CombatActor
var _enemy: Criatura
var _timing_system: TimingSystem
var _timing_cue: TimingCue
var _feedback: FeedbackSystem
var _sfx: SfxSystem

func _ready() -> void:
	_timing_system = $TimingSystem
	_timing_cue = $TimingCue
	_feedback = $FeedbackSystem
	_sfx = $SfxSystem

	_spawn_caipora()
	_spawn_enemy()
	_start_caipora_turn()

func _spawn_caipora() -> void:
	if caipora_combat_scene == null:
		push_error("ArenaManager: caipora_combat_scene não atribuído")
		return
	_caipora = caipora_combat_scene.instantiate()
	_caipora.position = Vector2(160, 240)
	add_child(_caipora)
	# Aplica HP de run + bônus/cooldown de meta (após _ready do HealthComponent).
	_caipora.health.max_health = GameState.caipora_max_hp
	_caipora.health.current_health = clampi(GameState.caipora_current_hp, 0, GameState.caipora_max_hp)
	_caipora.attack_cooldown = maxf(0.3, Constants.ATTACK_COOLDOWN_SECONDS - MetaProgression.get_cooldown_reduction())
	_caipora.health.health_changed.connect(_on_caipora_health_changed)
	_caipora.health.died.connect(_on_actor_died.bind(_caipora))
	_caipora.health.died.connect(func(): SignalBus.caipora_died.emit())
	# Inicializa o HUD com o estado atual da run.
	SignalBus.caipora_health_changed.emit(_caipora.health.current_health, _caipora.health.max_health)

func _on_caipora_health_changed(new_health: int, max_health: int) -> void:
	SignalBus.caipora_health_changed.emit(new_health, max_health)

func _spawn_enemy() -> void:
	# GameState pode definir o inimigo do próximo combate (ex: hub na Fase 4).
	var scene := enemy_scene
	if GameState.next_enemy_scene != null:
		scene = GameState.next_enemy_scene
		GameState.next_enemy_scene = null
	if scene == null:
		push_error("ArenaManager: enemy_scene não atribuído")
		return
	_enemy = scene.instantiate()
	_enemy.position = Vector2(480, 240)
	add_child(_enemy)
	_enemy.health.died.connect(_on_actor_died.bind(_enemy))
	_enemy.state_machine.attack_started.connect(_on_enemy_attack_started)
	_enemy.state_machine.pattern_finished.connect(_on_enemy_pattern_finished)

func _both_alive() -> bool:
	return _caipora.health.is_alive() and _enemy.health.is_alive()

# ─── Turno da Caipora (Ataque) ─────────────────────
func _start_caipora_turn() -> void:
	if not _both_alive():
		return
	_sfx.play(_sfx.attack_sound)
	_timing_system.timing_result.connect(_on_attack_timing_result)
	_timing_cue.show_cue(1.5)
	_timing_system.open_window(1.5, 0.35, 0.65)

func _on_attack_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_attack_timing_result)

	var is_critical := result == TimingSystem.TimingResult.PERFECT
	var damage := _caipora.execute_attack(is_critical)
	_enemy.take_damage(damage)
	if is_critical:
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(12.0, 0.4)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(3)
	else:
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(5.0, 0.2)
		_feedback.spawn_blood_particles(_enemy.position)

	if _enemy.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_enemy_turn()

# ─── Turno do Inimigo (Defesa) ─────────────────────
# A cadência (wind-up, golpes, cooldown) é dirigida pela EnemyStateMachine.
func _start_enemy_turn() -> void:
	if not _both_alive():
		return
	_enemy.state_machine.start_pattern(_enemy.attack_pattern)

func _on_enemy_attack_started() -> void:
	if not _both_alive():
		return
	var window := _enemy.attack_pattern.attack_duration
	# Em multi-strike, garante estado limpo entre golpes consecutivos.
	if _timing_system.timing_result.is_connected(_on_defense_timing_result):
		_timing_system.timing_result.disconnect(_on_defense_timing_result)
	_timing_system.timing_result.connect(_on_defense_timing_result)
	_timing_cue.show_cue(window)
	_timing_system.open_window(window, 0.4, 0.6)

func _on_defense_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_defense_timing_result)

	if result == TimingSystem.TimingResult.PERFECT:
		_caipora.dodge_performed.emit()
		_sfx.play(_sfx.dodge_sound)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		var counter_damage := _caipora.execute_attack(true, Constants.DAMAGE_COUNTER_MULTIPLIER)
		_enemy.take_damage(counter_damage)
		_feedback.trigger_screenshake(10.0, 0.35)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(4)
	else:
		var damage := _enemy.execute_attack(false)
		_caipora.take_damage(damage)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(8.0, 0.3)
		_feedback.spawn_blood_particles(_caipora.position)
		_feedback.trigger_hit_stop(2)

func _on_enemy_pattern_finished() -> void:
	if _both_alive():
		_start_caipora_turn()

# ─── Morte ─────────────────────────────────────────
func _on_actor_died(actor: CombatActor) -> void:
	var caipora_won := actor == _enemy
	# Grava o HP sobrevivente de volta no GameState (0 em caso de derrota).
	GameState.caipora_current_hp = maxi(0, _caipora.health.current_health)
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.state_machine.stop()
	_sfx.play(_sfx.death_sound)
	_feedback.spawn_death_particles(actor.position)
	_feedback.trigger_screenshake(20.0, 0.6)
	_feedback.trigger_hit_stop(5)

	SignalBus.arena_exited.emit(caipora_won)
	# Aguarda a death animation (flash + fade ≈ 0.55s) antes de trocar de tela.
	await get_tree().create_timer(0.6).timeout
	if caipora_won:
		if GameState.active_combat_is_boss:
			GameState.change_screen(SignalBus.Screen.WIN)
		else:
			GameState.defeated_enemy_ids.append(GameState.active_map_enemy_id)
			GameState.change_screen(SignalBus.Screen.EXPLORATION)
	else:
		GameState.change_screen(SignalBus.Screen.GAME_OVER)
