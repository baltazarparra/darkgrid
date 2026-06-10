class_name ControlsHud
extends CanvasLayer

# D-pad de toque que espelha as setas do teclado, para jogar em iPhone/iPad.
# As 4 setas controlam tudo: movimento na exploração e o timing no combate.
# Cada toque dirige os DOIS consumidores de input do jogo:
#   - Input.action_press/release  -> estado polado por caipora.gd (movimento)
#   - Input.parse_input_event     -> evento recebido por timing_system._input (combate)
# Aparece apenas em dispositivos com tela de toque; no desktop o teclado é o controle.

# ─── Constants ─────────────────────────────────────
# Tamanho como fração do lado menor do viewport (~15%, recomendação de ergonomia mobile),
# com piso bem acima dos 44pt da Apple HIG e teto para não estourar no iPad.
const KEY_FRACTION: float = 0.15
const KEY_MIN: float = 64.0
const KEY_MAX: float = 140.0

# Retrato é estreito: o cluster da cruz (3 teclas de largura) nunca pode dominar nem estourar
# a largura. Teto da largura do cluster como fração do viewport — se passar, a tecla encolhe
# proporcionalmente (mantém a proporção da cruz e o canto-direito alcançável pelo polegar).
const DPAD_MAX_WIDTH_FRACTION: float = 0.72

const OPACITY_IDLE: float = 0.45
const OPACITY_ACTIVE: float = 0.88
const FADE_IN_DURATION: float = 0.3
const PRESS_SCALE: float = 0.92
const SWIPE_DEAD_ZONE: float = 20.0
const SWIPE_THRESHOLD: float = 40.0
const MODE_EXPLORATION: int = 0
const MODE_COMBAT: int = 1
const COMBAT_KEY_FRACTION: float = 0.13
const COMBAT_KEY_MIN: float = 56.0
const COMBAT_KEY_MAX: float = 96.0
const COMBAT_MAX_WIDTH_FRACTION: float = 0.58

# Carimbo de build: logado uma vez no _ready(). Confirma, no console do navegador, que o
# dispositivo está rodando o build novo (e não um cache de CDN/PWA) ao iterar no mobile.
const _BUILD_TAG: String = "dpad-combat-arrows-1"

# Caminhos (não preload): como este script é autoload, ele é parseado já no boot — um
# preload de asset ainda não importado quebraria o parse. As texturas são carregadas com
# load() em runtime, dentro de _build_buttons(), que só roda numa tela de gameplay.
const _ENTRIES: Array = [
	["ui_up",    "res://assets/sprites/dpad_up.png"],
	["ui_left",  "res://assets/sprites/dpad_left.png"],
	["ui_down",  "res://assets/sprites/dpad_down.png"],
	["ui_right", "res://assets/sprites/dpad_right.png"],
]

# ─── State ─────────────────────────────────────────
# Telas em que o D-pad fica visível: toda exploração, toda arena e o acampamento jogável
# (HUB) — a Caipora caminha pelo acampamento entre fases, então ele é gameplay. Fora delas
# (menu, fim de jogo) ele é ocultado. Detectado por convenção de nome do enum Screen —
# qualquer EXPLORATION*/ARENA*/HUB conta como gameplay — para que uma fase nova (PHASE5…)
# não precise ser registrada aqui à mão e cause o D-pad sumir no mobile (regressão da Fase 4).
# Como este nó é um autoload persistente, o D-pad criado na exploração permanece vivo ao
# entrar no combate — sem recriação nem novo fade-in, eliminando o delay no início do turno.
const _GAMEPLAY_SCREEN_PREFIXES: Array = ["EXPLORATION", "ARENA", "HUB"]

var _root: Control = null
var _dpad_rect: Rect2 = Rect2()
var _keys: Array[BaseButton] = []
var _pressed_count: int = 0
var _active_screen_wants_dpad: bool = false
var _active_screen_is_arena: bool = false
var _button_mode: int = -1
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
	_active_screen_is_arena = _is_arena_screen(screen)
	_refresh()


