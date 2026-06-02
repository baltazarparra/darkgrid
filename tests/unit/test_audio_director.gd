extends GutTest

# Exercita o contrato do AudioDirector (autoload) de forma headless:
#   - os buses do layout existem
#   - volume por bus seta/lê e respeita o clamp
#   - duck() roda sem erro
#   - entrar na ARENA inicia os stems de maracatu (alfaia+ganzá)
# Não valida áudio audível (isso é manual). Restaura o estado global ao fim.

func after_each():
	# Para toda reprodução iniciada pelos testes (evita 'resources in use at exit').
	AudioDirector._maracatu_on = true  # força o stop a percorrer os players
	AudioDirector._stop_maracatu()
	for stem in AudioDirector._stem_players:
		AudioDirector._stem_players[stem].stop()
	AudioDirector._stinger_player.stop()
	AudioDirector._ambience_player.stop()
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

func test_arena_starts_maracatu():
	AudioDirector.unlock_audio()
	AudioDirector._apply_screen_audio(SignalBus.Screen.ARENA)
	var alfaia: AudioStreamPlayer = AudioDirector._stem_players[AudioDirector.STEM_ALFAIA]
	assert_not_null(alfaia.stream, "stem alfaia deve ter stream carregado na arena")
	assert_true(alfaia.playing, "stem alfaia deve estar tocando na arena")
