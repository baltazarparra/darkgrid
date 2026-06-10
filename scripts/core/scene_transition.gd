extends CanvasLayer
# Autoload registrado como SceneTransition em project.godot.
# Sem class_name: conflita com o nome do autoload em Godot 4.
#
# Mascara TODA troca de cena com um fade preto curto, escondendo o hard-cut do
# change_scene_to_file. Em avanços de fase — entrada numa exploração NOVA (run start
# ou progressão) — exibe o flavor "a mata se reorganiza..."; voltas de combate para
# a mesma fase e telas de menu usam fade limpo, sem texto enganoso.
#
# GameState.change_screen → SignalBus.screen_changed → GameState resolve o caminho
# e delega aqui. O autoload sobrevive ao swap, então o overlay cobre a troca.

# Acima do HUD e de qualquer overlay de jogo: a transição cobre tudo.
const LAYER := 100
const FADE_OUT := 0.22       # cobre a cena atual
const FADE_IN := 0.28        # revela a nova cena
const TEXT_FADE := 0.18      # surge/some do flavor
const TEXT_HOLD := 0.5       # tempo de leitura do flavor
const THEMED_TEXT := "a mata se reorganiza..."
const CAMP_TEXT := "o acampamento respira..."   # entrada no HUB jogável (Fase 9)

# ─── Loader de combate "peleja" (Fase 10) ──────────
# Toda entrada em tela ARENA_* vira combat-intro: o texto surge letra a letra
# sobre o preto enquanto a arena carrega por baixo, segura PELEJA_MIN_HOLD e
# some. É o aviso de que a luta vai começar E a máscara de carregamento — o
# ArenaManager só inicia o turno quando SignalBus.combat_intro_finished chega.
const PELEJA_TEXT := "peleja"
const PELEJA_MIN_HOLD := 2.0           # mínimo do texto inteiro em tela (requisito: >= 2s)
const PELEJA_REVEAL_PER_CHAR := 0.08   # reveal letra a letra (carregando...)
const PELEJA_FADE := 0.25              # surge/some do texto

var _fade: ColorRect
var _label: Label
var _peleja_label: Label
var _tween: Tween
var _last_exploration: int = -1   # última tela de exploração visitada (detecta nova fase)
var _combat_intro_active := false

func _ready() -> void:
	layer = LAYER
	# Roda mesmo com a árvore pausada (ex.: sair para o menu a partir do pause).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", Constants.FONT_MD)
	_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.add_child(_label)

	# Texto do combat-intro: grande, âmbar de cue — a palavra chega como golpe.
	_peleja_label = Label.new()
	_peleja_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_peleja_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_peleja_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_peleja_label.add_theme_font_size_override("font_size", Constants.FONT_TITLE)
	_peleja_label.add_theme_color_override("font_color", Constants.COLOR_AMBER)
	_peleja_label.text = PELEJA_TEXT
	_peleja_label.visible_characters = 0
	_peleja_label.modulate.a = 0.0
	_peleja_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.add_child(_peleja_label)

# ─── Public API ────────────────────────────────────
## Faz fade-out, troca para `path`, faz fade-in. `new_screen` (SignalBus.Screen)
## decide o flavor temático. Chamado por GameState._on_screen_changed.
func transition_to(path: String, new_screen: int) -> void:
	if path.is_empty():
		return
	var flavor := _flavor_for(new_screen)
	if _is_exploration(new_screen):
		_last_exploration = new_screen
	_run(path, flavor, _is_arena(new_screen))

## True enquanto o loader "peleja" cobre a entrada da arena. O ArenaManager
## consulta isto no _ready: se ativo, espera combat_intro_finished para iniciar
## o turno; se não (testes headless, run direto do editor), começa imediato.
func is_combat_intro_active() -> bool:
	return _combat_intro_active

# ─── Lógica de flavor (pura, testável) ─────────────
## Exploração é qualquer uma das 4 telas de fase. Função (não const) de propósito:
## resolvida em runtime, quando o autoload SignalBus já existe (evita a armadilha
## de ordem de carga dos autoloads ao referenciar SignalBus.Screen num const).
func _is_exploration(s: int) -> bool:
	return s == SignalBus.Screen.EXPLORATION \
		or s == SignalBus.Screen.EXPLORATION_PHASE2 \
		or s == SignalBus.Screen.EXPLORATION_PHASE3 \
		or s == SignalBus.Screen.EXPLORATION_PHASE4 \
		or s == SignalBus.Screen.EXPLORATION_PHASE5

## Arena é qualquer uma das 5 telas de combate — todas ganham o loader "peleja".
func _is_arena(s: int) -> bool:
	return s == SignalBus.Screen.ARENA \
		or s == SignalBus.Screen.ARENA_PHASE2 \
		or s == SignalBus.Screen.ARENA_PHASE3 \
		or s == SignalBus.Screen.ARENA_PHASE4 \
		or s == SignalBus.Screen.ARENA_PHASE5

## Texto de flavor da transição (vazio = fade limpo, sem texto). Há flavor ao ENTRAR numa
## exploração de fase nova (run start / avanço de fase) e ao ENTRAR no acampamento (HUB,
## tela calma). A volta do combate para a MESMA fase não dispara texto (mapa não mudou).
func _flavor_for(new_screen: int) -> String:
	if _is_exploration(new_screen) and new_screen != _last_exploration:
		return THEMED_TEXT
	if new_screen == SignalBus.Screen.HUB:
		return CAMP_TEXT
	return ""

## True quando a transição mostra algum flavor (qualquer texto não-vazio).
func _is_themed(new_screen: int) -> bool:
	return not _flavor_for(new_screen).is_empty()

# ─── Execução do fade ──────────────────────────────
func _run(path: String, flavor: String, peleja: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_fade.color.a = 0.0
	_label.modulate.a = 0.0
	_peleja_label.modulate.a = 0.0
	_peleja_label.visible_characters = 0
	# Transição nova zera qualquer intro pendurada (a anterior morreu com o tween).
	_combat_intro_active = peleja
	# Engole cliques durante a transição (evita disparo duplo de botões/ações).
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var themed := not flavor.is_empty()
	if themed:
		_label.text = flavor

	_tween = create_tween()
	_tween.tween_property(_fade, "color:a", 1.0, FADE_OUT)
	_tween.tween_callback(func() -> void: get_tree().change_scene_to_file(path))
	if peleja:
		# Surge, revela letra a letra (carregando), segura >= 2s e some — a arena
		# já trocou por baixo do preto; o fim do tween libera o combate.
		_tween.tween_property(_peleja_label, "modulate:a", 1.0, PELEJA_FADE)
		_tween.tween_property(_peleja_label, "visible_characters",
			PELEJA_TEXT.length(), PELEJA_REVEAL_PER_CHAR * PELEJA_TEXT.length())
		_tween.tween_interval(PELEJA_MIN_HOLD)
		_tween.tween_property(_peleja_label, "modulate:a", 0.0, PELEJA_FADE)
	elif themed:
		_tween.tween_property(_label, "modulate:a", 1.0, TEXT_FADE)
		_tween.tween_interval(TEXT_HOLD)
		_tween.tween_property(_label, "modulate:a", 0.0, TEXT_FADE)
	_tween.tween_property(_fade, "color:a", 0.0, FADE_IN)
	_tween.tween_callback(func() -> void:
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if peleja:
			_combat_intro_active = false
			SignalBus.combat_intro_finished.emit())
