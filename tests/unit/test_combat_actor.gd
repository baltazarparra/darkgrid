extends GutTest

var _actor: CombatActor

func before_each():
    _actor = preload("res://scenes/arena/criatura.tscn").instantiate()
    add_child_autofree(_actor)  # add_child dispara _ready e resolve os @onready

func test_critical_damage_multiplier():
    _actor.base_attack_damage = 10
    _actor.critical_multiplier = 2.5
    var received_damage: Array = [0]
    var was_critical: Array = [false]
    _actor.attack_executed.connect(func(d, c): received_damage[0] = d; was_critical[0] = c)
    _actor.execute_attack(true)
    assert_eq(received_damage[0], 25.0)
    assert_true(was_critical[0])

func test_normal_damage_without_critical():
    _actor.base_attack_damage = 10
    var received_damage: Array = [0]
    var was_critical: Array = [true]
    _actor.attack_executed.connect(func(d, c): received_damage[0] = d; was_critical[0] = c)
    _actor.execute_attack(false)
    assert_eq(received_damage[0], 10.0)
    assert_false(was_critical[0])

func test_death_signal_emitted():
    var died: Array = [false]
    _actor.health.died.connect(func(): died[0] = true)
    _actor.take_damage(100)
    assert_true(died[0])
    assert_false(_actor.health.is_alive())

func test_cooldown_blocks_attack_ready():
    var ready_count: Array = [0]
    _actor.attack_ready.connect(func(): ready_count[0] += 1)
    _actor.execute_attack(false)
    assert_eq(ready_count[0], 0)  # cooldown ativo, attack_ready não emitido
    await get_tree().create_timer(_actor.attack_cooldown + 0.1).timeout
    assert_eq(ready_count[0], 1)  # cooldown terminou, attack_ready emitido
