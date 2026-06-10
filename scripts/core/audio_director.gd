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
const BUS_REVERB: String = "Reverb"
const VOLUME_BUSES: PackedStringArray = [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_AMBIENCE]

## Perfis do espaço acústico (bus Reverb, dry fixo em 1.0 — só o wet/sala variam).
## A folhagem da mata absorve (quase seco); a igreja de pedra responde; a clareira
## da arena fica no meio. Aplicado por tela em _apply_screen_audio.
const SPACE_PROFILES: Dictionary = {
	&"mata": {"room_size": 0.25, "wet": 0.05, "damping": 0.75, "predelay_msec": 10.0},
	&"igreja": {"room_size": 0.90, "wet": 0.35, "damping": 0.20, "predelay_msec": 40.0},
	&"arena": {"room_size": 0.55, "wet": 0.15, "damping": 0.50, "predelay_msec": 15.0},
}

## Trim global aplicado sobre o Master, por cima do volume do usuário. -6 dB ≈ metade
## da amplitude linear (jogo 50% mais baixo) sem mexer no slider nem na persistência.
const MASTER_TRIM_DB: float = -6.0

const AMBIENCE_FADE: float = 1.2
const DUCK_AMOUNT_DB: float = -8.0
const DUCK_TIME: float = 0.35
## Duck mais fundo no timing perfeito: o mundo cala para o crítico soar enorme.
const PERFECT_DUCK_DB: float = -14.0
const PERFECT_DUCK_SECS: float = 0.35

const MUSIC_FADE: float = 0.9

# Caminhos das ambiências (carregadas só se existirem — graceful). Uma por clima de fase.
const AMB_FOREST: String = "res://assets/audio/ambience/amb_forest.wav"
const AMB_DREAD: String = "res://assets/audio/ambience/amb_dread.wav"
const AMB_FIRE: String = "res://assets/audio/ambience/amb_fire.wav"
const AMB_FOG: String = "res://assets/audio/ambience/amb_fog.wav"
const AMB_CHURCH: String = "res://assets/audio/ambience/amb_church.wav"

# Música por contexto: um loop híbrido (maracatu + chiptune) por tela/fase/boss.
const MUSIC_DIR: String = "res://assets/audio/music/"

# Stingers de estado (one-shot).
const STING_DIR: String = "res://assets/audio/stingers/"
const STING_ARENA: String = "sting_arena_enter"
const STING_VICTORY: String = "sting_victory"
const STING_GAME_OVER: String = "sting_game_over"
const STING_CHEST: String = "sting_chest"
const STING_BOSS_INTRO: String = "sting_boss_intro"
const STING_CHAMA: String = "sting_chama"
# Fase 5 (A Igreja): sino de torre na revelação do Jesuíta, sibilo de água benta
# no telegraph do especial dele, estertor de órgão na vitória (tela ENDING).
const STING_SINO_IGREJA: String = "sting_sino_igreja"
const STING_AGUA_BENTA: String = "sting_agua_benta"
const STING_ORGAO_ESTERTOR: String = "sting_orgao_estertor"
const FINAL_PHASE: int = 5

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
## Par de players para crossfade de música (bus Music). _music_active é o que toca agora.
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer = null
var _current_music: String = ""
var _stinger_player: AudioStreamPlayer

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # áudio segue durante pause/hit-stop

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	_music_a = AudioStreamPlayer.new()
	_music_a.bus = BUS_MUSIC
	_music_a.volume_db = -40.0
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = BUS_MUSIC
	_music_b.volume_db = -40.0
	add_child(_music_b)

	_stinger_player = AudioStreamPlayer.new()
	_stinger_player.bus = BUS_MUSIC
	add_child(_stinger_player)

	_load_settings()
	_apply_all_volumes()

	SignalBus.screen_changed.connect(_on_screen_changed)
	SignalBus.chest_opened.connect(_on_chest_opened)
	SignalBus.boss_intro_started.connect(_on_boss_intro)
	SignalBus.chama_gained.connect(_on_chama)
	SignalBus.boss_special_telegraph.connect(_on_boss_special_telegraph)

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

