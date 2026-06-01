class_name ArenaManager
extends Node2D

@export var caipora_combat_scene: PackedScene
@export var criatura_scene: PackedScene

var _caipora: CombatActor
var _criatura: CombatActor

func _ready() -> void:
    _spawn_caipora()
    _spawn_criatura()
    _start_combat()

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

func _start_combat() -> void:
    # Inicia o ciclo de combate: Caipora ataca primeiro
    _caipora.attack_ready.emit()

func _on_actor_died(actor: CombatActor) -> void:
    var caipora_won := actor == _criatura
    SignalBus.arena_exited.emit(caipora_won)
    if caipora_won:
        GameState.change_screen(SignalBus.Screen.WIN)
    else:
        GameState.change_screen(SignalBus.Screen.GAME_OVER)
