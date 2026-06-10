extends CanvasLayer
# Autoload registrado como PerfHud em project.godot.
# Sem class_name: conflita com o nome do autoload em Godot 4.
#
# Overlay de medição de performance (Fase 10): FPS + frame-time, atualizado a
# cada meio segundo. Só liga atrás de flag — `?perf` na URL (web) ou variável
# de ambiente CAIPORA_PERF (nativo) — e desligado não custa nada (process off,
# nenhum nó criado). É a régua do orçamento de 60fps em Android modesto.

const UPDATE_INTERVAL := 0.5

var _label: Label
var _accum := 0.0

func _ready() -> void:
	layer = 127
	if not _enabled():
		set_process(false)
		return
	_label = Label.new()
	_label.position = Vector2(8.0, 8.0)
	_label.add_theme_font_size_override("font_size", Constants.FONT_SM)
	_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _process(delta: float) -> void:
	_accum += delta
	if _accum < UPDATE_INTERVAL:
		return
	_accum = 0.0
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_label.text = "%d fps  %.1f ms" % [int(fps), frame_ms]

func _enabled() -> bool:
	if not OS.get_environment("CAIPORA_PERF").is_empty():
		return true
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("location.search", true)
		return search is String and "perf" in (search as String)
	return false
