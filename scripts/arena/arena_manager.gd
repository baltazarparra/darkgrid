class_name ArenaManager
extends Node2D

@export var caipora_combat_scene: PackedScene
## Cena do inimigo. Default = Criatura; pode ser trocada por Boss (ou qualquer
## CombatActor com EnemyStateMachine) sem o ArenaManager conhecer a classe.
@export var enemy_scene: PackedScene

const BOSS_BUBBLE_COLOR := Constants.COLOR_BUBBLE_BOSS
const BOSS_BUBBLE_SPREAD_MIN: float = 90.0
const BOSS_BUBBLE_X: Vector2 = Vector2(70.0, 570.0)
const BOSS_BUBBLE_Y: Vector2 = Vector2(80.0, 370.0)

# Retângulo de conteúdo que envolve toda a ação (atores + timing bubbles + boss-spread).
# A câmera dá zoom para encaixá-lo na tela, ampliando o combate e eliminando o espaço
# morto. FILL < 1 deixa um respiro para a HUD (topo) e o D-pad (base).
const STAGE_CENTER: Vector2 = Vector2(320.0, 225.0)
const STAGE_SIZE: Vector2 = Vector2(560.0, 340.0)
const STAGE_FILL: float = 0.92

# Folga extra (px de tela) somada ao raio da bolha ao testar contra o D-pad.
const DPAD_BUBBLE_PADDING: float = 12.0

@onready var _camera: Camera2D = $Camera2D
@onready var _controls_hud: ControlsHud = $ControlsHud

var _caipora: CombatActor
var _enemy: Criatura
var _timing_system: TimingSystem
var _timing_bubble: Node2D
var _timing_bubble_b: Node2D
var _feedback: FeedbackSystem
var _sfx: SfxSystem
var _active_enemy_pattern: AttackPattern
var _last_boss_bubble_pos: Vector2 = Vector2(-999.0, -999.0)
var _first_bubble_pos: Vector2 = Vector2.ZERO
var _is_double_attack: bool = false
var _boss_special_hit_index: int = 0

func _ready() -> void:
	_timing_system = $TimingSystem
	_timing_bubble = $TimingBubble
	_timing_bubble_b = $TimingBubbleB
	_feedback = $FeedbackSystem
	_sfx = $SfxSystem
	_timing_bubble.vulnerable_entered.connect(_on_bubble_vulnerable)
	_timing_bubble_b.vulnerable_entered.connect(_on_bubble_vulnerable)

	_update_camera_fit()
	get_viewport().size_changed.connect(_update_camera_fit)

	_spawn_caipora()
	_spawn_enemy()
	_start_caipora_turn()

func _update_camera_fit() -> void:
	# Zoom "contain": encaixa STAGE_SIZE na viewport sem cortar a ação. Em paisagem o
	# limite é a altura (ação grande, leve folga lateral); em retrato cabe inteiro.
	var vp := get_viewport().get_visible_rect().size
	var z: float = minf(vp.x / STAGE_SIZE.x, vp.y / STAGE_SIZE.y) * STAGE_FILL
	_camera.zoom = Vector2(z, z)
	_camera.position = STAGE_CENTER

func _spawn_caipora() -> void:
	if caipora_combat_scene == null:
		push_error("ArenaManager: caipora_combat_scene não atribuído")
		return
	_caipora = caipora_combat_scene.instantiate()
	_caipora.position = Vector2(160, 240)
	add_child(_caipora)
	_caipora.health.max_health = GameState.caipora_max_hp
	_caipora.health.current_health = clampf(GameState.caipora_current_hp, 0.0, GameState.caipora_max_hp)
	_caipora.attack_cooldown = Constants.ATTACK_COOLDOWN_SECONDS
	_caipora.base_attack_damage = 1 + MetaProgression.get_damage_bonus()
	_caipora.health.health_changed.connect(_on_caipora_health_changed)
	_caipora.health.died.connect(_on_actor_died.bind(_caipora))
	_caipora.health.died.connect(func(): SignalBus.caipora_died.emit())
	SignalBus.caipora_health_changed.emit(_caipora.health.current_health, _caipora.health.max_health)

func _on_caipora_health_changed(new_health: float, max_health: float) -> void:
	SignalBus.caipora_health_changed.emit(new_health, max_health)

func _spawn_enemy() -> void:
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
	_active_enemy_pattern = _enemy.attack_pattern
	_enemy.health.died.connect(_on_actor_died.bind(_enemy))
	_enemy.health.health_changed.connect(_on_enemy_health_changed)
	_enemy.state_machine.attack_started.connect(_on_enemy_attack_started)
	_enemy.state_machine.pattern_finished.connect(_on_enemy_pattern_finished)
	SignalBus.enemy_health_changed.emit(_enemy.health.current_health, _enemy.health.max_health)

