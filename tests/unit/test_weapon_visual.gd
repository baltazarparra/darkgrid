class_name TestWeaponVisual
extends GutTest

## Cobre o componente reutilizável WeaponVisual (Tronco Buster + aura ouro dark +
## fumaça), incluindo o gate de aprimoramento final de força (forca_3).

func before_each() -> void:
	MetaProgression.upgrades.erase("forca_3")

func after_each() -> void:
	MetaProgression.upgrades.erase("forca_3")

func test_locked_is_noop() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)
	assert_null(parent.get_node_or_null("WeaponSprite"), "sem forca_3, não anexa nada")

func test_unlocked_builds_sword_and_particles() -> void:
	MetaProgression.upgrades["forca_3"] = 1
	var parent := Node2D.new()
	add_child_autofree(parent)
	WeaponVisual.attach_to(parent)

	var weapon := parent.get_node_or_null("WeaponSprite") as Sprite2D
	assert_not_null(weapon, "anexa o sprite do tronco")
	assert_eq(weapon.texture.get_size(), Vector2(64, 112), "sprite maior que a Caipora (64×112)")

	var smoke := weapon.get_node_or_null("Smoke") as CPUParticles2D
	assert_not_null(smoke, "tem camada de fumaça")
	assert_true(smoke.emitting, "fumaça emitindo")
	assert_eq(smoke.z_index, -1, "fumaça atrás do tronco")

	var aura := weapon.get_node_or_null("GoldAura") as CPUParticles2D
	assert_not_null(aura, "tem aura dourada")
	assert_true(aura.emitting, "aura emitindo")
	var mat := aura.material as CanvasItemMaterial
	assert_not_null(mat, "aura tem material")
	assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "aura usa blend aditivo (glow)")
