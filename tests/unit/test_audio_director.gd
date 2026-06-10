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
	AudioDirector._music_stem_base.stop()
	AudioDirector._music_stem_mid.stop()
	AudioDirector._music_stem_top.stop()
	AudioDirector._stems_active = false
	AudioDirector._music_intensity = 0
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

func _stinger_path() -> String:
	return AudioDirector._stinger_player.stream.resource_path

func test_boss_intro_stinger_is_church_bell_on_final_phase():
	AudioDirector.unlock_audio()
	var phase_before := GameState.active_phase
	GameState.active_phase = 5
	GameState.active_combat_is_boss = true
	AudioDirector._on_boss_intro()
	assert_true(_stinger_path().ends_with("sting_sino_igreja.wav"),
		"revelação do Jesuíta toca o sino da torre")
	GameState.active_phase = 1
	AudioDirector._on_boss_intro()
	assert_true(_stinger_path().ends_with("sting_boss_intro.wav"),
		"fases 1–4 mantêm o stinger genérico de revelação")
	GameState.active_phase = phase_before
	GameState.active_combat_is_boss = false

func test_ending_plays_organ_death_rattle():
	AudioDirector.unlock_audio()
	AudioDirector._apply_screen_audio(SignalBus.Screen.ENDING)
	assert_true(_stinger_path().ends_with("sting_orgao_estertor.wav"),
		"vitória sobre o Jesuíta = estertor de órgão")

func test_jesuita_special_telegraph_plays_agua_benta():
	AudioDirector.unlock_audio()
	SignalBus.boss_special_telegraph.emit("jesuita")
	assert_true(_stinger_path().ends_with("sting_agua_benta.wav"),
		"wind-up do especial do Jesuíta sibila água benta")
	SignalBus.boss_special_telegraph.emit("saci")
	assert_true(_stinger_path().ends_with("sting_agua_benta.wav"),
		"outros chefes não trocam o stinger")

func test_arena_starts_music():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = false
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA)
	assert_not_null(AudioDirector._music_active, "deve haver player de música ativo na arena")
	assert_true(AudioDirector._music_active.playing, "a música da arena deve estar tocando")

func test_arena_uses_stems_at_intensity_one():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = false
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA_PHASE2)
	assert_true(AudioDirector._stems_active, "arena comum deve usar stems verticais")
	assert_eq(AudioDirector._music_active, AudioDirector._music_stem_base,
		"o stem base preserva o contrato de player ativo")
	assert_true(AudioDirector._music_stem_base.playing, "stem base deve tocar")
	assert_true(AudioDirector._music_stem_mid.playing, "stem mid deve tocar sincronizado")
	assert_true(AudioDirector._music_stem_top.playing, "stem top deve tocar sincronizado")
	assert_eq(AudioDirector._music_intensity, 1, "arena comum entra em intensidade 1")

func test_boss_uses_stems_at_intensity_two():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = true
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA_PHASE4)
	assert_true(AudioDirector._stems_active, "boss deve usar stems verticais")
	assert_eq(AudioDirector._music_intensity, 2, "boss entra em intensidade 2")
	assert_true(AudioDirector._music_stem_base.stream.resource_path.ends_with("mus_boss_saci_base.wav"))
	GameState.active_combat_is_boss = false

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

func test_missing_single_loop_falls_back_to_base_stem():
	var path := "res://assets/audio/music/mus_arena_p1.wav"
	assert_false(ResourceLoader.exists(path), "arena p1 não tem loop único materializado")
	assert_true(ResourceLoader.exists("res://assets/audio/music/mus_arena_p1_base.wav"),
		"o fallback base existe")
	assert_eq(AudioDirector._music_stream_path(path),
		"res://assets/audio/music/mus_arena_p1_base.wav")

func test_reverb_bus_exists_and_routes():
	var idx_reverb := AudioServer.get_bus_index("Reverb")
	assert_true(idx_reverb >= 0, "bus Reverb deve existir")
	assert_true(AudioServer.get_bus_effect(idx_reverb, 0) is AudioEffectReverb,
		"bus Reverb carrega um AudioEffectReverb")
	var idx_sfx := AudioServer.get_bus_index("SFX")
	var idx_amb := AudioServer.get_bus_index("Ambience")
	assert_eq(AudioServer.get_bus_send(idx_sfx), &"Reverb", "SFX atravessa o espaço")
	assert_eq(AudioServer.get_bus_send(idx_amb), &"Reverb", "Ambience atravessa o espaço")
	var idx_music := AudioServer.get_bus_index("Music")
	assert_eq(AudioServer.get_bus_send(idx_music), &"Master",
		"Music fica fora do reverb (espaço da música é a cauda impressa)")

func _reverb_fx() -> AudioEffectReverb:
	return AudioServer.get_bus_effect(AudioServer.get_bus_index("Reverb"), 0) as AudioEffectReverb

func test_space_profile_per_screen():
	# Igreja (Fase 5 inteira) = sala grande; arenas 1–4 = clareira; resto = mata seca.
	AudioDirector._apply_space_profile(SignalBus.Screen.EXPLORATION_PHASE5)
	assert_almost_eq(_reverb_fx().room_size, 0.9, 0.01, "igreja de pedra responde")
	AudioDirector._apply_space_profile(SignalBus.Screen.ARENA_PHASE5)
	assert_almost_eq(_reverb_fx().room_size, 0.9, 0.01, "o altar é a mesma igreja")
	AudioDirector._apply_space_profile(SignalBus.Screen.ARENA_PHASE2)
	assert_almost_eq(_reverb_fx().room_size, 0.55, 0.01, "arena = clareira média")
	AudioDirector._apply_space_profile(SignalBus.Screen.EXPLORATION)
	assert_almost_eq(_reverb_fx().room_size, 0.25, 0.01, "a folhagem absorve")
	assert_almost_eq(_reverb_fx().wet, 0.05, 0.001, "mata quase seca")

func test_music_bus_has_eq():
	var fx := AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0)
	assert_true(fx is AudioEffectEQ6, "bus Music carrega EQ de 6 bandas")
	var eq := fx as AudioEffectEQ6
	assert_almost_eq(eq.get_band_gain_db(4), -3.0, 0.01,
		"a música cede a banda de presença aos SFX de timing")
