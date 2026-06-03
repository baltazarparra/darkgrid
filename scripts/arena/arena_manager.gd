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
# D-pad é um autoload persistente (TouchControls), não mais um nó por cena.
@onready var _controls_hud: ControlsHud = TouchControls

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
# Encerramento de combate: a morte de um ator dispara teardown + transição UMA única vez.
# _combat_over barra qualquer reentrância de turno/timing após a morte; _screen_changed
# garante que a troca de cena ocorra exatamente uma vez (caminho normal OU watchdog).
var _combat_over: bool = false
var _screen_changed: bool = false

func _ready() -> void:
	_timing_system = $TimingSystem
	_timing_bubble = $TimingBubble
	_timing_bubble_b = $TimingBubbleB
	# Bolhas acima dos atores (z 0): a seta da tecla precisa ficar sempre visível.
	# Fica abaixo das CanvasLayer da HUD/D-pad, que desenham em camada própria.
	_timing_bubble.z_index = 10
	_timing_bubble_b.z_index = 10
	_feedback = $FeedbackSystem
	_sfx = $SfxSystem
	_timing_bubble.vulnerable_entered.connect(_on_bubble_vulnerable)
	_timing_bubble_b.vulnerable_entered.connect(_on_bubble_vulnerable)
	# Feedback tátil a cada input na janela de combate (conectado uma única vez).
	_timing_system.input_registered.connect(_on_input_registered)
	_feedback.hit_stop_started.connect(_on_hit_stop_started)
	_feedback.hit_stop_ended.connect(_on_hit_stop_ended)

	_update_camera_fit()
	get_viewport().size_changed.connect(_update_camera_fit)

	add_child(Atmosphere.new())

	_spawn_caipora()
	_spawn_enemy()
	_start_caipora_turn()

func _update_camera_fit() -> void:
	# Zoom "contain": encaixa STAGE_SIZE na viewport sem cortar a ação. Em paisagem o
	# limite é a altura (ação grande, leve folga lateral); em retrato cabe inteiro.
	var vp := get_viewport().get_visible_rect().size
	var z: float = minf(vp.x / STAGE_SIZE.x, vp.y / STAGE_SIZE.y) * STAGE_FILL
	z = clampf(z, 0.5, 2.0)
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
	_apply_weapon_visual()

func _on_caipora_health_changed(new_health: float, max_health: float) -> void:
	SignalBus.caipora_health_changed.emit(new_health, max_health)

func _apply_weapon_visual() -> void:
	if MetaProgression.get_upgrade_level("forca_3") < 1:
		return
	var animated_sprite := _caipora.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		return
	var weapon := Sprite2D.new()
	weapon.name = "WeaponSprite"
	weapon.texture = preload("res://assets/sprites/weapon_forca3.png")
	weapon.position = Vector2(28, -8)
	weapon.z_index = 1
	animated_sprite.add_child(weapon)

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
	if _combat_over or not _both_alive():
		return
	_is_double_attack = randf() < Constants.TIMING_DOUBLE_CHANCE
	_sfx.play(_sfx.attack_sound)
	_first_bubble_pos = _enemy.position + Vector2(0, -78)
	var atk_window: float = _phase_window(Constants.TIMING_WINDOW_ATTACK)
	_timing_bubble.show_bubble(
		_first_bubble_pos,
		atk_window,
		Constants.TIMING_PERFECT_START,
		Constants.TIMING_PERFECT_END,
		false, Color.TRANSPARENT, "up"
	)
	if _is_double_attack:
		var total: float = Constants.TIMING_DOUBLE_INTERVAL + atk_window
		var p1s: float = Constants.TIMING_PERFECT_START * atk_window / total
		var p1e: float = Constants.TIMING_PERFECT_END * atk_window / total
		var p2s: float = (Constants.TIMING_DOUBLE_INTERVAL + Constants.TIMING_PERFECT_START * atk_window) / total
		var p2e: float = (Constants.TIMING_DOUBLE_INTERVAL + Constants.TIMING_PERFECT_END * atk_window) / total
		_timing_system.open_window(total, p1s, p1e, true, p2s, p2e, "ui_up", "ui_right")
		_timing_system.timing_first_hit.connect(_on_double_first_hit)
		_timing_system.timing_result.connect(_on_double_final_result)
		get_tree().create_timer(Constants.TIMING_DOUBLE_INTERVAL).timeout.connect(_spawn_second_bubble)
	else:
		_timing_system.open_window(
			atk_window,
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
		_phase_window(Constants.TIMING_WINDOW_ATTACK),
		Constants.TIMING_PERFECT_START,
		Constants.TIMING_PERFECT_END,
		false, Color.TRANSPARENT, "right"
	)

