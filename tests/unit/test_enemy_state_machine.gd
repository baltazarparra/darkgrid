extends GutTest

var _sm: EnemyStateMachine
var _pattern: AttackPattern

func before_each():
    _sm = EnemyStateMachine.new()
    _pattern = AttackPattern.new()
    _pattern.idle_duration = 0.1
    _pattern.wind_up_duration = 0.1
    _pattern.attack_duration = 0.1
    _pattern.cooldown_duration = 0.1
    _pattern.strike_delay = 0.1
    add_child_autofree(_sm)

func test_idle_to_windup_transition():
    _sm.start_pattern(_pattern)
    var state: Array = [EnemyStateMachine.State.IDLE]
    _sm.state_changed.connect(func(s): state[0] = s)
    await get_tree().create_timer(0.15).timeout
    assert_eq(state[0], EnemyStateMachine.State.WIND_UP)

func test_full_cycle_idle_windup_attack_cooldown():
    _sm.start_pattern(_pattern)
    var states: Array = []
    _sm.state_changed.connect(func(s): states.append(s))
    await get_tree().create_timer(0.45).timeout
    assert_eq(states.size(), 3)
    assert_eq(states[0], EnemyStateMachine.State.WIND_UP)
    assert_eq(states[1], EnemyStateMachine.State.ATTACK)
    assert_eq(states[2], EnemyStateMachine.State.COOLDOWN)

func test_pattern_finished_emitted_after_cooldown():
    _sm.start_pattern(_pattern)
    var finished: Array = [false]
    _sm.pattern_finished.connect(func(): finished[0] = true)
    await get_tree().create_timer(0.5).timeout
    assert_true(finished[0])

func test_multi_strike_opens_multiple_attacks():
    _pattern.strike_count = 3
    _sm.start_pattern(_pattern)
    var attacks: Array = [0]
    _sm.attack_started.connect(func(): attacks[0] += 1)
    # idle(0.1) + 3x [windup(0.1) + attack(0.1)] + cooldown — folga generosa
    await get_tree().create_timer(0.9).timeout
    assert_eq(attacks[0], 3)
