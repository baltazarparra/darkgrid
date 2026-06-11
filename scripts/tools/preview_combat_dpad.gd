extends SceneTree

## Captura dev-only do D-pad de combate (precisa de DISPLAY; Xvfb serve). Salva o
## frame inteiro em --out e um recorte 2x do pad em <out>_crop.png; --press simula
## o feedback visual + injeção de uma direção antes da captura.
## Uso: xvfb-run -a godot --path . --resolution 393x852 \
##     -s scripts/tools/preview_combat_dpad.gd -- --out=/tmp/dpad.png [--press=ui_right]

var _out: String = "/tmp/dpad.png"
var _press: String = ""
var _frames: int = 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr("--out=".length())
		elif arg.begins_with("--press="):
			_press = arg.substr("--press=".length())
func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		root.get_node("MetaProgression").touch_controls_mode = "always"
		var bus: Node = root.get_node("SignalBus")
		bus.screen_changed.emit(bus.Screen.ARENA)
	if _frames == 20 and _press != "":
		var hud: Node = root.get_node("TouchControls")
		for btn in hud._keys:
			if btn.action == _press:
				btn._on_visual_press()
		hud._on_pressed(_press)
	if _frames >= 26:
		var hud: Node = root.get_node("TouchControls")
		var img: Image = root.get_texture().get_image()
		# _dpad_rect vive no canvas esticado; o backbuffer está em pixels de janela.
		var vp: Vector2 = hud.get_viewport().get_visible_rect().size
		var factor: Vector2 = Vector2(img.get_width(), img.get_height()) / vp
		var rect: Rect2 = hud._dpad_rect.grow(40.0)
		rect = Rect2(rect.position * factor, rect.size * factor).intersection(
			Rect2(0, 0, img.get_width(), img.get_height()))
		var crop := img.get_region(Rect2i(rect))
		crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(_out.get_basename() + "_crop.png")
		img.save_png(_out)
		print("[preview] saved ", _out)
		return true
	return false
