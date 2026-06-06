class_name FragmentCounter
extends Control

# Contador de fragmentos compacto: um glifo de estilhaço âmbar + o número.
# Substitui o antigo `"+".repeat(n)` (que transbordava a tela com muitos fragmentos).
# Largura praticamente constante: cresce só com a contagem de dígitos.

# ─── Constants ─────────────────────────────────────
const SHARD_W: float = 9.0    # meia-largura do estilhaço (proporcional ao glyph)
const SHARD_H: float = 13.0   # meia-altura
const GAP: float = 8.0        # respiro entre glifo e número

# ─── State ─────────────────────────────────────────
var _count: int = 0
var _glyph_size: float = 1.0
var _label: Label
var _pop_tween: Tween

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	add_child(_label)
	_relayout()

# ─── Public API ────────────────────────────────────
func set_count(value: int) -> void:
	var grew: bool = value > _count
	_count = maxi(value, 0)
	if _label != null:
		_label.text = str(_count)
	_relayout()
	queue_redraw()
	if grew:
		_pop()

func configure_size(font_size: int) -> void:
	_glyph_size = clampf(float(font_size) / float(Constants.FONT_MD), 0.7, 1.6)
	if _label != null:
		_label.add_theme_font_size_override("font_size", font_size)
	_relayout()
	queue_redraw()

# ─── Internals ─────────────────────────────────────
func _shard_width() -> float:
	return SHARD_W * _glyph_size

func _shard_height() -> float:
	return SHARD_H * _glyph_size

func _relayout() -> void:
	if _label == null:
		return
	var glyph_box: float = _shard_width() * 2.0
	var h: float = maxf(_shard_height() * 2.0, _label.get_minimum_size().y)
	_label.position = Vector2(glyph_box + GAP, 0.0)
	_label.size = Vector2(_label.get_minimum_size().x, h)
	custom_minimum_size = Vector2(glyph_box + GAP + _label.get_minimum_size().x, h)
	size = custom_minimum_size

func _pop() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	pivot_offset = Vector2(_shard_width(), size.y * 0.5)
	scale = Vector2(1.25, 1.25)
	_pop_tween = create_tween()
	_pop_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, 0.25)

# ─── Drawing ───────────────────────────────────────
func _draw() -> void:
	var w: float = _shard_width()
	var h: float = _shard_height()
	var cx: float = w
	var cy: float = size.y * 0.5
	# cristal/estilhaço: losango vertical alongado
	var pts: PackedVector2Array = [
		Vector2(cx, cy - h),
		Vector2(cx + w, cy - h * 0.15),
		Vector2(cx, cy + h),
		Vector2(cx - w, cy - h * 0.15),
	]
	draw_colored_polygon(pts, Constants.COLOR_AMBER)
	# faceta esquerda mais escura, para dar volume de gema
	var facet: PackedVector2Array = [
		Vector2(cx, cy - h),
		Vector2(cx, cy + h),
		Vector2(cx - w, cy - h * 0.15),
	]
	draw_colored_polygon(facet, Constants.COLOR_AMBER.darkened(0.35))
