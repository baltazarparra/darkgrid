extends GutTest

# Contrato visual do Curupira (boss P3) — pipeline premium gen_bosses.py.
# Lei: docs/PLANO-redesign-curupira.md §2 / docs/CONCEITO-curupira.md (travas
# de marca: nada de olhos brancos redondos, laranja da juba ou verde do
# cristal; o verde dele é verde-FOLHA, o vermelho da crista é fogo morto).

# Arena 128x128 (KI-012: canvas >=128, escala de nó 1.2 — texels uniformes);
# mapa 48x48 re-renderizado dos MESMOS vetores (bosses no mapa seguem 48).
const SPRITE_SIZES: Dictionary = {
	"res://assets/sprites/curupira_idle.png": Vector2(128, 128),
	"res://assets/sprites/curupira_windup.png": Vector2(128, 128),
	"res://assets/sprites/curupira_map.png": Vector2(48, 48),
}
# Fração mínima do canvas com pixels opacos (medido: arena ~0.16, mapa ~0.38).
const MIN_OPAQUE_FRACTION := 0.10

const CURUPIRA_IDLE := "res://assets/sprites/curupira_idle.png"
const CURUPIRA_WINDUP := "res://assets/sprites/curupira_windup.png"

# Paleta do Curupira (gen_bosses.py)
const COLOR_SKIN := Color8(42, 107, 52)        # verde da mata (corpo)
const COLOR_SKIN_DK := Color8(20, 56, 28)      # verde profundo (família da aura)
const COLOR_CRISTA := Color8(168, 40, 30)      # crista vermelho-sangue (fogo morto)
const COLOR_EYE := Color8(47, 168, 56)         # fendas verde-FOLHA
const COLOR_EYE_HOT := Color8(102, 212, 78)    # ponto vivo da fenda
const COLOR_BONE_DK := Color8(156, 140, 112)   # garras de osso sujo
const COLOR_BLOOD := Color8(139, 0, 0)         # pegadas/talhos/sangue seco

# Assinaturas exclusivas da protagonista (travas de marca)
const COLOR_CAIPORA_EYES := Color8(255, 255, 255)
const COLOR_CAIPORA_MANE := Color8(255, 69, 0)
const COLOR_CAIPORA_MANE_DK := Color8(139, 42, 0)
const COLOR_CAIPORA_CRYSTAL := Color8(0, 250, 154)

func test_curupira_sprite_contract_sizes() -> void:
	for path: String in SPRITE_SIZES:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), SPRITE_SIZES[path],
			"%s mantem contrato %s" % [path, SPRITE_SIZES[path]])

func test_curupira_sprite_contract_assets_are_not_blank() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var expected: Vector2 = SPRITE_SIZES[path]
		var min_opaque := int(expected.x * expected.y * MIN_OPAQUE_FRACTION)
		assert_gt(_count_opaque_pixels(image), min_opaque,
			"%s tem massa visual suficiente" % path)

func test_curupira_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(CURUPIRA_IDLE))
	assert_false(image.is_empty(), "curupira idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_SKIN), "idle preserva o verde da mata no corpo")
	assert_true(_has_color(image, COLOR_SKIN_DK), "idle preserva o verde profundo (família da aura)")
	assert_true(_has_color(image, COLOR_CRISTA), "idle preserva a crista vermelho-sangue")
	assert_true(_has_color(image, COLOR_EYE), "idle preserva as fendas verde-folha")
	assert_true(_has_color(image, COLOR_BONE_DK), "idle preserva as garras de osso (pés ao contrário)")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva o sangue (pegadas invertidas/talhos)")

func test_curupira_windup_breaks_the_indifference() -> void:
	# O telegraph é gameplay: o windup precisa existir E mudar a silhueta.
	var idle := Image.load_from_file(ProjectSettings.globalize_path(CURUPIRA_IDLE))
	var windup := Image.load_from_file(ProjectSettings.globalize_path(CURUPIRA_WINDUP))
	assert_false(windup.is_empty(), "curupira windup carrega como Image")
	if idle.is_empty() or windup.is_empty():
		return
	assert_ne(idle.get_data(), windup.get_data(),
		"windup telegrafa: silhueta difere do idle")
	assert_true(_has_color(windup, COLOR_EYE_HOT),
		"windup escancara as fendas (ponto vivo verde-folha)")
	# Crista eriçada: a mancha ocupa mais colunas que o idle (picos abertos).
	assert_gt(_opaque_width(windup), _opaque_width(idle) - 1,
		"windup eriça a crista (silhueta não encolhe)")

func test_curupira_le_como_crianca_da_mata() -> void:
	# Parente da Caipora: MESMO porte de criança (0.9–1.1x o desenho dela),
	# ambos a escala de nó 1.2 — a hierarquia vem do corpo desenhado.
	var caipora := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/player_idle.png"))
	var curupira := Image.load_from_file(ProjectSettings.globalize_path(CURUPIRA_IDLE))
	assert_false(caipora.is_empty(), "player_idle carrega como Image")
	if caipora.is_empty() or curupira.is_empty():
		return
	var caipora_h := _opaque_height(caipora)
	assert_between(_opaque_height(curupira), int(caipora_h * 0.9), int(caipora_h * 1.1),
		"Curupira desenhado lê do tamanho da Caipora (corpo dela %dpx)" % caipora_h)

func test_curupira_runtime_scale_matches_caipora() -> void:
	# Criatura._ready() reaplica o export sprite_scale por cima do scale do nó:
	# se o export não casar com 1.2, o default vence e quebra os texels uniformes.
	var boss := (load("res://scenes/arena/curupira.tscn") as PackedScene).instantiate()
	add_child_autofree(boss)
	var spr := boss.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert_eq(spr.scale, Vector2(1.2, 1.2),
		"curupira.tscn mantém escala 1.2 depois do _ready")
	assert_true(spr.sprite_frames.has_animation(&"windup"),
		"SpriteFrames do Curupira tem a anim windup (ActorAnimator toca sozinho)")

func test_curupira_never_steals_caipora_brand() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_false(_has_color(image, COLOR_CAIPORA_EYES),
			"%s sem olhos brancos puros (assinatura da Caipora)" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_MANE),
			"%s sem o laranja vivo da juba" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_MANE_DK),
			"%s sem o laranja escuro da juba" % path)
		assert_false(_has_color(image, COLOR_CAIPORA_CRYSTAL),
			"%s sem o verde do cristal/Fúria (o dele é verde-folha)" % path)

func _opaque_height(image: Image) -> int:
	var top := image.get_height()
	var bottom := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return maxi(bottom - top + 1, 0)

func _opaque_width(image: Image) -> int:
	var left := image.get_width()
	var right := -1
	for x: int in range(image.get_width()):
		for y: int in range(image.get_height()):
			if image.get_pixel(x, y).a > 0.1:
				left = mini(left, x)
				right = maxi(right, x)
				break
	return maxi(right - left + 1, 0)

func _count_opaque_pixels(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				count += 1
	return count

func _has_color(image: Image, expected: Color) -> bool:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).is_equal_approx(expected):
				return true
	return false
