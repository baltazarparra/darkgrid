extends GutTest

# Escalonamento por fase (PRD: comuns com HP uniforme, dano da Caipora cresce por fase).
#  - Comuns (não-boss): mesmo HP — 5 nas fases 1-2, 8 nas fases 3-4.
#  - Cada golpe da Caipora bate 1 na P1, 2 na P2, 3 na P3, 4 na P4…

func test_common_health_uniform_per_phase_band() -> void:
	assert_eq(Constants.common_health_for_phase(1), 5, "fase 1 → 5")
	assert_eq(Constants.common_health_for_phase(2), 5, "fase 2 → 5")
	assert_eq(Constants.common_health_for_phase(3), 8, "fase 3 → 8")
	assert_eq(Constants.common_health_for_phase(4), 8, "fase 4 → 8")

func test_caipora_damage_scales_with_phase() -> void:
	assert_eq(Constants.caipora_base_damage_for_phase(1), 1, "1 de dano por golpe na P1")
	assert_eq(Constants.caipora_base_damage_for_phase(2), 2, "2 na P2")
	assert_eq(Constants.caipora_base_damage_for_phase(3), 3, "3 na P3")
	assert_eq(Constants.caipora_base_damage_for_phase(4), 4, "4 na P4")

func test_damage_never_below_one() -> void:
	# Guarda defensiva: fase inválida (0) não zera o dano da Caipora.
	assert_eq(Constants.caipora_base_damage_for_phase(0), 1)
