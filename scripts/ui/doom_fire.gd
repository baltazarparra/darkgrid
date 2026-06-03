class_name DoomFire
extends CanvasLayer

# ─── Constants ─────────────────────────────────────
const COLS: int = 160
const ROWS: int = 90
const SCALE: int = 8

# Dark doom fire: preto transparente → roxo escuro → carmesim → vermelho sangue
const PALETTE: Array[Color] = [
	Color(0.00, 0.00, 0.00, 0.00),
	Color(0.01, 0.00, 0.02, 1.00),
	Color(0.03, 0.00, 0.05, 1.00),
	Color(0.05, 0.00, 0.09, 1.00),
	Color(0.08, 0.00, 0.12, 1.00),
	Color(0.11, 0.00, 0.14, 1.00),
	Color(0.15, 0.00, 0.14, 1.00),
	Color(0.19, 0.00, 0.13, 1.00),
	Color(0.23, 0.00, 0.11, 1.00),
	Color(0.27, 0.00, 0.08, 1.00),
	Color(0.31, 0.00, 0.06, 1.00),
	Color(0.35, 0.00, 0.04, 1.00),
	Color(0.38, 0.00, 0.02, 1.00),
	Color(0.41, 0.00, 0.01, 1.00),
	Color(0.43, 0.01, 0.01, 1.00),
	Color(0.45, 0.01, 0.01, 1.00),
	Color(0.47, 0.01, 0.01, 1.00),
	Color(0.49, 0.02, 0.01, 1.00),
	Color(0.51, 0.02, 0.01, 1.00),
	Color(0.52, 0.02, 0.01, 1.00),
	Color(0.50, 0.02, 0.01, 1.00),
	Color(0.46, 0.02, 0.01, 1.00),
	Color(0.41, 0.01, 0.00, 1.00),
	Color(0.36, 0.01, 0.00, 1.00),
	Color(0.31, 0.01, 0.00, 1.00),
	Color(0.26, 0.00, 0.00, 1.00),
	Color(0.21, 0.00, 0.00, 1.00),
	Color(0.17, 0.00, 0.00, 1.00),
	Color(0.13, 0.00, 0.00, 1.00),
	Color(0.09, 0.00, 0.00, 1.00),
	Color(0.06, 0.00, 0.00, 1.00),
	Color(0.04, 0.00, 0.00, 1.00),
	Color(0.02, 0.00, 0.00, 1.00),
	Color(0.01, 0.00, 0.00, 1.00),
	Color(0.00, 0.00, 0.00, 0.80),
	Color(0.00, 0.00, 0.00, 0.40),
	Color(0.00, 0.00, 0.00, 0.00),
]

# ─── State ─────────────────────────────────────────
var _grid: PackedInt32Array
var _image: Image
var _texture: ImageTexture
var _sprite: Sprite2D
var _fire_tick: int = 0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = -10

	_grid = PackedInt32Array()
	_grid.resize(COLS * ROWS)
	for col in COLS:
		_grid[(ROWS - 1) * COLS + col] = 36

	_image = Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)

	_sprite = Sprite2D.new()
	_sprite.texture = _texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(COLS * SCALE / 2.0, ROWS * SCALE / 2.0)
	_sprite.scale = Vector2(SCALE, SCALE)
	add_child(_sprite)

func _process(_delta: float) -> void:
	_fire_tick = (_fire_tick + 1) % 3
	if _fire_tick != 0:
		return
	_update_fire()
	_blit_image()

# ─── Private helpers ───────────────────────────────
func _update_fire() -> void:
	for row in range(ROWS - 1):
		for col in COLS:
			var src: int = (row + 1) * COLS + col
			var val: int = _grid[src]
			if val == 0:
				_grid[row * COLS + col] = 0
				continue
			var drift: int = (randi() & 1)
			var target: int = clampi(col - drift + (randi() & 1), 0, COLS - 1)
			var decay: int = randi() % 3
			_grid[row * COLS + target] = maxi(0, val - decay)

func _blit_image() -> void:
	for row in ROWS:
		for col in COLS:
			_image.set_pixel(col, row, PALETTE[_grid[row * COLS + col]])
	_texture.update(_image)
