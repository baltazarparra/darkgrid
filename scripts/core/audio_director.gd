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

## Trim global aplicado sobre o Master, por cima do volume do usuário. -6 dB ≈ metade
## da amplitude linear (jogo 50% mais baixo) sem mexer no slider nem na persistência.
const MASTER_TRIM_DB: float = -6.0

const AMBIENCE_FADE: float = 1.2
const DUCK_AMOUNT_DB: float = -8.0
const DUCK_TIME: float = 0.35

const MUSIC_FADE: float = 0.9

# Caminhos dos loops (carregados só se existirem — graceful).
const AMB_FOREST: String = "res://assets/audio/ambience/amb_forest.wav"
const AMB_RIVER: String = "res://assets/audio/ambience/amb_river.wav"
const AMB_DREAD: String = "res://assets/audio/ambience/amb_dread.wav"

# Stems de maracatu (loops sincronizados) e seu volume-alvo no mix.
const MUSIC_DIR: String = "res://assets/audio/music/"
const STEM_ALFAIA: String = "mar_alfaia"
const STEM_GANZA: String = "mar_ganza"
const STEM_AGOGO: String = "mar_agogo"
const STEM_TARGET_DB: Dictionary = {
	STEM_ALFAIA: 0.0, STEM_GANZA: -3.0, STEM_AGOGO: -2.0
}

# Stingers de estado (one-shot).
const STING_DIR: String = "res://assets/audio/stingers/"
const STING_ARENA: String = "sting_arena_enter"
const STING_VICTORY: String = "sting_victory"
const STING_GAME_OVER: String = "sting_game_over"
const STING_CHEST: String = "sting_chest"

# ─── State ─────────────────────────────────────────
## Volume linear (0..1) alvo por bus — fonte da verdade que o ducking respeita.
var _bus_volume: Dictionary = {
	BUS_MASTER: 1.0, BUS_SFX: 1.0, BUS_MUSIC: 0.8, BUS_AMBIENCE: 0.8
}
var _audio_unlocked: bool = false
var _music_enabled: bool = true
var _ambience_player: AudioStreamPlayer
var _current_ambience: String = ""
var _duck_tween: Tween
## name do stem -> AudioStreamPlayer (bus Music). Tocam em fase.
var _stem_players: Dictionary = {}
var _maracatu_on: bool = false
var _stinger_player: AudioStreamPlayer

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # áudio segue durante pause/hit-stop

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	for stem in STEM_TARGET_DB:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_MUSIC
		p.volume_db = -40.0
		add_child(p)
		_stem_players[stem] = p

	_stinger_player = AudioStreamPlayer.new()
	_stinger_player.bus = BUS_MUSIC
	add_child(_stinger_player)

	_load_settings()
	_apply_all_volumes()

	SignalBus.screen_changed.connect(_on_screen_changed)
	SignalBus.chest_opened.connect(_on_chest_opened)

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

# ─── Public API: music toggle ─────────────────────
func toggle_music_ambience() -> void:
	_music_enabled = not _music_enabled
	_apply_volume(BUS_MUSIC)
	_apply_volume(BUS_AMBIENCE)
	_save_settings()

func is_music_enabled() -> bool:
	return _music_enabled

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
		if not _music_enabled:
			continue  # já silenciado pelo toggle; não restaurar
		AudioServer.set_bus_volume_db(idx, _linear_to_db(_bus_volume[bus_name]) + amount_db * t)

# ─── Public API: autoplay unlock ───────────────────
## Chamar no 1º gesto do usuário (clique "Iniciar"). Libera o áudio no browser e
## inicia a ambiência da tela atual.
func unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	_apply_screen_audio(GameState.current_screen)

# ─── Reação às telas ───────────────────────────────
func _on_screen_changed(new_screen: int) -> void:
	if _audio_unlocked:
		_apply_screen_audio(new_screen)

## Casa ambiência, maracatu e stinger ao estado da tela.
func _apply_screen_audio(screen: int) -> void:
	_refresh_ambience(screen)
	if screen == SignalBus.Screen.ARENA:
		_start_maracatu(GameState.active_combat_is_boss)
		_play_stinger(STING_ARENA)
	else:
		_stop_maracatu()
	match screen:
		SignalBus.Screen.WIN:
			_play_stinger(STING_VICTORY)
		SignalBus.Screen.GAME_OVER:
			_play_stinger(STING_GAME_OVER)

func _on_chest_opened() -> void:
	if _audio_unlocked:
		_play_stinger(STING_CHEST)

# ─── Ambiência ─────────────────────────────────────
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
			_fade_player(_ambience_player, -40.0, true)
		return
	var stream: AudioStream = load(path)
	_force_loop(stream)
	_ambience_player.stream = stream
	_ambience_player.volume_db = -40.0
	_ambience_player.play()
	# Player em 0 dB (cheio); o volume do usuário vive no bus Ambience.
	_fade_player(_ambience_player, 0.0, false)

# ─── Maracatu adaptativo ───────────────────────────
## Inicia os stems em fase (alfaia+ganzá; +agogô no boss). Reinicia do compasso 1.
func _start_maracatu(boss: bool) -> void:
	_maracatu_on = true
	_play_stem(STEM_ALFAIA, true)
	_play_stem(STEM_GANZA, true)
	_play_stem(STEM_AGOGO, boss)  # silencioso fora do boss

func _stop_maracatu() -> void:
	if not _maracatu_on:
		return
	_maracatu_on = false
	for stem in _stem_players:
		var p: AudioStreamPlayer = _stem_players[stem]
		if p.playing:
			_fade_player(p, -40.0, true)

func _play_stem(stem: String, audible: bool) -> void:
	var p: AudioStreamPlayer = _stem_players[stem]
	if p.stream == null:
		var path := MUSIC_DIR + stem + ".wav"
		if not ResourceLoader.exists(path):
			return
		var s: AudioStream = load(path)
		_force_loop(s)
		p.stream = s
	p.stop()
	p.volume_db = -40.0
	p.play()
	if audible:
		_fade_player(p, STEM_TARGET_DB[stem], false)

# ─── Stingers ──────────────────────────────────────
func _play_stinger(name: String) -> void:
	var path := STING_DIR + name + ".wav"
	if not ResourceLoader.exists(path):
		return
	_stinger_player.stream = load(path)
	_stinger_player.volume_db = 0.0
	_stinger_player.play()

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
	if (bus_name == BUS_MUSIC or bus_name == BUS_AMBIENCE) and not _music_enabled:
		AudioServer.set_bus_volume_db(idx, -80.0)
		return
	var db := _linear_to_db(_bus_volume[bus_name])
	if bus_name == BUS_MASTER:
		db += MASTER_TRIM_DB
	AudioServer.set_bus_volume_db(idx, db)

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
	if cfg.has_section_key(SETTINGS_SECTION, "music_enabled"):
		_music_enabled = cfg.get_value(SETTINGS_SECTION, "music_enabled")

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # preserva outras seções, se houver
	for bus_name in VOLUME_BUSES:
		cfg.set_value(SETTINGS_SECTION, bus_name, _bus_volume[bus_name])
	cfg.set_value(SETTINGS_SECTION, "music_enabled", _music_enabled)
	cfg.save(SETTINGS_PATH)
