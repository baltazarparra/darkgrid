class_name ControlsHud
extends CanvasLayer

# D-pad de toque flutuante (padrão MOBA/AAA mobile) que espelha as setas do teclado.
# Em repouso um pad "fantasma" fica no canto inferior direito; tocar em qualquer ponto
# da área de jogo recentra o pad sob o dedo, e o arrasto além da zona morta pressiona
# a direção (FloatingDpad cuida do gesto e do visual). Cada press/release dirige os
# DOIS consumidores de input do jogo:
#   - Input.action_press/release  -> estado polado por caipora.gd (movimento)
#   - Input.parse_input_event     -> evento recebido por timing_system._input (combate)
# Aparece apenas em dispositivos com tela de toque; no desktop o teclado é o controle.

# ─── Constants ─────────────────────────────────────
# Raio do pad como fração do lado menor do viewport, com piso acima dos 44pt da
# Apple HIG e teto para não dominar tablets.
const PAD_RADIUS_FRACTION: float = 0.17
const PAD_RADIUS_MIN: float = 56.0
const PAD_RADIUS_MAX: float = 120.0
const PAD_PORTRAIT_SCALE: float = 1.15
# Margem do pad em repouso (fantasma), em frações do raio.
const REST_MARGIN_FRACTION: float = 0.55

# Faixa do topo excluída da ativação: ali vivem HUD (barras, fragmentos) e o botão de
# áudio — um toque nessa faixa nunca deve invocar o pad.
const TOP_EXCLUSION_FRACTION: float = 0.18

# Sentinelas de ponteiro: índices de toque reais são >= 0.
const NO_POINTER: int = -1
const MOUSE_POINTER_INDEX: int = -1000

# Carimbo de build: logado uma vez no _ready(). Confirma, no console do navegador, que o
# dispositivo está rodando o build novo (e não um cache de CDN/PWA) ao iterar no mobile.
const _BUILD_TAG: String = "dpad-float-1"

# ─── State ─────────────────────────────────────────
# Telas em que o D-pad fica visível: toda exploração, toda arena e o acampamento jogável
# (HUB) — a Caipora caminha pelo acampamento entre fases, então ele é gameplay. Fora delas
# (menu, fim de jogo) ele é ocultado. Detectado por convenção de nome do enum Screen —
# qualquer EXPLORATION*/ARENA*/HUB conta como gameplay — para que uma fase nova (PHASE5…)
# não precise ser registrada aqui à mão e cause o D-pad sumir no mobile (regressão da Fase 4).
# Como este nó é um autoload persistente, o pad criado na exploração permanece vivo ao
# entrar no combate — sem recriação nem novo fade-in, eliminando o delay no início do turno.
const _GAMEPLAY_SCREEN_PREFIXES: Array = ["EXPLORATION", "ARENA", "HUB"]

var _root: Control = null
var _pad: FloatingDpad = null
var _pointer_index: int = NO_POINTER
var _active_screen_wants_dpad: bool = false
# Sticky: uma vez reconhecido como touch (por detecção OU por um toque real), permanece true
# pela sessão. Evita que uma leitura instável de _is_touch_device() (JavaScriptBridge.eval pode
# devolver null/0 durante uma troca de cena pesada no web) esconda o D-pad no meio do combate.
var _touch_detected: bool = false


# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
	layer = 20
	print("[caipora] build ", _BUILD_TAG)
	# Autoload persistente: a visibilidade é dirigida pela tela atual, não pelo boot.
	# Nada aparece no menu principal (que carrega direto, sem emitir screen_changed).
	SignalBus.screen_changed.connect(_on_screen_changed)


func _on_screen_changed(screen: SignalBus.Screen) -> void:
	_active_screen_wants_dpad = _is_gameplay_screen(screen)
	_refresh()


# Gameplay = qualquer tela cujo nome no enum começa por EXPLORATION ou ARENA. Cobre as fases
# existentes e quaisquer novas sem manutenção manual, evitando a regressão do D-pad oculto.
func _is_gameplay_screen(screen: SignalBus.Screen) -> bool:
	var name: String = SignalBus.Screen.keys()[screen]
	for prefix: String in _GAMEPLAY_SCREEN_PREFIXES:
		if name.begins_with(prefix):
			return true
	return false