func _on_double_first_hit() -> void:
	if _combat_over:
		return
	_timing_system.timing_first_hit.disconnect(_on_double_first_hit)
	_timing_bubble.burst_success()
	var damage := _caipora.execute_attack(false)
	_enemy.take_damage(damage)
	_sfx.play(_sfx.hit_sound)
	_feedback.trigger_screenshake(13.0, 0.3)
	_feedback.spawn_bubble_burst(_timing_bubble.position, Constants.COLOR_TELEGRAPH_ENEMY)
	_feedback.trigger_hit_stop(3)

func _on_double_final_result(result: TimingSystem.TimingResult) -> void:
	if _combat_over:
		return
	_timing_system.timing_result.disconnect(_on_double_final_result)
	if _timing_system.timing_first_hit.is_connected(_on_double_first_hit):
		_timing_system.timing_first_hit.disconnect(_on_double_first_hit)
	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble_b.burst_success()
		var damage := _caipora.execute_attack(false)
		_enemy.take_damage(damage)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(22.0, 0.5)
		_feedback.spawn_bubble_burst(_timing_bubble_b.position, Constants.COLOR_TELEGRAPH_ENEMY)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(4)
	else:
		_timing_bubble.burst_fail()
		_timing_bubble_b.burst_fail()
		_feedback.spawn_fail_particles(_timing_bubble_b.position)
		_feedback.trigger_screenshake(6.0, 0.18)
		_sfx.play(_sfx.ui_click_sound, -6.0)
	if _enemy.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_enemy_turn()

func _on_attack_timing_result(result: TimingSystem.TimingResult) -> void:
	if _combat_over:
		return
	_timing_system.timing_result.disconnect(_on_attack_timing_result)
	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble.burst_success()
		var damage := _caipora.execute_attack(true)
		_enemy.take_damage(damage)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(26.0, 0.55)
		_feedback.spawn_bubble_burst(_timing_bubble.position, Constants.COLOR_TELEGRAPH_ENEMY)
		_feedback.spawn_critical_particles(_enemy.position)
		_feedback.trigger_hit_stop(6)
	else:
		_timing_bubble.burst_fail()
		_feedback.spawn_fail_particles(_timing_bubble.position)
		_feedback.trigger_screenshake(6.0, 0.18)
		_sfx.play(_sfx.ui_click_sound, -6.0)
	if _enemy.health.is_alive():
		await get_tree().create_timer(_caipora.attack_cooldown).timeout
		_start_enemy_turn()

# ─── Turno do Inimigo (Defesa) ─────────────────────
func _start_enemy_turn() -> void:
	if _combat_over or not _both_alive():
		return
	_boss_special_hit_index = 0
	_last_boss_bubble_pos = Vector2(-999.0, -999.0)
	_active_enemy_pattern = _enemy.get_attack_pattern()
	_enemy.state_machine.start_pattern(_active_enemy_pattern)

