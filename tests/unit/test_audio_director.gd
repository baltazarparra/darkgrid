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
	AudioDirector._heart_mode = false
	AudioDirector._music_active = null
	AudioDirector._current_music = ""
	AudioDirector._stinger_player.stop()
	AudioDirector._ambience_player.stop()
	AudioDirector._heartbeat_player.stop()
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

func test_heart_mode_activates_on_critical_hp():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = false
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA_PHASE2)
	SignalBus.caipora_health_changed.emit(2.0, 10.0)
	assert_true(AudioDirector._heart_mode, "HP abaixo de 30% ativa modo coração")
	assert_true(AudioDirector._heartbeat_player.playing, "heartbeat deve tocar após unlock")
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_BASE),
		AudioDirector.HEART_STEM_BASE_DB, 0.01)
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_MID),
		AudioDirector.STEM_SILENCE_DB, 0.01)
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_TOP),
		AudioDirector.STEM_SILENCE_DB, 0.01)

func test_heart_mode_waits_for_audio_unlock():
	AudioDirector._audio_unlocked = false
	SignalBus.caipora_health_changed.emit(1.0, 10.0)
	assert_true(AudioDirector._heart_mode, "estado crítico deve ser guardado")
	assert_false(AudioDirector._heartbeat_player.playing,
		"heartbeat não deve tocar antes do gesto que libera áudio")

func test_heart_mode_restores_previous_intensity_after_recovery():
	AudioDirector.unlock_audio()
	GameState.active_combat_is_boss = false
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA_PHASE2)
	SignalBus.caipora_health_changed.emit(2.0, 10.0)
	SignalBus.caipora_health_changed.emit(5.0, 10.0)
	assert_false(AudioDirector._heart_mode, "HP recuperado acima do limiar sai do modo coração")
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_BASE), 0.0, 0.01)
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_MID), 0.0, 0.01)
	assert_almost_eq(AudioDirector._stem_target_db(AudioDirector.STEM_TOP),
		AudioDirector.STEM_SILENCE_DB, 0.01)

func test_heart_mode_ignores_death_zero_hp():
	AudioDirector.unlock_audio()
	SignalBus.caipora_health_changed.emit(0.0, 10.0)
	assert_false(AudioDirector._heart_mode, "HP zero é morte, não estado crítico")

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

func _count_transient_players() -> int:
	# Players one-shot criados por _play_oneshot_sfx (filhos diretos além dos fixos).
	var fixed := [AudioDirector._music_a, AudioDirector._music_b,
		AudioDirector._music_stem_base, AudioDirector._music_stem_mid,
		AudioDirector._music_stem_top, AudioDirector._stinger_player,
		AudioDirector._ambience_player, AudioDirector._heartbeat_player]
	var extras := 0
	for child in AudioDirector.get_children():
		if child is AudioStreamPlayer and not fixed.has(child):
			extras += 1
	return extras

func test_ui_hover_respects_unlock_and_cooldown():
	AudioDirector._audio_unlocked = false
	AudioDirector._last_hover_msec = -AudioDirector.UI_HOVER_COOLDOWN_MSEC
	AudioDirector.play_ui_hover()
	assert_eq(_count_transient_players(), 0, "hover não toca antes do unlock de áudio")
	AudioDirector.unlock_audio()
	AudioDirector.play_ui_hover()
	AudioDirector.play_ui_hover()  # foco+mouse do mesmo controle: colapsa num tick só
	assert_eq(_count_transient_players(), 1, "cooldown colapsa hover duplo num único player")

func test_oneshot_sfx_missing_asset_is_noop():
	AudioDirector.unlock_audio()
	AudioDirector._play_oneshot_sfx("res://assets/audio/sfx/nao_existe.wav")
	assert_eq(_count_transient_players(), 0, "asset ausente não cria player nem quebra")

func test_bag_signals_play_oneshots_when_assets_exist():
	AudioDirector.unlock_audio()
	SignalBus.fragment_bag_dropped.emit(5.0)
	SignalBus.fragment_bag_recovered.emit(5.0)
	var expected := 0
	if ResourceLoader.exists(AudioDirector.STING_DIR + AudioDirector.STING_BAG_DROP + ".wav"):
		expected += 1
	if ResourceLoader.exists(AudioDirector.STING_DIR + AudioDirector.STING_BAG_RECOVER + ".wav"):
		expected += 1
	assert_eq(_count_transient_players(), expected,
		"cada sinal da bolsa toca um one-shot (graceful se o asset faltar)")

func test_force_loop_handles_8_and_16_bit():
	# A música é gravada em PCM 8-bit (1 byte por frame mono); SFX seguem 16-bit.
	var wav8 := AudioStreamWAV.new()
	wav8.format = AudioStreamWAV.FORMAT_8_BITS
	wav8.data = PackedByteArray([128, 200, 60, 128])
	AudioDirector._force_loop(wav8)
	assert_eq(wav8.loop_end, 4, "8-bit: loop_end = bytes (1 byte por frame)")
	var wav16 := AudioStreamWAV.new()
	wav16.format = AudioStreamWAV.FORMAT_16_BITS
	wav16.data = PackedByteArray([0, 0, 0, 0])
	AudioDirector._force_loop(wav16)
	assert_eq(wav16.loop_end, 2, "16-bit: loop_end = bytes / 2")

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