## Casa ambiência, música e stinger ao estado da tela.
func _apply_screen_audio(screen: int) -> void:
	_apply_space_profile(screen)
	_refresh_ambience(screen)
	_play_music(_music_for_screen(screen))
	match screen:
		SignalBus.Screen.ARENA, SignalBus.Screen.ARENA_PHASE2, \
		SignalBus.Screen.ARENA_PHASE3, SignalBus.Screen.ARENA_PHASE4, \
		SignalBus.Screen.ARENA_PHASE5:
			_play_stinger(STING_ARENA)
		SignalBus.Screen.WIN:
			_play_stinger(STING_VICTORY)
		SignalBus.Screen.ENDING:
			# Só se chega ao ENDING matando o Jesuíta: o órgão dele estertora.
			_play_stinger(STING_ORGAO_ESTERTOR)
		SignalBus.Screen.GAME_OVER:
			_play_stinger(STING_GAME_OVER)

func _on_chest_opened() -> void:
	if _audio_unlocked:
		_play_stinger(STING_CHEST)

## A revelação do boss (overlay durante a exploração) já dispara o tema do boss, que
## atravessa para a arena sem corte (o _play_music no-opa quando a faixa é a mesma).
func _on_boss_intro() -> void:
	if not _audio_unlocked:
		return
	# Fase FINAL: a revelação do Jesuíta toca o sino da torre, não o stinger genérico.
	var sting := STING_SINO_IGREJA if GameState.active_phase == FINAL_PHASE else STING_BOSS_INTRO
	_play_stinger(sting)
	_play_music(_mus(_boss_track(GameState.active_phase)))

func _on_chama() -> void:
	if _audio_unlocked:
		_play_stinger(STING_CHAMA)

## Cue de leitura do especial do Jesuíta: sibilo de água benta no wind-up.
func _on_boss_special_telegraph(boss_type: String) -> void:
	if _audio_unlocked and boss_type == "jesuita":
		_play_stinger(STING_AGUA_BENTA)

# ─── Espaço acústico (bus Reverb) ──────────────────
## Resolve o perfil de espaço da tela. Fase 5 inteira (explore+arena) é a igreja
## de pedra; as demais arenas são a clareira; todo o resto é mata fechada.
func _space_for_screen(screen: int) -> StringName:
	match screen:
		SignalBus.Screen.EXPLORATION_PHASE5, SignalBus.Screen.ARENA_PHASE5:
			return &"igreja"
		SignalBus.Screen.ARENA, SignalBus.Screen.ARENA_PHASE2, \
		SignalBus.Screen.ARENA_PHASE3, SignalBus.Screen.ARENA_PHASE4:
			return &"arena"
		_:
			return &"mata"

func _apply_space_profile(screen: int) -> void:
	var idx := AudioServer.get_bus_index(BUS_REVERB)
	if idx < 0:
		return
	var fx := AudioServer.get_bus_effect(idx, 0) as AudioEffectReverb
	if fx == null:
		return
	var profile: Dictionary = SPACE_PROFILES[_space_for_screen(screen)]
	fx.room_size = profile["room_size"]
	fx.wet = profile["wet"]
	fx.damping = profile["damping"]
	fx.predelay_msec = profile["predelay_msec"]

# ─── Ambiência ─────────────────────────────────────
func _refresh_ambience(screen: int) -> void:
	var path := ""
	match screen:
		SignalBus.Screen.EXPLORATION, SignalBus.Screen.HUB:
			path = AMB_FOREST  # mata noturna
		SignalBus.Screen.EXPLORATION_PHASE2:
			path = AMB_FIRE    # floresta em chamas
		SignalBus.Screen.EXPLORATION_PHASE3:
			path = AMB_FOG     # névoa
		SignalBus.Screen.EXPLORATION_PHASE4:
			path = AMB_DREAD   # ruína fria
		# A arena da Fase 5 é o altar DENTRO da mesma igreja: a cama sonora não
		# troca na porta (mesma continuidade espacial do boss-intro→arena).
		SignalBus.Screen.EXPLORATION_PHASE5, SignalBus.Screen.ARENA_PHASE5:
			path = AMB_CHURCH  # igreja fria e úmida
		SignalBus.Screen.ARENA, SignalBus.Screen.ARENA_PHASE2, \
		SignalBus.Screen.ARENA_PHASE3, SignalBus.Screen.ARENA_PHASE4:
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

