class_name DoomFire
extends CanvasLayer

# ─── Constants ─────────────────────────────────────
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
var _cols: int = 0
var _rows: int = 0
var _vp_size: Vector2 = Vector2.ZERO
var _grid: PackedInt32Array
var _image: Image
var _texture: ImageTexture
var _sprite: Sprite2D
var _fire_tick: int = 0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = -10
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_rebuild(get_viewport().get_visible_rect().size)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp == _vp_size:
		return
	_rebuild(vp)

func _rebuild(vp: Vector2) -> void:
	_vp_size = vp
	_cols = ceili(vp.x / float(SCALE))
	_rows = ceili(vp.y / float(SCALE))
	_grid = PackedInt32Array()
	_grid.resize(_cols * _rows)
	for col in _cols:
		_grid[(_rows - 1) * _cols + col] = 36
	_image = Image.create(_cols, _rows, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	_sprite.texture = _texture
	_sprite.position = Vector2(_cols * SCALE / 2.0, _rows * SCALE / 2.0)
	_sprite.scale = Vector2(SCALE, SCALE)

func _process(_delta: float) -> void:
	_fire_tick = (_fire_tick + 1) % 3
	if _fire_tick != 0:
		return
	_update_fire()
	_blit_image()

# ─── Private helpers ───────────────────────────────
func _update_fire() -> void:
	for row in range(_rows - 1):
		for col in _cols:
			var src: int = (row + 1) * _cols + col
			var val: int = _grid[src]
			if val == 0:
				_grid[row * _cols + col] = 0
				continue
			var drift: int = (randi() & 1)
			var target: int = clampi(col - drift + (randi() & 1), 0, _cols - 1)
			var decay: int = randi() % 3
			_grid[row * _cols + target] = maxi(0, val - decay)

func _blit_image() -> void:
	for row in _rows:
		for col in _cols:
			_image.set_pixel(col, row, PALETTE[_grid[row * _cols + col]])
	_texture.update(_image)
