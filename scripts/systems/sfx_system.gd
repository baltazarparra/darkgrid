class_name SfxSystem
extends Node

## Reproduz SFX de combate. Cada som toca num AudioStreamPlayer descartável,
## permitindo sobreposição (ex: hit + timing_perfect) sem pool dedicado.

@export var attack_sound: AudioStream
@export var hit_sound: AudioStream
@export var dodge_sound: AudioStream
@export var timing_perfect_sound: AudioStream
@export var timing_alert_sound: AudioStream
@export var death_sound: AudioStream
@export var ui_click_sound: AudioStream

func play(sound: AudioStream, volume_db: float = 0.0) -> void:
	if sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