# ─── Música por contexto ───────────────────────────
## Resolve a faixa (caminho .wav) da tela/fase atual. "" = sem música (WIN/GAME_OVER).
func _music_for_screen(screen: int) -> String:
	match screen:
		SignalBus.Screen.MAIN_MENU:
			return _mus("mus_menu")
		SignalBus.Screen.HUB:
			return _mus("mus_hub")
		SignalBus.Screen.ENDING:
			return _mus("mus_ending")
		SignalBus.Screen.EXPLORATION, SignalBus.Screen.EXPLORATION_PHASE2, \
		SignalBus.Screen.EXPLORATION_PHASE3, SignalBus.Screen.EXPLORATION_PHASE4, \
		SignalBus.Screen.EXPLORATION_PHASE5:
			return _mus("mus_explore_p%d" % _phase_from_screen(screen))
		SignalBus.Screen.ARENA, SignalBus.Screen.ARENA_PHASE2, \
		SignalBus.Screen.ARENA_PHASE3, SignalBus.Screen.ARENA_PHASE4, \
		SignalBus.Screen.ARENA_PHASE5:
			var phase := _phase_from_screen(screen)
			if GameState.active_combat_is_boss:
				return _mus(_boss_track(phase))
			return _mus("mus_arena_p%d" % phase)
		_:
			return ""

## Caminho completo da faixa de música por nome.
func _mus(track: String) -> String:
	return MUSIC_DIR + track + ".wav"

## Nome do tema do boss por fase (1=Mula, 2=Boitatá, 3=Curupira, 4=Saci).
func _boss_track(phase: int) -> String:
	match phase:
		2: return "mus_boss_boitata"
		3: return "mus_boss_curupira"
		4: return "mus_boss_saci"
		5: return "mus_boss_jesuita"
		_: return "mus_boss_mula"

## Fase 1..4 a partir do enum da tela (explore/arena codificam a fase no nome).
func _phase_from_screen(screen: int) -> int:
	match screen:
		SignalBus.Screen.EXPLORATION_PHASE2, SignalBus.Screen.ARENA_PHASE2:
			return 2
		SignalBus.Screen.EXPLORATION_PHASE3, SignalBus.Screen.ARENA_PHASE3:
			return 3
		SignalBus.Screen.EXPLORATION_PHASE4, SignalBus.Screen.ARENA_PHASE4:
			return 4
		SignalBus.Screen.EXPLORATION_PHASE5, SignalBus.Screen.ARENA_PHASE5:
			return 5
		_:
			return 1

## Crossfade para uma nova faixa. No-op se já tocando a mesma (transição sem corte
## boss-intro→arena). path "" ou ausente: faz fade-out e para.
func _play_music(path: String) -> void:
	if path == _current_music:
		return
	_current_music = path
	var outgoing := _music_active
	var stream_path := _music_stream_path(path)
	if stream_path == "":
		if outgoing != null and outgoing.playing:
			_fade_player(outgoing, -40.0, true, MUSIC_FADE)
		_music_active = null
		return
	var incoming: AudioStreamPlayer = _music_b if _music_active == _music_a else _music_a
	var s := _load_music_stream(stream_path)
	if s == null:
		if outgoing != null and outgoing.playing:
			_fade_player(outgoing, -40.0, true, MUSIC_FADE)
		_music_active = null
		return
	_force_loop(s)
	incoming.stop()
	incoming.stream = s
	incoming.volume_db = -40.0
	incoming.play()
	_fade_player(incoming, 0.0, false, MUSIC_FADE)
	if outgoing != null and outgoing.playing:
		_fade_player(outgoing, -40.0, true, MUSIC_FADE)
	_music_active = incoming

func _music_stream_path(path: String) -> String:
	if path == "":
		return ""
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return path
	var base_stem_path := "%s_base.%s" % [path.get_basename(), path.get_extension()]
	if ResourceLoader.exists(base_stem_path) or FileAccess.file_exists(base_stem_path):
		return base_stem_path
	return ""

func _load_music_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	if path.get_extension().to_lower() == "wav" and FileAccess.file_exists(path):
		return AudioStreamWAV.load_from_file(path)
	return null

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

func _fade_player(player: AudioStreamPlayer, to_db: float, stop_after: bool, dur: float = AMBIENCE_FADE) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, dur)
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
