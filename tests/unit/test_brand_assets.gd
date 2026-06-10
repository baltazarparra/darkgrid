extends GutTest

## Contrato dos assets de marca (gen_brand.py): a primeira leitura de qualquer
## ponto de contato é "mancha laranja serrilhada, vazio preto, dois olhos
## brancos PUROS" (docs/CONCEITO-protagonista.md + skill visual-identity).

const SIZES := {
	"res://assets/sprites/brand_mark.png": Vector2(64, 64),
	"res://assets/sprites/brand_mark_blink.png": Vector2(64, 64),
	"res://assets/sprites/logo_title.png": Vector2(256, 96),
	"res://assets/sprites/logo_title_blink.png": Vector2(256, 96),
	"res://assets/sprites/boot_splash.png": Vector2(1280, 720),
	"res://icon.png": Vector2(512, 512),
	"res://assets/icons/icon_512.png": Vector2(512, 512),
	"res://assets/icons/icon_180.png": Vector2(180, 180),
	"res://assets/icons/icon_144.png": Vector2(144, 144),
}

const MARK := "res://assets/sprites/brand_mark.png"
const MARK_BLINK := "res://assets/sprites/brand_mark_blink.png"
const LOGO := "res://assets/sprites/logo_title.png"
const LOGO_BLINK := "res://assets/sprites/logo_title_blink.png"
const SPLASH := "res://assets/sprites/boot_splash.png"

const COLOR_MANE := Color8(255, 69, 0)
const COLOR_MANE_DK := Color8(139, 42, 0)
const COLOR_VOID := Color8(0, 0, 0)
const COLOR_EYES := Color8(255, 255, 255)
const COLOR_BLOOD := Color8(139, 0, 0)
const COLOR_NIGHT := Color8(13, 17, 23)
const COLOR_OUTLINE := Color8(26, 18, 10)
# Identidade pré-rebrand que NÃO pode voltar (logo de madeira, olhos âmbar)
const LEGACY_WOOD := Color8(82, 43, 10)
const LEGACY_AMBER := Color8(255, 214, 84)

func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))

func test_brand_assets_keep_size_contract() -> void:
	for path: String in SIZES.keys():
		var image := _image(path)
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var size := Vector2(image.get_width(), image.get_height())
		assert_eq(size, SIZES[path], "%s mantem contrato de tamanho" % path)

func test_mark_is_orange_mass_with_pure_white_eyes() -> void:
	var image := _image(MARK)
	var orange := _count(image, COLOR_MANE) + _count(image, COLOR_MANE_DK)
	assert_gt(orange, _count(image, COLOR_VOID), "juba laranja domina a leitura do rosto-marca")
	assert_gt(_count(image, COLOR_EYES), 30, "dois olhos brancos puros presentes")
	assert_gt(_count(image, COLOR_OUTLINE), 0, "contorno 1px de treva na silhueta")

func test_mark_blink_closes_both_eyes() -> void:
	assert_eq(_count(_image(MARK_BLINK), COLOR_EYES), 0, "blink apaga os olhos no vazio")

func test_wordmark_is_juba_with_void_eyes_in_the_o() -> void:
	var image := _image(LOGO)
	var orange := _count(image, COLOR_MANE) + _count(image, COLOR_MANE_DK)
	assert_gt(orange, 2000, "letras leem na rampa laranja da juba")
	assert_gt(_count(image, COLOR_VOID), 100, "o O carrega o rosto-vazio preto")
	assert_eq(_count(image, COLOR_EYES), 18, "dois olhos 3x3 brancos puros no O")
	var blood := _count(image, COLOR_BLOOD)
	assert_between(blood, 1, orange / 10, "sangue presente porem minimo (acento, nao leitura)")

func test_wordmark_blink_closes_eyes_and_keeps_geometry() -> void:
	var blink := _image(LOGO_BLINK)
	assert_eq(_count(blink, COLOR_EYES), 0, "blink apaga os olhos do O")
	var open := _image(LOGO)
	var orange_open := _count(open, COLOR_MANE) + _count(open, COLOR_MANE_DK)
	var orange_blink := _count(blink, COLOR_MANE) + _count(blink, COLOR_MANE_DK)
	assert_eq(orange_open, orange_blink, "blink nao muda a geometria das letras")

func test_wordmark_buried_the_legacy_wood_logo() -> void:
	var image := _image(LOGO)
	assert_false(_has_color(image, LEGACY_WOOD), "madeira do logo antigo nao volta")
	assert_false(_has_color(image, LEGACY_AMBER), "olhos ambar violam a trava dos olhos brancos PUROS")

func test_boot_splash_is_night_with_mark_and_wordmark() -> void:
	var image := _image(SPLASH)
	assert_eq(image.get_pixel(0, 0), COLOR_NIGHT, "fundo noite #0d1117 (mesmo bg do loader HTML)")
	assert_gt(_count(image, COLOR_EYES), 400, "olhos brancos da marca e do wordmark presentes")
	assert_gt(_count(image, COLOR_MANE), 10000, "leitura laranja domina sobre o breu")

func test_icons_are_the_mark_over_night() -> void:
	for path: String in ["res://icon.png", "res://assets/icons/icon_512.png",
			"res://assets/icons/icon_180.png", "res://assets/icons/icon_144.png"]:
		var image := _image(path)
		assert_eq(image.get_pixel(0, 0), COLOR_NIGHT, "%s tem fundo noite" % path)
		assert_true(_has_color(image, COLOR_MANE), "%s carrega a juba laranja" % path)
		assert_true(_has_color(image, COLOR_EYES), "%s carrega os olhos brancos" % path)

func _count(image: Image, expected: Color) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				count += 1
	return count

func _has_color(image: Image, expected: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				return true
	return false
