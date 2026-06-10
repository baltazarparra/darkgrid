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

func _count_opaque_pixels(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				count += 1
	return count
