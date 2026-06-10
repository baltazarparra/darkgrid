class_name TestWeaponVisual
extends GutTest

## Cobre o componente reutilizável WeaponVisual: sprites evolutivos T1–T6 +
## partículas escalonadas (fumaça, aura dourada, resíduos, fragmentos, espinhos).

func before_each() -> void:
	# Limpa todos os tiers de Fúria antes de cada teste
	for key in MetaProgression.FURIA_KEYS:
		MetaProgression.upgrades.erase(key)
	MetaProgression.has_chama = false

func after_each() -> void:
	for key in MetaProgression.FURIA_KEYS:
		MetaProgression.upgrades.erase(key)
	MetaProgression.has_chama = false

func test_no_furia_is_noop() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)
	assert_null(parent.get_node_or_null("WeaponSprite"), "sem nenhum tier de Fúria, não anexa nada")

func test_tier1_shows_sprite_only() -> void:
	MetaProgression.upgrades["forca"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T1 anexa sprite")
	assert_eq(weapon.texture.get_size(), Vector2(64, 112), "sprite 64×112")
	assert_null(weapon.get_node_or_null("Smoke"), "T1 sem fumaça")
	assert_null(weapon.get_node_or_null("GoldAura"), "T1 sem aura")

func test_tier2_adds_smoke() -> void:
	MetaProgression.upgrades["forca_2"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T2 anexa sprite")
	var smoke := weapon.get_node_or_null("Smoke") as CPUParticles2D
	assert_not_null(smoke, "T2 tem fumaça")
	assert_true(smoke.emitting, "fumaça emitindo")
	assert_eq(smoke.z_index, -1, "fumaça atrás do sprite")
	assert_null(weapon.get_node_or_null("GoldAura"), "T2 sem aura dourada")

func test_tier3_adds_gold_aura() -> void:
	MetaProgression.upgrades["forca_3"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T3 anexa sprite")
	var smoke := weapon.get_node_or_null("Smoke") as CPUParticles2D
	assert_not_null(smoke, "T3 tem fumaça")
	var aura := weapon.get_node_or_null("GoldAura") as CPUParticles2D
	assert_not_null(aura, "T3 tem aura dourada")
	assert_true(aura.emitting, "aura emitindo")
	var mat := aura.material as CanvasItemMaterial
	assert_not_null(mat, "aura tem material")
	assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "aura usa blend aditivo")
	assert_null(weapon.get_node_or_null("BreuResidue"), "T3 sem resíduos")

func test_tier4_adds_residue() -> void:
	MetaProgression.upgrades["forca_4"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T4 anexa sprite")
	assert_not_null(weapon.get_node_or_null("Smoke"), "T4 tem fumaça")
	assert_not_null(weapon.get_node_or_null("GoldAura"), "T4 tem aura")
	var residue := weapon.get_node_or_null("BreuResidue") as CPUParticles2D
	assert_not_null(residue, "T4 tem resíduos de breu")
	assert_null(weapon.get_node_or_null("BoneFragments"), "T4 sem fragmentos de osso")

func test_tier5_adds_bone_fragments() -> void:
	MetaProgression.upgrades["forca_5"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T5 anexa sprite")
	assert_not_null(weapon.get_node_or_null("Smoke"), "T5 tem fumaça")
	assert_not_null(weapon.get_node_or_null("GoldAura"), "T5 tem aura")
	assert_not_null(weapon.get_node_or_null("BreuResidue"), "T5 tem resíduos")
	var bone := weapon.get_node_or_null("BoneFragments") as CPUParticles2D
	assert_not_null(bone, "T5 tem fragmentos de osso")
	assert_null(weapon.get_node_or_null("FleshSpines"), "T5 sem espinhos de carne")

func test_tier6_adds_flesh_spines() -> void:
	MetaProgression.upgrades["forca_6"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "T6 anexa sprite")
	assert_not_null(weapon.get_node_or_null("Smoke"), "T6 tem fumaça")
	assert_not_null(weapon.get_node_or_null("GoldAura"), "T6 tem aura")
	assert_not_null(weapon.get_node_or_null("BreuResidue"), "T6 tem resíduos")
	assert_not_null(weapon.get_node_or_null("BoneFragments"), "T6 tem fragmentos")
	var spines := weapon.get_node_or_null("FleshSpines") as CPUParticles2D
	assert_not_null(spines, "T6 tem espinhos de carne")
	assert_true(spines.emitting, "espinhos emitindo")

func test_chama_adds_flame_to_tier3() -> void:
	MetaProgression.upgrades["forca_3"] = 1
	MetaProgression.has_chama = true
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "anexa sprite")
	var flame := weapon.get_node_or_null("ChamaFlame") as CPUParticles2D
	assert_not_null(flame, "CHAMA adiciona partículas de chama")
	assert_true(flame.emitting, "chama emitindo")