# Gameplay = qualquer tela cujo nome no enum começa por EXPLORATION ou ARENA. Cobre as fases
# existentes e quaisquer novas sem manutenção manual, evitando a regressão do D-pad oculto.
func _is_gameplay_screen(screen: SignalBus.Screen) -> bool:
	var name: String = SignalBus.Screen.keys()[screen]
	for prefix: String in _GAMEPLAY_SCREEN_PREFIXES:
		if name.begins_with(prefix):
			return true
	return false


func _is_arena_screen(screen: SignalBus.Screen) -> bool:
	return SignalBus.Screen.keys()[screen].begins_with("ARENA")


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


# ─── Public API ────────────────────────────────────
func get_dpad_screen_rect() -> Rect2:
	# Vazio quando não há D-pad (desktop / sem touch) -> sem exclusão.
	return _dpad_rect if _root != null and _root.visible else Rect2()


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
	# Fade-in já ocorre uma única vez em _init_controls(); aqui só reexpomos sem reanimar.
	if _root != null:
		_sync_button_mode()
		_root.visible = true


func _hide() -> void:
	if _root != null:
		_root.visible = false
		_release_all_actions()
	_dpad_rect = Rect2()


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
	_root.modulate.a = 0.0
	add_child(_root)

	_build_buttons()
	_rebuild()
	get_viewport().size_changed.connect(_rebuild)

	# Fade-in suave.
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", OPACITY_IDLE, FADE_IN_DURATION)


func _build_buttons() -> void:
	_sync_button_mode()


func _sync_button_mode() -> void:
	if _root == null:
		return
	var desired_mode := MODE_COMBAT if _active_screen_is_arena else MODE_EXPLORATION
	if desired_mode == _button_mode:
		return
	_release_all_actions()
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	_keys.clear()
	_button_mode = desired_mode
	for entry in _ENTRIES:
		var action: String = entry[0]
		var btn: BaseButton = _make_combat_button(_label_for_action(action)) if _button_mode == MODE_COMBAT else _make_exploration_button(entry[1])
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.button_down.connect(_on_pressed.bind(action))
		btn.button_up.connect(_on_released.bind(action))
		_root.add_child(btn)
		_keys.append(btn)
	_rebuild()


func _make_exploration_button(texture_path: String) -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal = load(texture_path) as Texture2D
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	return btn