func _input(event: InputEvent) -> void:
	# Um toque real é a prova definitiva de dispositivo touch: fixa o sticky e (re)exibe o D-pad,
	# mesmo que _root já exista e esteja oculto por uma detecção falha anterior.
	if _touch_detected:
		return
	if not _active_screen_wants_dpad:
		return
	if MetaProgression.get_touch_controls_mode() == "never":
		return
	if event is InputEventScreenTouch and event.pressed:
		_touch_detected = true
		_refresh()


# Gestos do pad flutuante. _unhandled_input (e não _input) para que toques consumidos
# pela GUI (diálogo, painéis) não invoquem o pad. Dois caminhos de ponteiro:
#   - ScreenTouch/ScreenDrag: o caminho real no mobile (multi-touch por índice).
#   - Mouse físico: só para testar no desktop com modo "always"; eventos de mouse
#     EMULADOS a partir de toque (DEVICE_ID_EMULATION) são ignorados para não
#     processar o mesmo dedo duas vezes.
func _unhandled_input(event: InputEvent) -> void:
	if _root == null or not _root.visible or _pad == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_try_begin(event.index, event.position)
		elif event.index == _pointer_index:
			_end_gesture()
	elif event is InputEventScreenDrag:
		if event.index == _pointer_index:
			_pad.drag_to(event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_try_begin(MOUSE_POINTER_INDEX, event.position)
			elif _pointer_index == MOUSE_POINTER_INDEX:
				_end_gesture()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if _pointer_index == MOUSE_POINTER_INDEX:
			_pad.drag_to(event.position)


# ─── Public API ────────────────────────────────────
func get_dpad_screen_rect() -> Rect2:
	# Vazio quando não há D-pad (desktop / sem touch) -> sem exclusão. Com o pad
	# flutuante o retângulo é DINÂMICO: a pose de repouso reserva o canto inferior
	# direito (bolhas de timing não nascem atrás do fantasma) e durante um gesto ele
	# acompanha o pad onde quer que o dedo esteja.
	if _root == null or _pad == null or not _root.visible:
		return Rect2()
	return _pad.get_screen_rect()


# ─── Private helpers ───────────────────────────────
# Decide a visibilidade SEM flapping: a detecção de toque é sticky-true, então uma leitura
# instável nunca esconde um D-pad já reconhecido. Só oculta fora de gameplay ou no modo "never".
func _resolve_should_show() -> bool:
	if not _active_screen_wants_dpad:
		return false
	match MetaProgression.get_touch_controls_mode():
		"never":
			return false
		"always":
			return true
		_:
			if not _touch_detected and _is_touch_device():
				_touch_detected = true
			return _touch_detected


func _refresh() -> void:
	if _resolve_should_show():
		_init_controls()
		_show()
	else:
		_hide()


func _show() -> void:
	if _root != null:
		_root.visible = true


func _hide() -> void:
	# Solta qualquer gesto em andamento ANTES de ocultar: uma troca de tela no meio de
	# um arrasto não pode deixar a action presa (Caipora andando sozinha na tela nova).
	_end_gesture()
	if _root != null:
		_root.visible = false


func _is_touch_device() -> bool:
	if OS.has_feature("web"):
		var result: Variant = JavaScriptBridge.eval(
			"navigator.maxTouchPoints > 0 || 'ontouchstart' in window", true
		)
		# JavaScriptBridge.eval pode retornar int(1), bool(true), ou null.
		# Tratamos qualquer truthy value como touch.
		if result != null and result != false and result != 0:
			return true

		# Fallback por user-agent se o eval falhar ou retornar 0/false.
		var ua: Variant = JavaScriptBridge.eval("navigator.userAgent", true)
		if ua is String:
			var ua_str: String = ua.to_lower()
			if ua_str.contains("iphone") or ua_str.contains("ipad") or ua_str.contains("ipod") or ua_str.contains("android"):
				return true

		# Fallback por viewport pequeno (< 1024px de largura = provavelmente mobile).
		var vp_w: Variant = JavaScriptBridge.eval("window.innerWidth", true)
		if vp_w is int or vp_w is float:
			if int(vp_w) < 1024:
				return true

		return false

	return DisplayServer.is_touchscreen_available()


func _init_controls() -> void:
	if _root != null:
		return

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_pad = FloatingDpad.new()
	_pad.direction_pressed.connect(_on_pressed)
	_pad.direction_released.connect(_on_released)
	_root.add_child(_pad)

	_layout_pad()
	get_viewport().size_changed.connect(_layout_pad)


func _layout_pad() -> void:
	if _pad == null:
		return

	var vp := get_viewport().get_visible_rect().size
	var radius: float = clampf(minf(vp.x, vp.y) * PAD_RADIUS_FRACTION, PAD_RADIUS_MIN, PAD_RADIUS_MAX)
	if _touch_detected and Constants.is_portrait(vp):
		radius *= PAD_PORTRAIT_SCALE

	var safe: Vector2 = _get_safe_margins()
	var margin: float = radius * REST_MARGIN_FRACTION

	# Fantasma de repouso no canto inferior DIREITO (polegar direito = direcional),
	# respeitando safe area (home bar / notch lateral).
	var rest := Vector2(
		vp.x - safe.x - margin - radius,
		vp.y - safe.y - margin - radius
	)

	# Onde o CENTRO do pad pode ficar quando recentrado sob o dedo: nunca vaza da
	# tela nas laterais e nunca entra na faixa do HUD nem na safe area de baixo.
	var clamp_min := Vector2(radius, vp.y * TOP_EXCLUSION_FRACTION)
	var clamp_max := Vector2(vp.x - radius, vp.y - safe.y - radius)
	var clamp_rect := Rect2(clamp_min, (clamp_max - clamp_min).max(Vector2.ZERO))

	_pad.configure(radius, rest, clamp_rect)


func _try_begin(index: int, point: Vector2) -> void:
	if _pointer_index != NO_POINTER:
		return
	if GameState.is_paused:
		return
	# Overlay "gire o dispositivo" cobre a tela sem pausar: nada de mover a Caipora
	# por trás dele.
	if PortraitGuard.visible:
		return
	if not _is_in_activation_zone(point):
		return
	_pointer_index = index
	_pad.begin_touch(point)
	get_viewport().set_input_as_handled()


func _end_gesture() -> void:
	if _pointer_index == NO_POINTER:
		return
	_pointer_index = NO_POINTER
	if _pad != null:
		_pad.end_touch()


func _is_in_activation_zone(point: Vector2) -> bool:
	var vp := get_viewport().get_visible_rect().size
	return point.y >= vp.y * TOP_EXCLUSION_FRACTION


func _get_safe_margins() -> Vector2:
	# Retorna Vector2(margin_right, margin_bottom) da safe area.
	var right: float = 0.0
	var bottom: float = 0.0

	# Em HTML5, tenta ler CSS safe-area-inset.
	if OS.has_feature("web"):
		var eval_right: Variant = JavaScriptBridge.eval(
			"parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sari') || 0)", true
		)
		var eval_bottom: Variant = JavaScriptBridge.eval(
			"parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sab') || 0)", true
		)
		# Fallback direto: tenta env() via CSS em um elemento temporário.
		if (eval_right == null or eval_right == 0) and (eval_bottom == null or eval_bottom == 0):
			var sar: Variant = JavaScriptBridge.eval(
				"(function(){var d=document.createElement('div');d.style.paddingRight='env(safe-area-inset-right)';d.style.paddingBottom='env(safe-area-inset-bottom)';d.style.position='absolute';document.body.appendChild(d);var s=getComputedStyle(d);var r=parseFloat(s.paddingRight)||0;var b=parseFloat(s.paddingBottom)||0;document.body.removeChild(d);return r+','+b;})()", true
			)
			if sar is String:
				var parts: PackedStringArray = sar.split(",")
				if parts.size() == 2:
					right = float(parts[0])
					bottom = float(parts[1])
		else:
			if eval_right is int or eval_right is float:
				right = float(eval_right)
			if eval_bottom is int or eval_bottom is float:
				bottom = float(eval_bottom)
	else:
		# Nativo: usar DisplayServer.get_display_safe_area().
		var safe_rect: Rect2 = DisplayServer.get_display_safe_area()
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		right = float(screen_size.x - safe_rect.end.x)
		bottom = float(screen_size.y - safe_rect.end.y)

	# Garantir mínimo de 28px (Apple HIG) quando em dispositivos touch.
	if _is_touch_device():
		right = maxf(right, 28.0)
		bottom = maxf(bottom, 28.0)

	return Vector2(right, bottom)


func _on_pressed(action: String) -> void:
	Input.action_press(action)
	_feed_event(action, true)


func _on_released(action: String) -> void:
	Input.action_release(action)
	_feed_event(action, false)


func _feed_event(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