func _on_enemy_attack_started() -> void:
	if not _both_alive():
		return
	var window: float = _phase_window(_active_enemy_pattern.attack_duration)
	if _timing_system.timing_result.is_connected(_on_defense_timing_result):
		_timing_system.timing_result.disconnect(_on_defense_timing_result)
	_timing_system.timing_result.connect(_on_defense_timing_result)
	var is_special: bool = _active_enemy_pattern.is_special
	var action: String
	var hint: String
	if is_special:
		var seq: Array[String] = _active_enemy_pattern.input_sequence
		var hint_map: Dictionary = {
			"ui_right": "right", "ui_left": "left",
			"ui_up": "up", "ui_down": "down"
		}
		var idx := clampi(_boss_special_hit_index, 0, seq.size() - 1)
		action = seq[idx] if not seq.is_empty() else "ui_down"
		hint = hint_map.get(action, "down")
		_boss_special_hit_index += 1
	else:
		action = "ui_down"
		hint = "down"
	var bubble_pos: Vector2 = _boss_spread_pos() if is_special else _caipora.position + Vector2(0, -70)
	var vuln: Color = BOSS_BUBBLE_COLOR if is_special else Color.TRANSPARENT
	_timing_bubble.show_bubble(bubble_pos, window, Constants.TIMING_PERFECT_START, Constants.TIMING_PERFECT_END, true, vuln, hint)
	_timing_system.open_window(window, Constants.TIMING_PERFECT_START, Constants.TIMING_PERFECT_END, false, 0.0, 0.0, action)

func _on_defense_timing_result(result: TimingSystem.TimingResult) -> void:
	if _combat_over:
		return
	_timing_system.timing_result.disconnect(_on_defense_timing_result)

	if result == TimingSystem.TimingResult.PERFECT:
		_timing_bubble.burst_success()
		_caipora.dodge_performed.emit()
		_sfx.play(_sfx.dodge_sound)
		_sfx.play(_sfx.timing_perfect_sound, -4.0)
		_feedback.trigger_screenshake(22.0, 0.5)
		_feedback.spawn_bubble_burst(_timing_bubble.position, Constants.COLOR_PARTICLE_DODGE)
		_feedback.spawn_dodge_particles(_caipora.position)
		_feedback.trigger_hit_stop(5)
	else:
		_timing_bubble.burst_fail()
		var damage := _enemy.execute_attack(false, _active_enemy_pattern.damage_multiplier)
		_caipora.take_damage(damage)
		_sfx.play(_sfx.hit_sound)
		_feedback.trigger_screenshake(14.0, 0.35)
		_feedback.spawn_fail_particles(_timing_bubble.position)
		_feedback.spawn_blood_particles(_caipora.position)
		_feedback.trigger_hit_stop(2)

func _on_enemy_pattern_finished() -> void:
	if not _combat_over and _both_alive():
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

func _phase_window(base: float) -> float:
	if GameState.active_phase == 3:
		return maxf(base - Constants.PHASE3_TIMING_REDUCTION, 0.2)
	return base

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

# ─── Feedback por input ────────────────────────────
## Resposta tátil imediata a qualquer ação na janela (mesmo fora da zona perfeita).
## O feedback forte do acerto (crítico/esquiva) é empilhado por cima nos handlers.
func _on_input_registered() -> void:
	_feedback.trigger_screenshake(2.5, 0.08)
	_sfx.play(_sfx.ui_click_sound, -6.0)

func _on_hit_stop_started(_duration: float) -> void:
	_timing_bubble.set_frozen(true)
	_timing_bubble_b.set_frozen(true)
	if _caipora != null and is_instance_valid(_caipora):
		_caipora.animated_sprite.speed_scale = 0.0
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.animated_sprite.speed_scale = 0.0

func _on_hit_stop_ended() -> void:
	_timing_bubble.set_frozen(false)
	_timing_bubble_b.set_frozen(false)
	if _caipora != null and is_instance_valid(_caipora):
		_caipora.animated_sprite.speed_scale = 1.0
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.animated_sprite.speed_scale = 1.0

