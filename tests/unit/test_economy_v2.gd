extends GutTest

## Trava os números da Economia v2 (docs/PRD-economia-v2.md) + expansão T5/T6:
## tabelas de recompensa por fase, snowball pela metade e a curva de custo das duas trilhas.
## Um retuning acidental quebra aqui antes de chegar ao jogo.

func test_common_fragment_reward_scales_by_phase() -> void:
	assert_eq(Constants.COMMON_FRAGMENT_REWARD, {1: 1, 2: 2, 3: 3, 4: 4})

func test_boss_bounty_scales_by_phase() -> void:
	assert_eq(Constants.BOSS_FRAGMENT_BOUNTY, {1: 3, 2: 5, 3: 8, 4: 12})

func test_snowball_is_half_hp_per_common_kill() -> void:
	assert_eq(Constants.COMMON_KILL_HP_GROWTH, 0.5, "meio HP máx. por kill comum")
	assert_eq(Constants.BOSS_KILL_HP_GROWTH, 1.0, "boss é marco de +1 HP máx.")

func test_furia_track_damage_scaling() -> void:
	# Tiers 1-4 somam +1 cada; tiers 5-6 somam +2 cada.
	# Teto +8 → dano 9 base; +1 da CHAMA → 10.
	var sum := 0
	for key in MetaProgression.FURIA_KEYS:
		var dmg: int = int(MetaProgression.UPGRADE_DEFS[key].get("dmg", 0))
		var tier: int = int(MetaProgression.UPGRADE_DEFS[key].get("tier", 1))
		if tier <= 4:
			assert_eq(dmg, 1, "%s (T%d) soma +1 dano" % [key, tier])
		else:
			assert_eq(dmg, 2, "%s (T%d) soma +2 dano" % [key, tier])
		sum += dmg
	assert_eq(sum, 8, "trilha Fúria soma +8 no total (T1-T4: +4, T5-T6: +4)")
	assert_eq(MetaProgression.CHAMA_DAMAGE_BONUS, 1, "CHAMA soma +1")

func test_cura_track_health_scaling() -> void:
	# Incrementos 2/3/3/4/4/5 → HP máx. = base 2 + 21 = 23.
	var sum := 0
	for key in MetaProgression.CURA_KEYS:
		sum += int(MetaProgression.UPGRADE_DEFS[key].get("hp", 0))
	assert_eq(sum, 21, "trilha Cura soma +21 no total")
	assert_eq(Constants.CAIPORA_MAX_HEALTH + sum, 23, "HP máx. com Cura cheia = 23")

func test_upgrade_costs_rise_per_tier() -> void:
	# Custo marginal crescente em ambas as trilhas (escassez = dificuldade).
	for keys in [MetaProgression.FURIA_KEYS, MetaProgression.CURA_KEYS]:
		var prev := 0
		for key in keys:
			var cost := int(MetaProgression.UPGRADE_DEFS[key]["fragment_cost"])
			assert_true(cost > prev, "%s custa mais que o tier anterior (%d > %d)" % [key, cost, prev])
			prev = cost
