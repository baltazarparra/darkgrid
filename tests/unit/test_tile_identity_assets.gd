extends GutTest

const TILE_SIZE := 32

const ATLAS_CONTRACTS := {
	"res://assets/sprites/tile_floor.png": Vector2i(128, 32),
	"res://assets/sprites/tile_wall.png": Vector2i(64, 32),
	"res://assets/sprites/tile_floor_church.png": Vector2i(128, 32),
	"res://assets/sprites/tile_wall_church.png": Vector2i(64, 32),
	"res://assets/sprites/tile_shade.png": Vector2i(96, 32),
	"res://assets/sprites/tile_identity_contact_sheet.png": Vector2i(528, 608),
	"res://assets/sprites/tile_identity_value_sheet.png": Vector2i(528, 608),
}

const COLOR_BLACK := Color8(0, 0, 0)
const COLOR_NIGHT := Color8(13, 17, 23)
const COLOR_ORANGE_DK := Color8(139, 42, 0)
const COLOR_ORANGE := Color8(255, 69, 0)
const COLOR_BLOOD := Color8(139, 0, 0)
const COLOR_CRYSTAL := Color8(0, 250, 154)

func test_tile_identity_atlases_keep_expected_dimensions() -> void:
	for path: String in ATLAS_CONTRACTS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_eq(Vector2i(image.get_width(), image.get_height()), ATLAS_CONTRACTS[path],
			"%s preserva contrato de tamanho" % path)

func test_forest_wall_reads_as_dark_blocking_mass() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_wall.png"))
	assert_false(image.is_empty(), "parede de mata carrega como Image")
	if image.is_empty():
		return
	var black_pixels := _count_color(image, COLOR_BLACK)
	var night_pixels := _count_color(image, COLOR_NIGHT)
	assert_gt(black_pixels + night_pixels, 350, "parede de mata tem massa escura dominante")

func test_floor_and_wall_have_functional_value_separation() -> void:
	var forest_floor := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor.png"))
	var forest_wall := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_wall.png"))
	var church_floor := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor_church.png"))
	var church_wall := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_wall_church.png"))
	assert_false(forest_floor.is_empty(), "chao de floresta carrega")
	assert_false(forest_wall.is_empty(), "parede de floresta carrega")
	assert_false(church_floor.is_empty(), "chao de igreja carrega")
	assert_false(church_wall.is_empty(), "parede de igreja carrega")
	if forest_floor.is_empty() or forest_wall.is_empty() or church_floor.is_empty() or church_wall.is_empty():
		return
	assert_gt(_mean_luminance(forest_floor) - _mean_luminance(forest_wall), 4.0,
		"floresta separa chao caminhavel da parede por valor")
	assert_lt(_mean_luminance(forest_floor), 30.0,
		"piso da floresta fica no breu e nao compete com os atores")
	assert_gt(_mean_luminance(church_floor) - _mean_luminance(church_wall), 4.0,
		"igreja separa piso escuro da parede/sombra por valor")
	assert_lt(_mean_luminance(church_floor), 38.0,
		"piso da igreja fica no breu e nao compete com os atores")

func test_forest_floor_keeps_caipora_accent_without_becoming_orange() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor.png"))
	assert_false(image.is_empty(), "chao de mata carrega como Image")
	if image.is_empty():
		return
	var orange_pixels := _count_color(image, COLOR_ORANGE_DK) + _count_color(image, COLOR_ORANGE)
	var blood_pixels := _count_color(image, COLOR_BLOOD)
	assert_gt(orange_pixels + blood_pixels, 12, "chao tem assinatura laranja/sangue da identidade")
	assert_lt(orange_pixels, 180, "laranja fica como acento, nao tapete")
	assert_lt(_count_color(image, COLOR_BLACK), image.get_width() * image.get_height() / 2,
		"chao usa preto como breu, mas ainda preserva textura caminhavel")

func test_forest_floor_caps_peak_value_for_ground_read() -> void:
	# Boas práticas de tiles top-down: o piso é a camada de menor contraste.
	# Nenhum pixel do chão pode passar de osso/laranja vivo/branco — acentos
	# ficam abaixo de lum 80 (BLOOD=29.6, ORANGE_DK=59.6 passam; BONE=112 não).
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor.png"))
	assert_false(image.is_empty(), "chao de mata carrega como Image")
	if image.is_empty():
		return
	var peak := 0.0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			peak = maxf(peak, (c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722) * 255.0)
	assert_lt(peak, 80.0, "piso da mata nao tem pixel-confete acima da faixa de chao")

func test_church_tiles_are_corrupted_not_clean_stone() -> void:
	var floor := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor_church.png"))
	var wall := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_wall_church.png"))
	assert_false(floor.is_empty(), "chao da igreja carrega")
	assert_false(wall.is_empty(), "parede da igreja carrega")
	if floor.is_empty() or wall.is_empty():
		return
	assert_gt(_count_color(floor, COLOR_BLOOD), 20, "chao da igreja preserva sangue ritual")
	assert_gt(_count_color(wall, COLOR_BLACK), 140, "parede da igreja tem sombra/raiz preta dominante")

func test_tiles_do_not_steal_crystal_green_identity() -> void:
	for path: String in [
		"res://assets/sprites/tile_floor.png",
		"res://assets/sprites/tile_wall.png",
		"res://assets/sprites/tile_floor_church.png",
		"res://assets/sprites/tile_wall_church.png",
	]:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_eq(_count_color(image, COLOR_CRYSTAL), 0,
			"%s nao usa verde-cristal da Caipora como cor de mapa" % path)

func test_floor_shade_atlas_uses_pixel_art_alpha_steps() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_shade.png"))
	assert_false(image.is_empty(), "atlas de sombra do chao carrega")
	if image.is_empty():
		return
	assert_gt(_count_alpha_over(image, 0.0), 200, "tile_shade tem pixels de oclusao")
	assert_eq(_count_alpha_over(image, 0.75), 0, "tile_shade nunca vira preto solido")
	assert_gt(_count_alpha_in_tile(image, 0, 0.40), 120, "edge tem degrau forte")
	assert_gt(_count_alpha_in_tile(image, 1, 0.25), 100, "corner tem oclusao em L")
	assert_gt(_count_alpha_in_tile(image, 2, 0.50), 150, "edge_deep aprofunda corredores")

func _count_color(image: Image, expected: Color) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				count += 1
	return count

func _mean_luminance(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			total += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			count += 1
	if count == 0:
		return 0.0
	return total / float(count) * 255.0

func _count_alpha_over(image: Image, threshold: float) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > threshold:
				count += 1
	return count

func _count_alpha_in_tile(image: Image, tile_index: int, threshold: float) -> int:
	var count := 0
	var start_x := tile_index * TILE_SIZE
	for y: int in range(TILE_SIZE):
		for x: int in range(start_x, start_x + TILE_SIZE):
			if image.get_pixel(x, y).a > threshold:
				count += 1
	return count
