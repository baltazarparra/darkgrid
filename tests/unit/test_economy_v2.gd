extends GutTest

## Trava os números da Economia v2 (docs/PRD-economia-v2.md): tabelas de recompensa por
## fase, snowball pela metade e a curva de custo das duas trilhas. Um retuning acidental
## quebra aqui antes de chegar ao jogo. A LÓGICA de aplicação (meio HP/kill, boss bounty)
## vive em arena_manager._on_actor_died; aqui validamos as constantes que ela consome.

func test_common_fragment_reward_scales_by_phase() -> void:
	assert_eq(Constants.COMMON_FRAGMENT_REWARD, {1: 1, 2: 2, 3: 3, 4: 4})

func test_boss_bounty_scales_by_phase() -> void:
	assert_eq(Constants.BOSS_FRAGMENT_BOUNTY, {1: 3, 2: 5, 3: 8, 4: 12})

func test_snowball_is_half_hp_per_common_kill() -> void:
	assert_eq(Constants.COMMON_KILL_HP_GROWTH, 0.5, "meio HP máx. por kill comum")
	assert_eq(Constants.BOSS_KILL_HP_GROWTH, 1.0, "boss é marco de +1 HP máx.")

func test_furia_track_is_capped_at_plus_four() -> void:
	# Cada erva da Fúria soma +1 (teto +4 → dano 5; +1 da CHAMA → 6).
	var sum := 0
	for key in MetaProgression.FURIA_KEYS:
		assert_eq(int(MetaProgression.UPGRADE_DEFS[key].get("dmg", 0)), 1, "%s soma +1 dano" % key)
		sum += int(MetaProgression.UPGRADE_DEFS[key]["dmg"])
	assert_eq(sum, 4, "trilha Fúria soma +4 no total")
	assert_eq(MetaProgression.CHAMA_DAMAGE_BONUS, 1, "CHAMA soma +1 (respeita o teto)")

func test_cura_track_caps_at_fourteen() -> void:
	# Incrementos crescentes 2/3/3/4 → HP máx. = base 2 + 12 = 14.
	var sum := 0
	for key in MetaProgression.CURA_KEYS:
		sum += int(MetaProgression.UPGRADE_DEFS[key].get("hp", 0))
	assert_eq(sum, 12, "trilha Cura soma +12 no total")
	assert_eq(Constants.CAIPORA_MAX_HEALTH + sum, 14, "HP máx. com Cura cheia = 14")

func test_upgrade_costs_rise_per_tier() -> void:
	# Custo marginal crescente em ambas as trilhas (escassez = dificuldade).
	for keys in [MetaProgression.FURIA_KEYS, MetaProgression.CURA_KEYS]:
		var prev := 0
		for key in keys:
			var cost := int(MetaProgression.UPGRADE_DEFS[key]["fragment_cost"])
			assert_true(cost > prev, "%s custa mais que o tier anterior (%d > %d)" % [key, cost, prev])
			prev = cost