func _both_alive() -> bool:
	return _caipora.health.is_alive() and _enemy.health.is_alive()

# ─── Turno da Caipora (Ataque) ─────────────────────
func _start_caipora_turn() -> void:
	if not _both_alive():
		return
	_is_double_attack = randf() < Constants.TIMING_DOUBLE_CHANCE
	_sfx.play(_sfx.attack_sound)
	_first_bubble_pos = _enemy.position + Vector2(0, -78)
	_timing_bubble.show_bubble(
		_first_bubble_pos,
		Constants.TIMING_WINDOW_ATTACK,
		Constants.TIMING_PERFECT_START,
		Constants.TIMING_PERFECT_END,
		false, Color.TRANSPARENT, "up"
	)
	if _is_double_attack:
		var total: float = Constants.TIMING_DOUBLE_INTERVAL + Constants.TIMING_WINDOW_ATTACK
		var p1s: float = Constants.TIMING_PERFECT_START * Constants.TIMING_WINDOW_ATTACK / total
		var p1e: float = Constants.TIMING_PERFECT_END * Constants.TIMING_WINDOW_ATTACK / total
		var p2s: float = (Constants.TIMING_DOUBLE_INTERVAL + Constants.TIMING_PERFECT_START * Constants.TIMING_WINDOW_ATTACK) / total
		var p2e: float = (Constants.TIMING_DOUBLE_INTERVAL + Constants.TIMING_PERFECT_END * Constants.TIMING_WINDOW_ATTACK) / total
		_timing_system.open_window(total, p1s, p1e, true, p2s, p2e, "ui_up", "ui_right")
		_timing_system.timing_first_hit.connect(_on_double_first_hit)
		_timing_system.timing_result.connect(_on_double_final_result)
		get_tree().create_timer(Constants.TIMING_DOUBLE_INTERVAL).timeout.connect(_spawn_second_bubble)
	else:
		_timing_system.open_window(
			Constants.TIMING_WINDOW_ATTACK,
			Constants.TIMING_PERFECT_START,
			Constants.TIMING_PERFECT_END,
			false, 0.0, 0.0, "ui_up"
		)
		_timing_system.timing_result.connect(_on_attack_timing_result)

func _spawn_second_bubble() -> void:
	if not _both_alive() or not _timing_system.is_open():
		return
	var spread: Vector2
	for _i in 20:
		var angle := randf() * TAU
		var dist := randf_range(Constants.TIMING_DOUBLE_BUBBLE_SPREAD_MIN, Constants.TIMING_DOUBLE_BUBBLE_SPREAD_MAX)
		spread = _first_bubble_pos + Vector2(cos(angle) * dist, sin(angle) * dist)
		if not _is_under_dpad(spread):
			break
	_timing_bubble_b.show_bubble(
		spread,
		Constants.TIMING_WINDOW_ATTACK,
		Constants.TIMING_PERFECT_START,
		Constants.TIMING_PERFECT_END,
		false, Color.TRANSPARENT, "right"
	)

func _on_double_first_hit() -> void:
	_timing_system.timing_first_hit.disconnect(_on_double_first_hit)
	_timing_bubble.burst_success()
	var damage := _caipora.execute_attack(false)
	_enemy.take_damage(damage)
	_sfx.play(_sfx.hit_sound)
	_feedback.trigger_screenshake(6.0, 0.2)
	_feedback.trigger_hit_stop(2)

func _on_double_final_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_double_final_result)
	if _timing_system.timing_first_hit.is_connected(_on_double_first_hit):
		_timing_system.timing_first_hit.disconnect(_on_double_first_hit)
	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble_b.burst_success()
		var damage := _caipora.execute_attack(false)
		_enemy.take_damage(damage)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(10.0, 0.35)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(3)
	else:
		_timing_bubble.hide_bubble()
		_timing_bubble_b.hide_bubble()
	if _enemy.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_enemy_turn()

func _on_attack_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_attack_timing_result)
	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble.burst_success()
		var damage := _caipora.execute_attack(true)
		_enemy.take_damage(damage)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(12.0, 0.4)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(3)
	else:
		_timing_bubble.hide_bubble()
	if _enemy.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_enemy_turn()

# ─── Turno do Inimigo (Defesa) ─────────────────────
func _start_enemy_turn() -> void:
	if not _both_alive():
		return
	_boss_special_hit_index = 0
	_last_boss_bubble_pos = Vector2(-999.0, -999.0)
	_active_enemy_pattern = _enemy.get_attack_pattern()
	_enemy.state_machine.start_pattern(_active_enemy_pattern)

