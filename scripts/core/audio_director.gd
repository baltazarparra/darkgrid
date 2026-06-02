extends Node

## Maestro de áudio persistente (autoload). Diferente do SfxSystem/FeedbackSystem
## (que são por-arena), o AudioDirector vive entre telas e cuida de:
##  - volume dos buses (Master/SFX/Music/Ambience) + persistência em user://settings.cfg
##  - ambiência e música (stems de maracatu) com cross-fade por tela
##  - ducking de Music/Ambience em impactos pesados
##  - unlock de autoplay no HTML5 (1º play só após gesto do usuário)
##
## Os assets de ambiência/música chegam nas Fases C/D; aqui o carregamento é graceful
## (ResourceLoader.exists), então os hooks já existem mas ficam dormentes sem os .wav.

# ─── Constants ─────────────────────────────────────
const SETTINGS_PATH: String = "user://settings.cfg"
const SETTINGS_SECTION: String = "audio"

const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const BUS_MUSIC: String = "Music"
const BUS_AMBIENCE: String = "Ambience"
const VOLUME_BUSES: PackedStringArray = [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_AMBIENCE]

const AMBIENCE_FADE: float = 1.2
const DUCK_AMOUNT_DB: float = -8.0
const DUCK_TIME: float = 0.35

# Caminhos dos loops (gerados nas Fases C/D). Carregados só se existirem.
const AMB_FOREST: String = "res://assets/audio/ambience/amb_forest.wav"
const AMB_RIVER: String = "res://assets/audio/ambience/amb_river.wav"
const AMB_DREAD: String = "res://assets/audio/ambience/amb_dread.wav"

# ─── State ─────────────────────────────────────────
## Volume linear (0..1) alvo por bus — fonte da verdade que o ducking respeita.
var _bus_volume: Dictionary = {
	BUS_MASTER: 1.0, BUS_SFX: 1.0, BUS_MUSIC: 0.8, BUS_AMBIENCE: 0.8
}
var _audio_unlocked: bool = false
var _ambience_player: AudioStreamPlayer
var _current_ambience: String = ""
var _duck_tween: Tween

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # áudio segue durante pause/hit-stop

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	_load_settings()
	_apply_all_volumes()

	SignalBus.screen_changed.connect(_on_screen_changed)
	SignalBus.arena_exited.connect(_on_arena_exited)

# ─── Public API: volume ────────────────────────────
## Define o volume linear (0..1) de um bus, aplica e persiste.
func set_bus_volume(bus_name: String, linear: float) -> void:
	if not _bus_volume.has(bus_name):
		return
	_bus_volume[bus_name] = clampf(linear, 0.0, 1.0)
	_apply_volume(bus_name)
	_save_settings()

func get_bus_volume(bus_name: String) -> float:
	return _bus_volume.get(bus_name, 1.0)

# ─── Public API: ducking ───────────────────────────
## Abaixa Music+Ambience por um instante (impactos/hit-stop) e recupera com tween.
func duck(amount_db: float = DUCK_AMOUNT_DB, secs: float = DUCK_TIME) -> void:
	if _duck_tween != null and _duck_tween.is_running():
		_duck_tween.kill()
	# Tween não tem property-path no AudioServer, então animamos um fator 0..1 por método:
	# desce rápido, segura, volta ao alvo do usuário.
	_duck_tween = create_tween()
	_duck_tween.tween_method(_duck_apply.bind(amount_db), 0.0, 1.0, secs * 0.25)
	_duck_tween.tween_interval(secs * 0.4)
	_duck_tween.tween_method(_duck_apply.bind(amount_db), 1.0, 0.0, secs * 0.35)

func _duck_apply(t: float, amount_db: float) -> void:
	for bus_name in [BUS_MUSIC, BUS_AMBIENCE]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			continue
		AudioServer.set_bus_volume_db(idx, _linear_to_db(_bus_volume[bus_name]) + amount_db * t)

# ─── Public API: autoplay unlock ───────────────────
## Chamar no 1º gesto do usuário (clique "Iniciar"). Libera o áudio no browser e
## inicia a ambiência da tela atual.
func unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	_refresh_ambience(GameState.current_screen)

# ─── Ambiência ─────────────────────────────────────
func _on_screen_changed(new_screen: int) -> void:
	if _audio_unlocked:
		_refresh_ambience(new_screen)

func _on_arena_exited(_won: bool) -> void:
	pass  # a troca de ambiência segue pelo screen_changed que vem em seguida

func _refresh_ambience(screen: int) -> void:
	var path := ""
	match screen:
		SignalBus.Screen.EXPLORATION, SignalBus.Screen.HUB:
			path = AMB_FOREST
		SignalBus.Screen.ARENA:
			path = AMB_DREAD
		_:
			path = ""
	_play_ambience(path)

func _play_ambience(path: String) -> void:
	if path == _current_ambience:
		return
	_current_ambience = path
	if path == "" or not ResourceLoader.exists(path):
		# Sem asset (ainda) ou tela sem ambiência: fade-out e para.
		if _ambience_player.playing:
			_fade_player(_ambience_player, 0.0, true)
		return
	var stream: AudioStream = load(path)
	_force_loop(stream)
	_ambience_player.stream = stream
	_ambience_player.volume_db = -40.0
	_ambience_player.play()
	_fade_player(_ambience_player, _linear_to_db(_bus_volume[BUS_AMBIENCE]), false)

## Garante loop contínuo no asset. O .import é gitignored (regenera sem loop), então
## forçamos LOOP_FORWARD em runtime no AudioStreamWAV (mono 16-bit = 2 bytes/frame).
func _force_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2

func _fade_player(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, AMBIENCE_FADE)
	if stop_after:
		tween.tween_callback(player.stop)

# ─── Volume helpers ────────────────────────────────
func _apply_all_volumes() -> void:
	for bus_name in VOLUME_BUSES:
		_apply_volume(bus_name)

func _apply_volume(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, _linear_to_db(_bus_volume[bus_name]))

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0  # mute prático (evita -inf)
	return linear_to_db(linear)

# ─── Persistência ──────────────────────────────────
func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for bus_name in VOLUME_BUSES:
		if cfg.has_section_key(SETTINGS_SECTION, bus_name):
			_bus_volume[bus_name] = clampf(cfg.get_value(SETTINGS_SECTION, bus_name), 0.0, 1.0)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # preserva outras seções, se houver
	for bus_name in VOLUME_BUSES:
		cfg.set_value(SETTINGS_SECTION, bus_name, _bus_volume[bus_name])
	cfg.save(SETTINGS_PATH)