func _make_combat_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", Constants.FONT_MD)
	btn.add_theme_color_override("font_color", Constants.COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", Constants.COLOR_AMBER)
	btn.add_theme_stylebox_override("normal", _combat_style(false))
	btn.add_theme_stylebox_override("hover", _combat_style(false))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", _combat_style(true))
	return btn


func _combat_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.98 if pressed else 0.90)
	style.border_color = Constants.COLOR_AMBER if pressed else Color(0.50, 0.44, 0.62, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _label_for_action(action: String) -> String:
	match action:
		"ui_up": return "↑"
		"ui_left": return "←"
		"ui_down": return "↓"
		"ui_right": return "→"
	return "?"


func _release_all_actions() -> void:
	for entry in _ENTRIES:
		Input.action_release(entry[0])
	_pressed_count = 0


func _rebuild() -> void:
	if _root == null or _keys.is_empty():
		return
	if _button_mode == MODE_COMBAT:
		_rebuild_combat()
		return

	var vp := get_viewport().get_visible_rect().size
	var key: float = clampf(minf(vp.x, vp.y) * KEY_FRACTION, KEY_MIN, KEY_MAX)

	# Mobile: retrato → 1.5x (−25% vs 2.0 original); paisagem → 1.3x.
	if _touch_detected:
		key *= 1.5 if Constants.is_portrait(vp) else 1.3

	var gap: float = key * 0.12
	var margin: float = key * 0.4

	# Safe area margins.
	var safe: Vector2 = _get_safe_margins()
	margin = maxf(margin, safe.x)

	# Cluster em cruz: 3 colunas x 2 linhas, com dead zone no centro.
	var cluster_w: float = key * 3.0 + gap * 2.0
	var cluster_h: float = key * 2.0 + gap

	# Trava de largura (retrato): impede que o cluster + margem estoure ou domine a tela
	# estreita. Encolhe a tecla na mesma proporção, preservando o desenho da cruz.
	var max_cluster_w: float = vp.x * DPAD_MAX_WIDTH_FRACTION - margin
	if cluster_w > max_cluster_w and max_cluster_w > 0.0:
		var shrink: float = max_cluster_w / cluster_w
		key *= shrink
		gap *= shrink
		cluster_w = key * 3.0 + gap * 2.0
		cluster_h = key * 2.0 + gap

	# Ancorado ao canto inferior DIREITO (polegar direito = direcional).
	var origin := Vector2(vp.x - margin - cluster_w, vp.y - margin - cluster_h - safe.y)

	# Retângulo em coordenadas de tela ocupado pelo cluster — consultado pela arena
	# para impedir que bolhas de timing nasçam atrás do D-pad.
	_dpad_rect = Rect2(origin, Vector2(cluster_w, cluster_h))

	var cx: float = origin.x + key + gap          # coluna central
	var y_top: float = origin.y                    # linha de cima (↑)
	var y_bot: float = origin.y + key + gap        # linha de baixo (← ↓ →)

	var positions: Array[Vector2] = [
		Vector2(cx, y_top),
		Vector2(origin.x, y_bot),
		Vector2(cx, y_bot),
		Vector2(origin.x + key * 2.0 + gap * 2.0, y_bot),
	]

	for i in _keys.size():
		var btn := _keys[i]
		btn.position = positions[i]
		btn.size = Vector2(key, key)


func _rebuild_combat() -> void:
	var vp := get_viewport().get_visible_rect().size
	var key: float = clampf(minf(vp.x, vp.y) * COMBAT_KEY_FRACTION, COMBAT_KEY_MIN, COMBAT_KEY_MAX)
	if _touch_detected:
		key *= 1.2 if Constants.is_portrait(vp) else 1.0

	var gap: float = key * 0.10
	var margin: float = key * 0.45
	var safe: Vector2 = _get_safe_margins()
	margin = maxf(margin, safe.x)

	var cluster_w: float = key * 3.0 + gap * 2.0
	var cluster_h: float = key * 2.0 + gap
	var max_cluster_w: float = vp.x * COMBAT_MAX_WIDTH_FRACTION - margin
	if cluster_w > max_cluster_w and max_cluster_w > 0.0:
		var shrink: float = max_cluster_w / cluster_w
		key *= shrink
		gap *= shrink
		cluster_w = key * 3.0 + gap * 2.0
		cluster_h = key * 2.0 + gap

	# Combate usa a cruz antiga no canto inferior esquerdo, como comando explícito de timing.
	var origin := Vector2(margin, vp.y - margin - cluster_h - safe.y)
	_dpad_rect = Rect2(origin, Vector2(cluster_w, cluster_h))

	var cx: float = origin.x + key + gap
	var y_top: float = origin.y
	var y_bot: float = origin.y + key + gap
	var positions: Array[Vector2] = [
		Vector2(cx, y_top),
		Vector2(origin.x, y_bot),
		Vector2(cx, y_bot),
		Vector2(origin.x + key * 2.0 + gap * 2.0, y_bot),
	]

	for i in _keys.size():
		var btn := _keys[i]
		btn.position = positions[i]
		btn.size = Vector2(key, key)


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
	_pressed_count += 1
	_update_opacity()

	var btn := _get_button_for_action(action)
	if btn != null:
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), 0.05)

	Input.action_press(action)
	_feed_event(action, true)


func _on_released(action: String) -> void:
	_pressed_count = maxi(_pressed_count - 1, 0)
	_update_opacity()

	var btn := _get_button_for_action(action)
	if btn != null:
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.05)

	Input.action_release(action)
	_feed_event(action, false)


func _get_button_for_action(action: String) -> BaseButton:
	if _keys.is_empty():
		return null
	for i in _ENTRIES.size():
		if _ENTRIES[i][0] == action:
			if i < _keys.size():
				return _keys[i]
			break
	return null


func _update_opacity() -> void:
	if _root == null:
		return
	var target: float = OPACITY_ACTIVE if _pressed_count > 0 else OPACITY_IDLE
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", target, 0.15)


func _feed_event(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
