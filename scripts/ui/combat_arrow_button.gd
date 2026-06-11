class_name CombatArrowButton
extends BaseButton

# Botão direcional do D-pad de COMBATE, na identidade da protagonista: garra-chevron
# pixel-art na paleta da juba (laranja sobre vazio preto, outline duro, cantos retos),
# que flasheia nos tons de CHAMA ao pressionar. Substitui os Buttons de texto "↑←↓→"
# que liam como teclas de teclado.
#
# Ergonomia: o retângulo do Control cobre o cluster INTEIRO do D-pad (os 4 irmãos se
# sobrepõem) e `_has_point` aceita apenas o gajo (wedge) de 90° da própria direção —
# como um D-pad físico, toda a área do pad é clicável, dividida em quadrantes, com
# uma zona morta pequena no centro. O visual (plate) é menor que a área de toque.
#
# Este nó é APENAS visual + hit-test. A injeção dual de input, o háptico e o SFX
# permanecem no ControlsHud, dono do contrato com o jogo (mesmo split do FloatingDpad).

# ─── Constants ─────────────────────────────────────
const GRID := 16
# Glifo em pixel-art autoral (célula a célula, sem polígono — leitura chapada).
# Desenhado apontando para CIMA; as outras direções rotacionam no _draw.
# '.'=vazio  'K'=outline preto  'O'=juba clara  'D'=juba escura.
const GLYPH: PackedStringArray = [
	"................",
	"......KKKK......",
	".....KKOOKK.....",
	"....KKOOOOKK....",
	"...KKOOOOOOKK...",
	"..KKOOODDOOOKK..",
	".KKOOODDDDOOOKK.",
	"KKOOODDKKDDOOOKK",
	"KOOODDKKKKDDOOOK",
	"KOODDKK..KKDDOOK",
	"KODDKK....KKDDOK",
	"KDDKK......KKDDK",
	"KDKK........KKDK",
	"KKK..........KKK",
	"................",
	"................",
]

# Respiro entre o glifo e a borda da plate, em células da grade.
const GLYPH_PAD_CELLS := 2
const PLATE_BG := Color(0.04, 0.025, 0.025, 0.92)
const PLATE_BG_PRESSED := Color(0.0, 0.0, 0.0, 0.98)

# Press: o glifo avança 1.5 células na própria direção (bote, não afundamento).
const PRESS_LUNGE_CELLS := 1.5
const RELEASE_SECONDS := 0.10
# Anel de impacto: contorno duro expandindo da borda da plate, alpha em degraus
# (sem gradiente suave — acabamento chapado).
const RING_SECONDS := 0.16
const RING_GROW_CELLS := 2.5
const RING_ALPHA_STEPS := 4

const _ORIENTATIONS: Dictionary = {
	"ui_up": 0, "ui_right": 1, "ui_down": 2, "ui_left": 3,
}
const _LUNGE_DIRS: Array = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]

# ─── State ─────────────────────────────────────────
var action: String = "ui_up":
	set(value):
		action = value
		_orientation = _ORIENTATIONS.get(value, 0)
		queue_redraw()

var _orientation: int = 0
# Geometria local (definida pelo ControlsHud no layout).
var _plate_rect: Rect2 = Rect2()
var _wedge_center: Vector2 = Vector2.ZERO
var _dead_radius: float = 0.0

var _press_amount: float = 0.0:
	set(value):
		_press_amount = value
		queue_redraw()
var _ring_amount: float = 1.0:
	set(value):
		_ring_amount = value
		queue_redraw()
var _release_tween: Tween = null
var _ring_tween: Tween = null


# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	button_down.connect(_on_visual_press)
	button_up.connect(_on_visual_release)


# ─── Public API ────────────────────────────────────
## Geometria do botão em coordenadas LOCAIS: plate desenhada, centro do cluster
## (vértice dos gajos) e raio da zona morta central.
func configure(plate_rect: Rect2, wedge_center: Vector2, dead_radius: float) -> void:
	_plate_rect = plate_rect
	_wedge_center = wedge_center
	_dead_radius = dead_radius
	queue_redraw()


## Zera o estado visual de press (usado quando o HUD solta todas as actions à força).
func clear_feedback() -> void:
	if _release_tween != null:
		_release_tween.kill()
	if _ring_tween != null:
		_ring_tween.kill()
	_press_amount = 0.0
	_ring_amount = 1.0


