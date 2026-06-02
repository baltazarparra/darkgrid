class_name AttackPattern
extends Resource

## Dado puro que descreve o ritmo de ataque de um inimigo.
## Salvo como .tres e consumido pela EnemyStateMachine — permite criar novos
## padrões (Criatura, Boss, futuros inimigos) sem tocar em código.

@export var idle_duration: float = 0.3
@export var wind_up_duration: float = 0.5
@export var attack_duration: float = 1.0
@export var cooldown_duration: float = 2.0
@export var damage_multiplier: float = 1.0
@export var is_special: bool = false

## Multi-strike (Boss): número de golpes consecutivos por pattern.
@export var strike_count: int = 1
## Telegraph mais curto usado entre golpes consecutivos (golpes 2..N).
@export var strike_delay: float = 0.4
