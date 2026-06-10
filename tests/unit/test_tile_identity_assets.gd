extends GutTest

const TILE_SIZE := 32

const ATLAS_CONTRACTS := {
	"res://assets/sprites/tile_floor.png": Vector2i(128, 32),
	"res://assets/sprites/tile_wall.png": Vector2i(64, 32),
	"res://assets/sprites/tile_floor_church.png": Vector2i(128, 32),
	"res://assets/sprites/tile_wall_church.png": Vector2i(64, 32),
	"res://assets/sprites/tile_identity_contact_sheet.png": Vector2i(528, 608),
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

func test_forest_floor_keeps_caipora_accent_without_becoming_orange() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/tile_floor.png"))
	assert_false(image.is_empty(), "chao de mata carrega como Image")
	if image.is_empty():
		return
	var orange_pixels := _count_color(image, COLOR_ORANGE_DK) + _count_color(image, COLOR_ORANGE)
	var blood_pixels := _count_color(image, COLOR_BLOOD)
	assert_gt(orange_pixels + blood_pixels, 12, "chao tem assinatura laranja/sangue da identidade")
	assert_lt(orange_pixels, 180, "laranja fica como acento, nao tapete")

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

func _count_color(image: Image, expected: Color) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				count += 1
	return count
