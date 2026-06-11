extends SceneTree

## Captura dev-only do Santuário dos Encantados: o acampamento (hub jogável) com N
## bosses libertados — gate visual de leitura da Etapa 3 (a Caipora ainda domina a
## tela? cards legíveis? espíritos e camadas no quadro?). Precisa de DISPLAY (Xvfb).
## Uso: xvfb-run -a godot --path . --resolution 393x852 \
##     -s scripts/tools/preview_camp_spirits.gd -- --freed=4 --out=/tmp/santuario.png
##   --freed=N  liberta os encantados das fases 1..N (0 = acampamento original)
##   --frames=M frames antes da captura (default 90 — partículas/pulsos assentam)

var _out: String = "/tmp/santuario.png"
var _freed: int = 0
var _wait: int = 90
var _frames: int = 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr("--out=".length())
		elif arg.begins_with("--freed="):
			_freed = clampi(int(arg.substr("--freed=".length())), 0, 4)
		elif arg.begins_with("--frames="):
			_wait = int(arg.substr("--frames=".length()))

func _process(_delta: float) -> bool:
	_frames += 1
	# No frame 1 (NÃO em _initialize): os autoloads só rodam _ready depois do
	# _initialize — setar antes faria o load_progress() do MetaProgression
	# sobrescrever o estado do preview. Só em memória, sem save (não toca o
	# savegame do dev).
	if _frames == 1:
		var meta: Node = root.get_node("MetaProgression")
		var freed: Array[int] = []
		for phase: int in range(1, _freed + 1):
			freed.append(phase)
		meta.freed_bosses = freed
		var hub: Node = (load("res://scenes/hub/hub.tscn") as PackedScene).instantiate()
		root.add_child(hub)
	if _frames >= _wait:
		_dump_spirits()
		root.get_texture().get_image().save_png(_out)
		print("[preview] saved ", _out)
		return true
	return false

# Dump de depuração: um espírito fora do quadro/invisível aparece aqui antes de
# aparecer no olho — posições em world px e estado do sprite.
func _dump_spirits() -> void:
	var hub: Node = null
	for c: Node in root.get_children():
		if c.has_node("Objects"):
			hub = c
	if hub == null:
		print("[preview] hub não encontrado")
		return
	for n: Node in hub.get_node("Objects").get_children():
		var script: Script = n.get_script()
		var path := script.resource_path if script != null else "<sem script>"
		var pos := str((n as Node2D).global_position) if n is Node2D else "-"
		print("[preview] obj %s script=%s pos=%s" % [n.name, path.get_file(), pos])
