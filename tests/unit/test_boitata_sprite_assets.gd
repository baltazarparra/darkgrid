extends GutTest

# Contrato visual do Boitata premium: serpente de fogo/cadaver em canvas grande,
# escala de node 1.2 na arena, sem roubar as cores-marca da Caipora.

const SPRITE_SIZES: Dictionary = {
	"res://assets/sprites/boitata_idle.png": Vector2(160, 128),
	"res://assets/sprites/boitata_windup.png": Vector2(160, 128),
}
const MIN_OPAQUE_FRACTION := 0.12

const BOITATA_IDLE := "res://assets/sprites/boitata_idle.png"
const BOITATA_WINDUP := "res://assets/sprites/boitata_windup.png"

const COLOR_CHAR := Color8(28, 13, 9)
const COLOR_SCALE := Color8(132, 38, 19)
const COLOR_FIRE := Color8(226, 87, 24)
const COLOR_FIRE_HOT := Color8(255, 178, 72)
const COLOR_FIRE_WHITE := Color8(255, 232, 174)
const COLOR_ASH := Color8(126, 119, 98)
const COLOR_BLOOD := Color8(139, 0, 0)
const COLOR_EYE := Color8(250, 203, 83)

const COLOR_CAIPORA_EYES := Color8(255, 255, 255)
const COLOR_CAIPORA_MANE := Color8(255, 69, 0)
const COLOR_CAIPORA_MANE_DK := Color8(139, 42, 0)
const COLOR_CAIPORA_CRYSTAL := Color8(0, 250, 154)

func test_boitata_sprite_contract_sizes() -> void:
	for path: String in SPRITE_SIZES:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), SPRITE_SIZES[path],
			"%s mantem canvas premium %s" % [path, SPRITE_SIZES[path]])

func test_boitata_sprites_are_not_blank() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var expected: Vector2 = SPRITE_SIZES[path]
		var min_opaque := int(expected.x * expected.y * MIN_OPAQUE_FRACTION)
		assert_gt(_count_opaque_pixels(image), min_opaque,
			"%s tem massa visual de serpente gigante" % path)

func test_boitata_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(BOITATA_IDLE))
	assert_false(image.is_empty(), "boitata idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_CHAR), "idle preserva corpo carbonizado")
	assert_true(_has_color(image, COLOR_SCALE), "idle preserva escama vermelho-queimada")
	assert_true(_has_color(image, COLOR_FIRE), "idle preserva fogo sem usar laranja exato da Caipora")
	assert_true(_has_color(image, COLOR_FIRE_HOT), "idle preserva brasa quente")
	assert_true(_has_color(image, COLOR_ASH), "idle preserva chifres/cinzas")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva sangue material")
	assert_true(_has_color(image, COLOR_EYE), "idle preserva olhos em fenda amarelos")

func test_boitata_windup_has_white_corpse_fire() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(BOITATA_WINDUP))
	assert_false(image.is_empty(), "boitata windup carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_FIRE_WHITE),
		"windup acende fogo branco-amarelado sem usar branco puro de olhos da Caipora")

func test_boitata_windup_silhouette_differs_from_idle() -> void:
	var idle := Image.load_from_file(ProjectSettings.globalize_path(BOITATA_IDLE))
	var windup := Image.load_from_file(ProjectSettings.globalize_path(BOITATA_WINDUP))
	if idle.is_empty() or windup.is_empty():
		fail_test("boitata idle/windup carregam como Image")
		return
	assert_ne(idle.get_data(), windup.get_data(),
		"windup levanta cabeca/pescoco e telegrafa diferente do idle")

func test_boitata_does_not_steal_caipora_brand_colors() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_false(_has_color(image, COLOR_CAIPORA_EYES),
			"%s sem olhos brancos puros" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_MANE),
			"%s sem o laranja vivo da juba" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_MANE_DK),
			"%s sem o laranja escuro da juba" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_CRYSTAL),
			"%s sem o verde do cristal/Furia" % path)

func _count_opaque_pixels(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				count += 1
	return count

func _has_color(image: Image, expected: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				return true
	return false
