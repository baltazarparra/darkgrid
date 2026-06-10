class_name SfxSystem
extends Node

## Reproduz SFX de combate. Cada som toca num AudioStreamPlayer descartável (bus "SFX"),
## permitindo sobreposição (ex: hit + timing_perfect) sem pool dedicado.
##
## Variação anti-repetição: no _ready, descobre variantes por convenção de nome
## (hit.wav -> hit_2.wav, hit_3.wav) via ResourceLoader.exists e faz round-robin entre
## elas a cada play, com leve jitter de pitch/volume. A API play() é a mesma — o
## arena_manager continua chamando _sfx.play(_sfx.hit_sound, vol) sem saber das variantes.

# ─── Constants ─────────────────────────────────────
const SFX_BUS: String = "SFX"
const SFX_DIR: String = "res://assets/audio/sfx"
const MAX_VARIANTS: int = 8
const PITCH_JITTER: float = 0.05  # ±5%
const VOLUME_JITTER_DB: float = 1.0  # ±1 dB

# ─── Exports ───────────────────────────────────────
@export var attack_sound: AudioStream
@export var hit_sound: AudioStream
@export var dodge_sound: AudioStream
@export var timing_perfect_sound: AudioStream
@export var timing_alert_sound: AudioStream
@export var death_sound: AudioStream
@export var ui_click_sound: AudioStream

# ─── State ─────────────────────────────────────────
## resource_path do som primário -> Array[AudioStream] de variantes (inclui o primário).
var _variants: Dictionary = {}
## resource_path -> índice atual do round-robin.
var _rr_index: Dictionary = {}
## nome (play_named) -> stream primário resolvido (ou null se o asset não existe).
var _named: Dictionary = {}

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	for sound in [attack_sound, hit_sound, dodge_sound, timing_perfect_sound,
			timing_alert_sound, death_sound, ui_click_sound]:
		_register_variants(sound)

func _register_variants(primary: AudioStream) -> void:
	if primary == null or primary.resource_path.is_empty():
		return
	var key := primary.resource_path
	if _variants.has(key):
		return
	var list: Array[AudioStream] = [primary]
	var base := key.get_basename()  # tira .wav
	var ext := "." + key.get_extension()
	for i in range(2, MAX_VARIANTS + 1):
		var path := "%s_%d%s" % [base, i, ext]
		if ResourceLoader.exists(path):
			list.append(load(path))
		else:
			break
	_variants[key] = list
	_rr_index[key] = 0

# ─── Public API ────────────────────────────────────
func play(sound: AudioStream, volume_db: float = 0.0) -> void:
	if sound == null:
		return
	var to_play := _next_variant(sound)
	var player := AudioStreamPlayer.new()
	player.stream = to_play
	player.bus = SFX_BUS
	player.volume_db = volume_db + randf_range(-VOLUME_JITTER_DB, VOLUME_JITTER_DB)
	player.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

## Toca um SFX por nome de arquivo (sem export): "hurt_caipora" -> sfx/hurt_caipora.wav.
## Resolve com ResourceLoader.exists e cacheia; asset ausente é no-op silencioso
## (fallback fica no chamador). Devolve true se tocou.
func play_named(sound_name: String, volume_db: float = 0.0) -> bool:
	if not _named.has(sound_name):
		var path := "%s/%s.wav" % [SFX_DIR, sound_name]
		var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
		_named[sound_name] = stream
		_register_variants(stream)
	var primary: AudioStream = _named[sound_name]
	if primary == null:
		return false
	play(primary, volume_db)
	return true

# ─── Private helpers ───────────────────────────────
## Round-robin entre as variantes do som; se não houver registro, devolve o próprio.
func _next_variant(sound: AudioStream) -> AudioStream:
	var key := sound.resource_path
	if not _variants.has(key):
		return sound
	var list: Array = _variants[key]
	if list.size() <= 1:
		return sound
	var idx: int = (_rr_index[key] + 1) % list.size()
	_rr_index[key] = idx
	return list[idx]
