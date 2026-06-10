extends GutTest

# Contrato visual dos inimigos comuns (caçador & bruxo) — pipeline premium
# gen_inimigos.py. Lei: docs/PLANO-redesign-cacador-bruxo.md §2 (travas de
# marca: nada de olhos brancos, laranja da juba ou verde do cristal em inimigo).

# Arena 112x112 (invasores adultos > Caipora 96/corpo ~75px); mapa 56x56
# (re-render dos mesmos vetores — a Caipora anda o mapa a ~51px visuais).
const SPRITE_SIZES: Dictionary = {
	"res://assets/sprites/enemy_idle.png": Vector2(112, 112),
	"res://assets/sprites/enemy_windup.png": Vector2(112, 112),
	"res://assets/sprites/bruxo_idle.png": Vector2(112, 112),
	"res://assets/sprites/bruxo_windup.png": Vector2(112, 112),
	"res://assets/sprites/enemy_map.png": Vector2(56, 56),
	"res://assets/sprites/bruxo_map.png": Vector2(56, 56),
}
# Fração mínima do canvas com pixels opacos (medido: idle ~0.28, mapa ~0.28).
const MIN_OPAQUE_FRACTION := 0.15

const CACADOR_IDLE := "res://assets/sprites/enemy_idle.png"
const CACADOR_WINDUP := "res://assets/sprites/enemy_windup.png"
const BRUXO_IDLE := "res://assets/sprites/bruxo_idle.png"
const BRUXO_WINDUP := "res://assets/sprites/bruxo_windup.png"

# Paleta dos invasores (gen_inimigos.py)
const COLOR_LEATHER := Color8(61, 38, 20)      # couro/chapéu do caçador
const COLOR_PONCHO := Color8(74, 42, 30)       # pano de terra
const COLOR_STEEL := Color8(138, 138, 146)     # fio do cano da espingarda
const COLOR_EYE_RED := Color8(200, 30, 20)     # brilho dos olhos na sombra
const COLOR_ROBE := Color8(58, 31, 82)         # manto breu-roxo do bruxo
const COLOR_BONE := Color8(216, 200, 168)      # osso (cajado/troféus)
const COLOR_EMBER := Color8(200, 60, 20)       # brasa mortiça (olhos do bruxo)
const COLOR_EMBER_HOT := Color8(232, 116, 44)  # fetiche aceso (windup)
const COLOR_BLOOD := Color8(139, 0, 0)         # sangue

# Assinaturas exclusivas da protagonista (travas de marca)
const COLOR_CAIPORA_EYES := Color8(255, 255, 255)
const COLOR_CAIPORA_MANE := Color8(255, 69, 0)
const COLOR_CAIPORA_MANE_DK := Color8(139, 42, 0)
const COLOR_CAIPORA_CRYSTAL := Color8(0, 250, 154)

func test_inimigos_sprite_contract_sizes() -> void:
	for path: String in SPRITE_SIZES:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), SPRITE_SIZES[path],
			"%s mantem contrato %s" % [path, SPRITE_SIZES[path]])

func test_inimigos_sprite_contract_assets_are_not_blank() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var expected: Vector2 = SPRITE_SIZES[path]
		var min_opaque := int(expected.x * expected.y * MIN_OPAQUE_FRACTION)
		assert_gt(_count_opaque_pixels(image), min_opaque,
			"%s tem massa visual suficiente" % path)

func test_cacador_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(CACADOR_IDLE))
	assert_false(image.is_empty(), "cacador idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_LEATHER), "idle preserva couro do chapéu")
	assert_true(_has_color(image, COLOR_PONCHO), "idle preserva poncho de terra")
	assert_true(_has_color(image, COLOR_STEEL), "idle preserva fio de aço da espingarda")
	assert_true(_has_color(image, COLOR_EYE_RED), "idle preserva brilho vermelho dos olhos na sombra")
	assert_true(_has_color(image, COLOR_BONE), "idle preserva colar de troféus de osso")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva sangue seco na barra")

func test_bruxo_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(BRUXO_IDLE))
	assert_false(image.is_empty(), "bruxo idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_ROBE), "idle preserva manto breu-roxo")
	assert_true(_has_color(image, COLOR_BONE), "idle preserva cajado/crânio de osso")
	assert_true(_has_color(image, COLOR_EMBER), "idle preserva olhos de brasa mortiça")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva talhos rituais de sangue")

func test_bruxo_windup_lights_the_fetish() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(BRUXO_WINDUP))
	assert_false(image.is_empty(), "bruxo windup carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_EMBER_HOT), "windup acende o fetiche (telegraph)")

func test_invasores_arena_sao_maiores_que_caipora() -> void:
	# Lei de escala: invasores adultos se agigantam sobre a Caipora-criança.
	# Mesma escala de nó (1.2) na arena — a hierarquia vem do corpo desenhado.
	var caipora := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/player_idle.png"))
	assert_false(caipora.is_empty(), "player_idle carrega como Image")
	if caipora.is_empty():
		return
	var caipora_h := _opaque_height(caipora)
	for path: String in ["res://assets/sprites/enemy_idle.png", "res://assets/sprites/bruxo_idle.png"]:
		var invasor := Image.load_from_file(ProjectSettings.globalize_path(path))
		if invasor.is_empty():
			fail_test("%s carrega como Image" % path)
			continue
		assert_gt(_opaque_height(invasor), int(caipora_h * 1.2),
			"%s lê pelo menos 1.2x mais alto que a Caipora (corpo %dpx)" % [path, caipora_h])

func test_windup_silhouettes_differ_from_idle() -> void:
	for pair: Array in [[CACADOR_IDLE, CACADOR_WINDUP], [BRUXO_IDLE, BRUXO_WINDUP]]:
		var idle := Image.load_from_file(ProjectSettings.globalize_path(pair[0]))
		var windup := Image.load_from_file(ProjectSettings.globalize_path(pair[1]))
		if idle.is_empty() or windup.is_empty():
			fail_test("%s/%s carregam como Image" % [pair[0], pair[1]])
			continue
		assert_ne(idle.get_data(), windup.get_data(),
			"%s telegrafa: silhueta do windup difere do idle" % pair[1])

func test_inimigos_never_steal_caipora_brand() -> void:
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
			"%s sem o verde do cristal/Fúria" % path)

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