func _on_enemy_attack_started() -> void:
	if not _both_alive():
		return
	var window: float = _active_enemy_pattern.attack_duration
	if _timing_system.timing_result.is_connected(_on_defense_timing_result):
		_timing_system.timing_result.disconnect(_on_defense_timing_result)
	_timing_system.timing_result.connect(_on_defense_timing_result)
	var is_special: bool = _active_enemy_pattern.is_special
	var action: String
	var hint: String
	if is_special:
		var seq := ["ui_right", "ui_left", "ui_right", "ui_left"]
		var hint_seq := ["right", "left", "right", "left"]
		var idx := clampi(_boss_special_hit_index, 0, seq.size() - 1)
		action = seq[idx]
		hint = hint_seq[idx]
		_boss_special_hit_index += 1
	else:
		action = "ui_down"
		hint = "down"
	var bubble_pos: Vector2 = _boss_spread_pos() if is_special else _caipora.position + Vector2(0, -70)
	var vuln: Color = BOSS_BUBBLE_COLOR if is_special else Color.TRANSPARENT
	_timing_bubble.show_bubble(bubble_pos, window, Constants.TIMING_PERFECT_START, Constants.TIMING_PERFECT_END, true, vuln, hint)
	_timing_system.open_window(window, Constants.TIMING_PERFECT_START, Constants.TIMING_PERFECT_END, false, 0.0, 0.0, action)

func _on_defense_timing_result(result: TimingSystem.TimingResult) -> void:
	_timing_system.timing_result.disconnect(_on_defense_timing_result)

	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble.burst_success()
		_caipora.dodge_performed.emit()
		_sfx.play(_sfx.dodge_sound)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_feedback.trigger_screenshake(10.0, 0.35)
		_feedback.spawn_dodge_particles(_caipora.position)
		_feedback.trigger_hit_stop(4)
	else:
		_timing_bubble.hide_bubble()
		var damage := _enemy.execute_attack(false, _active_enemy_pattern.damage_multiplier)
		_caipora.take_damage(damage)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(8.0, 0.3)
		_feedback.spawn_blood_particles(_caipora.position)
		_feedback.trigger_hit_stop(2)

func _on_enemy_pattern_finished() -> void:
	if _both_alive():
		_start_caipora_turn()

func _boss_spread_pos() -> Vector2:
	var pos: Vector2
	for _i in 20:
		pos = Vector2(
			randf_range(BOSS_BUBBLE_X.x, BOSS_BUBBLE_X.y),
			randf_range(BOSS_BUBBLE_Y.x, BOSS_BUBBLE_Y.y)
		)
		if _last_boss_bubble_pos.distance_to(pos) >= BOSS_BUBBLE_SPREAD_MIN and not _is_under_dpad(pos):
			break
	_last_boss_bubble_pos = pos
	return pos

func _is_under_dpad(world_pos: Vector2) -> bool:
	var rect := _controls_hud.get_dpad_screen_rect()
	if rect.size == Vector2.ZERO:
		return false
	# Mundo -> tela (a transform do canvas embute a Camera2D).
	var screen_pos := get_viewport().get_canvas_transform() * world_pos
	# Expande pelo raio da bolha em px de tela + folga, para que nem a borda encoste no D-pad.
	var grow := TimingBubble.RADIUS_MAX * _camera.zoom.x + DPAD_BUBBLE_PADDING
	return rect.grow(grow).has_point(screen_pos)

func _on_enemy_health_changed(new_health: float, max_health: float) -> void:
	SignalBus.enemy_health_changed.emit(new_health, max_health)

# ─── Bolha ─────────────────────────────────────────
func _on_bubble_vulnerable() -> void:
	_sfx.play(_sfx.timing_alert_sound)

# ─── Morte ─────────────────────────────────────────
func _on_actor_died(actor: CombatActor) -> void:
	var caipora_won := actor == _enemy
	if caipora_won:
		_caipora.health.max_health += 1
		_caipora.health.heal(1)
		GameState.caipora_max_hp = _caipora.health.max_health
		if not GameState.active_combat_is_boss:
			MetaProgression.add_fragment()
	GameState.caipora_current_hp = maxf(0.0, _caipora.health.current_health)
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.state_machine.stop()
	_sfx.play(_sfx.death_sound)
	_feedback.spawn_death_particles(actor.position)
	_feedback.trigger_screenshake(20.0, 0.6)
	_feedback.trigger_hit_stop(5)

	SignalBus.arena_exited.emit(caipora_won)
	await get_tree().create_timer(0.6).timeout
	if caipora_won:
		if GameState.active_combat_is_boss:
			GameState.change_screen(SignalBus.Screen.WIN)
		else:
			GameState.defeated_enemy_ids.append(GameState.active_map_enemy_id)
			GameState.change_screen(SignalBus.Screen.EXPLORATION)
	else:
		GameState.change_screen(SignalBus.Screen.GAME_OVER)
