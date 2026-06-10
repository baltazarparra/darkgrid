extends CanvasLayer
# Autoload registrado como PerfOverlay em project.godot.
# Sem class_name: conflita com o nome do autoload em Godot 4.
#
# Overlay de medição de performance (Fase 0.1 do PLANO-performance-60fps):
# FPS, frame-time médio/p95 e monitores de render, para baseline e A/B em
# device real. Custo zero quando desligado (_process desativado, nada
# construído). Liga via ?perf=1 na URL (export web) ou F3 (desktop).

# ─── Constants ─────────────────────────────────────
const SAMPLE_COUNT: int = 120         # janela de ~2s a 60fps
const REFRESH_INTERVAL: float = 0.25  # texto atualiza a 4Hz: nada de alocar string por frame
const FONT_SIZE: int = 10

# ─── State ─────────────────────────────────────────
var _samples: PackedFloat32Array = PackedFloat32Array()
var _sample_index: int = 0
var _filled: int = 0
var _refresh_timer: float = 0.0
var _label: Label = null

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 100  # acima do HUD/D-pad (20), abaixo do PortraitGuard (128)
	set_process(false)
	if _wants_overlay():
		_enable()

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		_disable() if is_processing() else _enable()

func _process(delta: float) -> void:
	_samples[_sample_index] = delta * 1000.0
	_sample_index = (_sample_index + 1) % SAMPLE_COUNT
	_filled = mini(_filled + 1, SAMPLE_COUNT)

	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = REFRESH_INTERVAL
	_label.text = _build_report()

# ─── Public helpers (testáveis) ────────────────────
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

# ─── Private helpers ───────────────────────────────
func _wants_overlay() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	return search is String and (search as String).contains("perf=1")

func _enable() -> void:
	if _label == null:
		_build_label()
	_samples.resize(SAMPLE_COUNT)
	_samples.fill(0.0)
	_sample_index = 0
	_filled = 0
	_refresh_timer = 0.0
	_label.visible = true
	set_process(true)

func _disable() -> void:
	set_process(false)
	if _label != null:
		_label.visible = false

func _build_label() -> void:
	_label = Label.new()
	_label.position = Vector2(8.0, 8.0)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func _build_report() -> String:
	var window := _samples.slice(0, _filled) if _filled < SAMPLE_COUNT else _samples
	return "fps %d  med %.1fms  p95 %.1fms\ndraw %d  obj %d  nodes %d" % [
		Engine.get_frames_per_second(),
		average(window),
		percentile(window, 0.95),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	]
