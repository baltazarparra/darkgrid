extends GutTest

# Exercita o contrato do AudioDirector (autoload) de forma headless:
#   - os buses do layout existem
#   - volume por bus seta/lê e respeita o clamp
#   - duck() roda sem erro
#   - cada tela resolve a faixa de música correta e a arena começa a tocar
#   - o tema do boss começa na revelação e atravessa para a arena sem corte
# Não valida áudio audível (isso é manual). Restaura o estado global ao fim.

func after_each():
	# Para toda reprodução iniciada pelos testes (evita 'resources in use at exit').
	AudioDirector._music_a.stop()
	AudioDirector._music_b.stop()
	AudioDirector._music_active = null
	AudioDirector._current_music = ""
	AudioDirector._stinger_player.stop()
	AudioDirector._ambience_player.stop()
	AudioDirector._current_ambience = ""
	AudioDirector.set_bus_volume("Music", 0.8)

func test_layout_buses_exist():
	for bus_name in ["Master", "SFX", "Music", "Ambience"]:
		assert_true(AudioServer.get_bus_index(bus_name) >= 0, "bus %s deve existir" % bus_name)

func test_set_get_bus_volume_clamps():
	AudioDirector.set_bus_volume("SFX", 0.5)
	assert_almost_eq(AudioDirector.get_bus_volume("SFX"), 0.5, 0.001)
	AudioDirector.set_bus_volume("SFX", 2.0)
	assert_almost_eq(AudioDirector.get_bus_volume("SFX"), 1.0, 0.001)
	AudioDirector.set_bus_volume("SFX", 1.0)  # restaura

func test_duck_runs_without_error():
	AudioDirector.duck()
	assert_true(true, "duck() não deve quebrar")

func test_music_resolves_per_screen():
	# Cada fase de exploração e arena mapeia para a sua própria faixa.
	GameState.active_combat_is_boss = false
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.MAIN_MENU),
		"res://assets/audio/music/mus_menu.wav")
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.EXPLORATION_PHASE3),
		"res://assets/audio/music/mus_explore_p3.wav")
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.ARENA_PHASE2),
		"res://assets/audio/music/mus_arena_p2.wav")
	# Fase FINAL (A Igreja): faixa própria de exploração e de arena.
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.EXPLORATION_PHASE5),
		"res://assets/audio/music/mus_explore_p5.wav")
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.ARENA_PHASE5),
		"res://assets/audio/music/mus_arena_p5.wav")
	# WIN/GAME_OVER não têm loop de música.
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.WIN), "")

func test_boss_screen_picks_boss_theme():
	GameState.active_combat_is_boss = true
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.ARENA_PHASE4),
		"res://assets/audio/music/mus_boss_saci.wav")
	# Boss FINAL: o Jesuíta tem seu próprio tema.
	assert_eq(AudioDirector._music_for_screen(SignalBus.Screen.ARENA_PHASE5),
		"res://assets/audio/music/mus_boss_jesuita.wav")
	GameState.active_combat_is_boss = false

func test_ambience_resolves_church_for_phase5():
	# A igreja tem cama sonora própria — na exploração E na arena (mesmo espaço).
	AudioDirector._refresh_ambience(SignalBus.Screen.EXPLORATION_PHASE5)
	assert_eq(AudioDirector._current_ambience, AudioDirector.AMB_CHURCH,
		"exploração da Fase 5 usa a ambiência de igreja")
	AudioDirector._refresh_ambience(SignalBus.Screen.ARENA_PHASE5)
	assert_eq(AudioDirector._current_ambience, AudioDirector.AMB_CHURCH,
		"a arena da Fase 5 é o altar da mesma igreja")
	AudioDirector._refresh_ambience(SignalBus.Screen.ARENA_PHASE4)
	assert_eq(AudioDirector._current_ambience, AudioDirector.AMB_DREAD,
		"arenas 1–4 continuam no dread")

func test_arena_starts_music():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = false
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA)
	assert_not_null(AudioDirector._music_active, "deve haver player de música ativo na arena")
	assert_true(AudioDirector._music_active.playing, "a música da arena deve estar tocando")

func test_same_track_does_not_restart():
	# Boss-intro inicia o tema; a arena pede a MESMA faixa → não reinicia (sem corte).
	AudioDirector.unlock_audio()
	GameState.active_phase = 1
	GameState.active_combat_is_boss = true
	AudioDirector._on_boss_intro()
	var active_before := AudioDirector._music_active
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA)
	assert_eq(AudioDirector._music_active, active_before,
		"a faixa de boss não deve trocar de player ao entrar na arena")
	GameState.active_combat_is_boss = false
