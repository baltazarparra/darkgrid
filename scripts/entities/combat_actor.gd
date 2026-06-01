class_name CombatActor
extends CharacterBody2D

signal attack_ready
signal attack_executed(damage: int, is_critical: bool)
signal dodge_performed

@onready var health: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var base_attack_damage: int = Constants.DAMAGE_BASE
@export var attack_cooldown: float = Constants.ATTACK_COOLDOWN_SECONDS
@export var critical_multiplier: float = Constants.DAMAGE_CRIT_MULTIPLIER

var _attack_timer: Timer
var _can_attack: bool = true

func _ready() -> void:
    _attack_timer = Timer.new()
    _attack_timer.one_shot = true
    _attack_timer.wait_time = attack_cooldown
    _attack_timer.timeout.connect(_on_attack_cooldown_ready)
    add_child(_attack_timer)

func start_attack_window() -> void:
    pass

func execute_attack(is_critical: bool = false, multiplier_override: float = 0.0) -> void:
    var damage := base_attack_damage
    if is_critical:
        if multiplier_override > 0.0:
            damage = int(damage * multiplier_override)
        else:
            damage = int(damage * critical_multiplier)
    attack_executed.emit(damage, is_critical)
    _can_attack = false
    _attack_timer.start()

func _on_attack_cooldown_ready() -> void:
    _can_attack = true
    attack_ready.emit()

func take_damage(amount: int) -> void:
    health.take_damage(amount)
