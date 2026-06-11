extends GutTest

# Contrato visual do Saci premium: menino de uma perna, menor que a Caipora,
# carbonizado, com carapuca vermelha e redemoinho sujo.

const SPRITE_SIZES: Dictionary = {
	"res://assets/sprites/saci_idle.png": Vector2(128, 128),
	"res://assets/sprites/saci_windup.png": Vector2(128, 128),
}
const MIN_OPAQUE_FRACTION := 0.09

const SACI_IDLE := "res://assets/sprites/saci_idle.png"
const SACI_WINDUP := "res://assets/sprites/saci_windup.png"
const CAIPORA_IDLE := "res://assets/sprites/player_idle.png"

const COLOR_CHAR := Color8(34, 19, 17)
const COLOR_CAP := Color8(190, 24, 18)
const COLOR_CAP_HOT := Color8(232, 70, 36)
const COLOR_EMBER := Color8(238, 92, 28)
const COLOR_EMBER_HOT := Color8(255, 178, 82)
const COLOR_PIPE := Color8(88, 52, 28)
const COLOR_SMOKE := Color8(142, 130, 112)
const COLOR_ASH := Color8(72, 63, 52)
const COLOR_BLOOD := Color8(139, 0, 0)

const COLOR_CAIPORA_EYES := Color8(255, 255, 255)
const COLOR_CAIPORA_MANE := Color8(255, 69, 0)
const COLOR_CAIPORA_MANE_DK := Color8(139, 42, 0)
const COLOR_CAIPORA_CRYSTAL := Color8(0, 250, 154)

func test_saci_sprite_contract_sizes() -> void:
	for path: String in SPRITE_SIZES:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), SPRITE_SIZES[path],
			"%s mantem canvas premium %s" % [path, SPRITE_SIZES[path]])

func test_saci_sprites_are_not_blank() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var expected: Vector2 = SPRITE_SIZES[path]
		var min_opaque := int(expected.x * expected.y * MIN_OPAQUE_FRACTION)
		assert_gt(_count_opaque_pixels(image), min_opaque,
			"%s tem massa visual suficiente" % path)

func test_saci_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SACI_IDLE))
	assert_false(image.is_empty(), "saci idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_CHAR), "idle preserva corpo carbonizado")
	assert_true(_has_color(image, COLOR_CAP), "idle preserva carapuca vermelha suja")
	assert_true(_has_color(image, COLOR_CAP_HOT), "idle preserva corte quente da carapuca")
	assert_true(_has_color(image, COLOR_EMBER), "idle preserva olhos/rachaduras de brasa")
	assert_true(_has_color(image, COLOR_PIPE), "idle preserva cachimbo")
	assert_true(_has_color(image, COLOR_SMOKE), "idle preserva fumaca suja")
	assert_true(_has_color(image, COLOR_ASH), "idle preserva redemoinho de cinza")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva sangue fisico")

func test_saci_windup_lights_more_ember() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SACI_WINDUP))
	assert_false(image.is_empty(), "saci windup carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_EMBER_HOT), "windup acende brasa quente")

func test_saci_windup_silhouette_differs_from_idle() -> void:
	var idle := Image.load_from_file(ProjectSettings.globalize_path(SACI_IDLE))
	var windup := Image.load_from_file(ProjectSettings.globalize_path(SACI_WINDUP))
	if idle.is_empty() or windup.is_empty():
		fail_test("saci idle/windup carregam como Image")
		return
	assert_ne(idle.get_data(), windup.get_data(),
		"windup desloca cabeca/carapuca/redemoinho e telegrafa diferente do idle")

func test_saci_reads_smaller_than_caipora() -> void:
	var saci := Image.load_from_file(ProjectSettings.globalize_path(SACI_IDLE))
	var caipora := Image.load_from_file(ProjectSettings.globalize_path(CAIPORA_IDLE))
	assert_false(saci.is_empty(), "saci idle carrega como Image")
	assert_false(caipora.is_empty(), "caipora idle carrega como Image")
	if saci.is_empty() or caipora.is_empty():
		return
	assert_lt(_opaque_height(saci), _opaque_height(caipora),
		"Saci menino de uma perna le menor que a Caipora-crianca")

func test_saci_does_not_steal_caipora_brand_colors() -> void:
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

func _opaque_height(image: Image) -> int:
	var top := image.get_height()
	var bottom := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return maxi(bottom - top + 1, 0)

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