# ─── Morte ─────────────────────────────────────────
func _on_actor_died(actor: CombatActor) -> void:
	# Idempotente: a morte encerra o combate exatamente uma vez. Qualquer segundo `died`
	# (ou reentrância) é ignorado.
	if _combat_over:
		return
	_combat_over = true
	var caipora_won := actor == _enemy
	# Derruba TODO o estado de combate ANTES de qualquer await: fecha a janela de timing,
	# desconecta os handlers (impede que o ataque duplo reentre e toque o _enemy já
	# liberado pelo tween de morte) e restaura os sprites congelados pelo hit-stop.
	_teardown_combat()
	if caipora_won:
		_caipora.health.max_health += 1
		_caipora.health.heal(1)
		GameState.caipora_max_hp = _caipora.health.max_health
		if not GameState.active_combat_is_boss:
			match GameState.active_phase:
				3: MetaProgression.add_fragments(2.0)
				2: MetaProgression.add_fragments(1.5)
				_: MetaProgression.add_fragment()
		if GameState.active_combat_is_boss and GameState.active_phase == 2:
			if MetaProgression.phase_reached < 3:
				MetaProgression.phase_reached = 3
				MetaProgression.save_progress()
	GameState.caipora_current_hp = maxf(0.0, _caipora.health.current_health)
	_sfx.play(_sfx.death_sound)
	_feedback.spawn_death_particles(actor.position)
	_feedback.trigger_screenshake(26.0, 0.7)

	SignalBus.arena_exited.emit(caipora_won)
	var next_screen := _resolve_next_screen(caipora_won)
	# Watchdog: rede de segurança que garante a transição caso o caminho normal abaixo
	# seja preemptado por algum motivo. _do_screen_change é idempotente, então o primeiro
	# a disparar vence. (NÃO cobre engine-halt — ver plano.)
	get_tree().create_timer(1.5, true).timeout.connect(_do_screen_change.bind(next_screen, caipora_won))
	await get_tree().create_timer(0.6).timeout
	_do_screen_change(next_screen, caipora_won)

## Encerra o combate de forma síncrona: fecha a janela de timing, desconecta todos os
## handlers de resultado/primeiro-hit, para a state machine do inimigo e limpa o hit-stop
## (restaurando speed_scale). Chamado uma vez, no início de _on_actor_died, antes de awaits.
func _teardown_combat() -> void:
	_timing_system.close_window()
	_disconnect_timing(_on_attack_timing_result)
	_disconnect_timing(_on_double_final_result)
	_disconnect_timing(_on_defense_timing_result)
	if _timing_system.timing_first_hit.is_connected(_on_double_first_hit):
		_timing_system.timing_first_hit.disconnect(_on_double_first_hit)
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.state_machine.stop()
	_feedback.force_clear_hit_stop()
	if _caipora != null and is_instance_valid(_caipora):
		_caipora.animated_sprite.speed_scale = 1.0
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.animated_sprite.speed_scale = 1.0

func _disconnect_timing(callable: Callable) -> void:
	if _timing_system.timing_result.is_connected(callable):
		_timing_system.timing_result.disconnect(callable)

## Tela-alvo após o combate (puro, sem efeitos colaterais). Preserva exatamente o
## comportamento anterior por fase/boss.
func _resolve_next_screen(caipora_won: bool) -> SignalBus.Screen:
	if not caipora_won:
		return SignalBus.Screen.GAME_OVER
	if GameState.active_combat_is_boss:
		match GameState.active_phase:
			3: return SignalBus.Screen.ENDING
			1: return SignalBus.Screen.EXPLORATION
			_: return SignalBus.Screen.EXPLORATION_PHASE3
	match GameState.active_phase:
		3: return SignalBus.Screen.EXPLORATION_PHASE3
		2: return SignalBus.Screen.EXPLORATION_PHASE2
		_: return SignalBus.Screen.EXPLORATION

## Executa a troca de tela uma única vez (caminho normal OU watchdog). Registra o inimigo
## derrotado apenas em vitórias que voltam à exploração (não no ENDING).
func _do_screen_change(screen: SignalBus.Screen, caipora_won: bool) -> void:
	if _screen_changed:
		return
	_screen_changed = true
	if caipora_won and screen != SignalBus.Screen.ENDING:
		GameState.defeated_enemy_ids.append(GameState.active_map_enemy_id)
	GameState.change_screen(screen)
