class_name ControlsHud
extends CanvasLayer

# ─── Constants ─────────────────────────────────────
const SW: float = 1280.0
const SH: float = 720.0
const KEY_SZ: float = 40.0
const SPACE_W: float = 160.0
const GAP: float = 4.0
const MARGIN: float = 18.0

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 20

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Linha de baixo (↓ ← →) e linha de cima (↑)
	var y2: float = SH - MARGIN - KEY_SZ      # topo da linha de baixo
	var y1: float = y2 - KEY_SZ - GAP          # topo da linha de cima (↑)
	var cx: float = MARGIN + KEY_SZ + GAP      # centro horizontal do D-pad

	_key(root, "↑", cx - KEY_SZ * 0.5,          y1)
	_key(root, "←", cx - KEY_SZ * 1.5 - GAP,    y2)
	_key(root, "↓", cx - KEY_SZ * 0.5,          y2)
	_key(root, "→", cx + KEY_SZ * 0.5 + GAP,    y2)

	# Barra de espaço — direita inferior
	_key(root, "SPACE", SW - MARGIN - SPACE_W, y2, SPACE_W)

# ─── Private helpers ───────────────────────────────
func _key(parent: Control, label: String, x: float, y: float, w: float = KEY_SZ) -> void:
	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, KEY_SZ)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.88)
	style.border_color = Color(0.50, 0.44, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var lbl := Label.new()
	lbl.text = label
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
