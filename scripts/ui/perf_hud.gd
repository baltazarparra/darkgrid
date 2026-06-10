extends CanvasLayer
# Autoload registrado como PerfHud em project.godot.
# Sem class_name: conflita com o nome do autoload em Godot 4.
#
# Overlay de medição de performance (Fase 10 + PLANO-performance-60fps §3):
# FPS, frame-time médio e p95 (janela de ~2s — pega o SPIKE do frame de
# crítico, não só a média) e monitores de render (draw calls, nós). Só liga
# atrás de flag — `?perf` na URL (web) ou variável de ambiente CAIPORA_PERF
# (nativo) — e desligado não custa nada (process off, nenhum nó criado).
# É a régua do orçamento de 60fps em Android modesto.

const UPDATE_INTERVAL := 0.5
const SAMPLE_COUNT := 120  # janela de ~2s a 60fps para média/p95

var _label: Label
var _accum := 0.0
var _samples: PackedFloat32Array = PackedFloat32Array()
var _sample_index: int = 0
var _filled: int = 0

func _ready() -> void:
	layer = 127
	if not _enabled():
		set_process(false)
		return
	_samples.resize(SAMPLE_COUNT)
	_label = Label.new()
	_label.position = Vector2(8.0, 8.0)
	_label.add_theme_font_size_override("font_size", Constants.FONT_SM)
	_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _process(delta: float) -> void:
	_samples[_sample_index] = delta * 1000.0
	_sample_index = (_sample_index + 1) % SAMPLE_COUNT
	_filled = mini(_filled + 1, SAMPLE_COUNT)

	_accum += delta
	if _accum < UPDATE_INTERVAL:
		return
	_accum = 0.0
	var window := _samples.slice(0, _filled) if _filled < SAMPLE_COUNT else _samples
	_label.text = "%d fps  med %.1fms  p95 %.1fms\ndraw %d  nodes %d" % [
		int(Performance.get_monitor(Performance.TIME_FPS)),
		average(window),
		percentile(window, 0.95),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	]

## Percentil (0.0–1.0) por nearest-rank sobre a janela de amostras.
static func percentile(samples: PackedFloat32Array, fraction: float) -> float:
	if samples.is_empty():
		return 0.0
	var sorted := samples.duplicate()
	sorted.sort()
	var rank: int = clampi(ceili(fraction * sorted.size()) - 1, 0, sorted.size() - 1)
	return sorted[rank]

static func average(samples: PackedFloat32Array) -> float:
	if samples.is_empty():
		return 0.0
	var sum: float = 0.0
	for value in samples:
		sum += value
	return sum / samples.size()

func _enabled() -> bool:
	if not OS.get_environment("CAIPORA_PERF").is_empty():
		return true
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("location.search", true)
		return search is String and "perf" in (search as String)
	return false