# ─── Hit-test em gajo (wedge) ──────────────────────
func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	var v := point - _wedge_center
	if v.length() < _dead_radius:
		return false
	match _orientation:
		0: return -v.y >= absf(v.x)
		1: return v.x >= absf(v.y)
		2: return v.y >= absf(v.x)
		_: return -v.x >= absf(v.y)


# ─── Feedback visual ───────────────────────────────
func _on_visual_press() -> void:
	if _release_tween != null:
		_release_tween.kill()
	if _ring_tween != null:
		_ring_tween.kill()
	# Resposta instantânea no press (zero latência percebida); o anel expande.
	_press_amount = 1.0
	_ring_amount = 0.0
	_ring_tween = create_tween()
	_ring_tween.tween_property(self, "_ring_amount", 1.0, RING_SECONDS)


func _on_visual_release() -> void:
	if _release_tween != null:
		_release_tween.kill()
	_release_tween = create_tween()
	_release_tween.set_trans(Tween.TRANS_SINE)
	_release_tween.set_ease(Tween.EASE_OUT)
	_release_tween.tween_property(self, "_press_amount", 0.0, RELEASE_SECONDS)


# ─── Draw ──────────────────────────────────────────
func _draw() -> void:
	if _plate_rect.size.x <= 0.0:
		return
	var border_w := float(Constants.UI_BORDER_WIDTH)
	var cell := (_plate_rect.size.x - border_w * 2.0) / float(GRID + GLYPH_PAD_CELLS * 2)

	# Plate: vazio preto com borda dura (cantos retos — direção de arte da UI).
	var border_color := Constants.COLOR_JUBA_DARK.lerp(Constants.COLOR_JUBA, _press_amount)
	draw_rect(_plate_rect, border_color, true)
	var bg := PLATE_BG.lerp(PLATE_BG_PRESSED, _press_amount)
	draw_rect(_plate_rect.grow(-border_w), bg, true)

	# Anel de impacto: contorno expandindo da plate, alpha quantizado em degraus.
	if _ring_amount < 1.0:
		var alpha := floorf((1.0 - _ring_amount) * RING_ALPHA_STEPS) / float(RING_ALPHA_STEPS)
		if alpha > 0.0:
			var ring := _plate_rect.grow(_ring_amount * RING_GROW_CELLS * cell)
			var ring_color := Constants.COLOR_JUBA
			ring_color.a = alpha
			draw_rect(ring, ring_color, false, maxf(border_w * 0.5, 1.0))

	# Glifo: célula a célula, rotacionado para a direção; no press, troca a paleta
	# para CHAMA e avança ("bote") na direção do comando.
	var bright := Constants.COLOR_JUBA.lerp(Constants.COLOR_CHAMA_CORE, _press_amount)
	var dark := Constants.COLOR_JUBA_DARK.lerp(Constants.COLOR_CHAMA_HOT, _press_amount)
	var lunge: Vector2 = _LUNGE_DIRS[_orientation] * (PRESS_LUNGE_CELLS * cell * _press_amount)
	var origin := _plate_rect.position + Vector2.ONE * (border_w + GLYPH_PAD_CELLS * cell) + lunge
	# Overlap mínimo entre células vizinhas: mata as emendas de float sem borrar.
	var cell_size := Vector2.ONE * (cell + 0.5)

	for r in GRID:
		var row := GLYPH[r]
		for c in GRID:
			var ch := row[c]
			if ch == ".":
				continue
			var color: Color
			match ch:
				"O": color = bright
				"D": color = dark
				_: color = Color.BLACK
			var cell_pos := _rotated_cell(r, c)
			draw_rect(Rect2(origin + cell_pos * cell, cell_size), color, true)


## Mapeia a célula (r, c) do glifo "para cima" na posição (x, y) da orientação atual.
func _rotated_cell(r: int, c: int) -> Vector2:
	match _orientation:
		1: return Vector2(float(GRID - 1 - r), float(c))
		2: return Vector2(float(GRID - 1 - c), float(GRID - 1 - r))
		3: return Vector2(float(r), float(GRID - 1 - c))
		_: return Vector2(float(c), float(r))
