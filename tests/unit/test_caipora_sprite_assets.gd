extends GutTest

const SPRITE_PATHS: Array[String] = [
	"res://assets/sprites/player_idle.png",
	"res://assets/sprites/player_walk_1.png",
	"res://assets/sprites/player_walk_2.png",
	"res://assets/sprites/player_windup.png",
	"res://assets/sprites/player_strike.png",
	"res://assets/sprites/player_recover.png",
	"res://assets/sprites/player_idle_chama.png",
	"res://assets/sprites/player_walk_1_chama.png",
	"res://assets/sprites/player_walk_2_chama.png",
	"res://assets/sprites/player_windup_chama.png",
	"res://assets/sprites/player_strike_chama.png",
	"res://assets/sprites/player_recover_chama.png",
]

const PLAYER_IDLE := "res://assets/sprites/player_idle.png"
const PLAYER_IDLE_CHAMA := "res://assets/sprites/player_idle_chama.png"

const COLOR_MANE := Color8(255, 69, 0)
const COLOR_VOID := Color8(0, 0, 0)
const COLOR_EYES := Color8(255, 255, 255)
const COLOR_CRYSTAL := Color8(0, 250, 154)
const COLOR_CHAMA := Color8(255, 176, 50)

func test_caipora_sprite_contract_assets_are_96x96() -> void:
	for path: String in SPRITE_PATHS:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), Vector2(96, 96), "%s mantem contrato 96x96" % path)

func test_caipora_sprite_contract_assets_are_not_blank() -> void:
	for path: String in SPRITE_PATHS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_gt(_count_opaque_pixels(image), 180, "%s tem massa visual suficiente" % path)

func test_caipora_idle_keeps_concept_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_IDLE))
	assert_false(image.is_empty(), "idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_MANE), "idle preserva juba-capa laranja da prancha")
	assert_true(_has_color(image, COLOR_VOID), "idle preserva rosto-vazio preto")
	assert_true(_has_color(image, COLOR_EYES), "idle preserva olhos brancos puros")
	assert_true(_has_color(image, COLOR_CRYSTAL), "idle preserva cristal verde")

func test_caipora_idle_is_orange_black_silhouette_first() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_IDLE))
	assert_false(image.is_empty(), "idle carrega como Image")
	if image.is_empty():
		return
	var orange_pixels := _count_color(image, COLOR_MANE) + _count_color(image, Color8(139, 42, 0))
	var black_pixels := _count_color(image, COLOR_VOID)
	var green_pixels := _count_color(image, COLOR_CRYSTAL)
	assert_gt(orange_pixels, black_pixels, "juba-capa laranja domina a leitura da silhueta")
	assert_lte(green_pixels, 12, "cristal verde fica mínimo; cajado lê preto como na referência")

func test_caipora_chama_idle_keeps_fire_variant_color() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_IDLE_CHAMA))
	assert_false(image.is_empty(), "idle CHAMA carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_CHAMA), "CHAMA preserva juba incendiada")
	assert_true(_has_color(image, COLOR_VOID), "CHAMA preserva rosto-vazio preto")
	assert_true(_has_color(image, COLOR_EYES), "CHAMA preserva olhos brancos puros")

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

func _count_color(image: Image, expected: Color) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				count += 1
	return count
