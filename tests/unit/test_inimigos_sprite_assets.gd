extends GutTest

# Contrato visual dos inimigos comuns (caçador & bruxo) — pipeline premium
# gen_inimigos.py. Lei: docs/PLANO-redesign-cacador-bruxo.md §2 (travas de
# marca: nada de olhos brancos, laranja da juba ou verde do cristal em inimigo).

const SPRITE_PATHS: Array[String] = [
	"res://assets/sprites/enemy_idle.png",
	"res://assets/sprites/enemy_windup.png",
	"res://assets/sprites/bruxo_idle.png",
	"res://assets/sprites/bruxo_windup.png",
]

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

func test_inimigos_sprite_contract_assets_are_48x48() -> void:
	for path: String in SPRITE_PATHS:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), Vector2(48, 48), "%s mantem contrato 48x48" % path)

func test_inimigos_sprite_contract_assets_are_not_blank() -> void:
	for path: String in SPRITE_PATHS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		assert_gt(_count_opaque_pixels(image), 400, "%s tem massa visual suficiente" % path)

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
	for path: String in SPRITE_PATHS:
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
