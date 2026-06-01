# AGENTS.md — scripts/

This folder contains all GDScript (`.gd`) source files.

## Structure

```
scripts/
  core/        — Autoloads (GameState, SignalBus, MetaProgression)
  systems/     — Game systems (TimingSystem, CombatSystem, FeedbackSystem)
  entities/    — Player and Enemy classes
  exploration/ — Grid logic, TurnManager
  arena/       — ArenaManager, attack patterns
  utils/       — Helpers, constants
```

## Rules

1. **One class per file.** File name matches class name in `snake_case`.
2. **Use `class_name` on every script.** This enables type hints and `preload()` across the project.
3. **Autoloads go in `core/`.** Register them in `Project Settings > Autoloads`.
4. **Systems in `systems/` are stateless services.** They process data but do not own game objects. Prefer `Node` or plain classes over `Node2D`.
5. **Entities in `entities/` are game objects.** They extend `CharacterBody2D`, `Area2D`, or `Node2D`.
6. **State machines:** If an entity has multiple behaviors, use a `StateMachine` node with child `State` scripts.

## State Machine Pattern

```gdscript
# scripts/entities/player/states/player_explore_state.gd
class_name PlayerExploreState
extends State

func enter() -> void:
    pass

func physics_process(delta: float) -> void:
    # handle movement
    pass

func exit() -> void:
    pass
```

The state machine transitions are triggered by signals, not direct calls:
```gdscript
# In Player entity
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
    SignalBus.arena_entered.connect(_on_arena_entered)

func _on_arena_entered() -> void:
    state_machine.transition_to("PlayerCombatState")
```

## Autoload Access

Use autoloads for cross-system communication. Never use `get_node("/root/...")` to find autoloads — they are globally accessible:

```gdscript
# Correct
SignalBus.health_changed.emit(new_health)
GameState.current_screen = GameState.Screen.ARENA

# Incorrect
get_node("/root/SignalBus").health_changed.emit(new_health)
```
