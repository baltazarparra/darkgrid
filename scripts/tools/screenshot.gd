extends SceneTree

## Ferramenta de captura visual (dev only). Renderiza uma cena com janela real
## (precisa de DISPLAY, ex. WSLg :0) por N frames e salva um PNG. Reutilizada para
## validar mudanças visuais (UI, mapa, atmosfera, personagens).
##
## Uso:
##   DISPLAY=:0 godot --path . -s scripts/tools/screenshot.gd -- \
##       --scene=res://scenes/ui/main_menu.tscn --out=/tmp/shot.png [--frames=30]

var _out: String = "/tmp/caipora_shot.png"
var _target_frames: int = 30
var _frames: int = 0

func _initialize() -> void:
	var scene_path: String = "res://scenes/ui/main_menu.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.substr("--scene=".length())
		elif arg.begins_with("--out="):
			_out = arg.substr("--out=".length())
		elif arg.begins_with("--frames="):
			_target_frames = int(arg.substr("--frames=".length()))
	var packed: PackedScene = load(scene_path)
	root.add_child(packed.instantiate())

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= _target_frames:
		var img: Image = root.get_texture().get_image()
		img.save_png(_out)
		print("[screenshot] saved ", _out)
		return true  # quit
	return false
