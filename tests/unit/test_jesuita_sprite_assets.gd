extends GutTest

# Contrato visual do Jesuíta (boss FINAL, P5) — pipeline premium gen_bosses.py.
# Lei: docs/CONCEITO-jesuita.md (travas de marca: nada de olhos brancos
# redondos, laranja da juba ou verde do cristal; a cruz é DELE — lei dos
# invasores — e as fendas são douradas de zelote).

# Arena 128x128 (KI-012: canvas >=128, escala de nó 1.2 — texels uniformes);
# mapa 48x48 re-renderizado dos MESMOS vetores (bosses no mapa seguem 48).
const SPRITE_SIZES: Dictionary = {
	"res://assets/sprites/jesuita_idle.png": Vector2(128, 128),
	"res://assets/sprites/jesuita_windup.png": Vector2(128, 128),
	"res://assets/sprites/jesuita_map.png": Vector2(48, 48),
}
# Fração mínima do canvas com pixels opacos (medido: arena ~0.23, mapa ~0.42).
const MIN_OPAQUE_FRACTION := 0.10

const JESUITA_IDLE := "res://assets/sprites/jesuita_idle.png"
const JESUITA_WINDUP := "res://assets/sprites/jesuita_windup.png"

# Paleta do Jesuíta (gen_bosses.py)
const COLOR_CASSOCK := Color8(38, 34, 48)       # batina-breu (prega iluminada)
const COLOR_CASSOCK_DK := Color8(16, 14, 20)    # batina-breu (sombra)
const COLOR_GOLD := Color8(212, 180, 98)        # ouro litúrgico (cruz/guardas)
const COLOR_EYE_GOLD := Color8(255, 196, 90)    # fendas douradas de zelote
const COLOR_STEEL := Color8(138, 138, 146)      # baionetas consagradas
const COLOR_HOLY := Color8(200, 222, 236)       # água benta nas lâminas
const COLOR_BLOOD := Color8(139, 0, 0)          # barra/lâminas ensanguentadas

# Assinaturas exclusivas da protagonista (travas de marca)
const COLOR_CAIPORA_EYES := Color8(255, 255, 255)
const COLOR_CAIPORA_MANE := Color8(255, 69, 0)
const COLOR_CAIPORA_MANE_DK := Color8(139, 42, 0)
const COLOR_CAIPORA_CRYSTAL := Color8(0, 250, 154)

func test_jesuita_sprite_contract_sizes() -> void:
	for path: String in SPRITE_SIZES:
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s carrega" % path)
		if texture == null:
			continue
		assert_eq(texture.get_size(), SPRITE_SIZES[path],
			"%s mantem contrato %s" % [path, SPRITE_SIZES[path]])

func test_jesuita_sprite_contract_assets_are_not_blank() -> void:
	for path: String in SPRITE_SIZES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_false(image.is_empty(), "%s carrega como Image" % path)
		if image.is_empty():
			continue
		var expected: Vector2 = SPRITE_SIZES[path]
		var min_opaque := int(expected.x * expected.y * MIN_OPAQUE_FRACTION)
		assert_gt(_count_opaque_pixels(image), min_opaque,
			"%s tem massa visual suficiente" % path)

func test_jesuita_idle_keeps_signature_colors() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(JESUITA_IDLE))
	assert_false(image.is_empty(), "jesuita idle carrega como Image")
	if image.is_empty():
		return
	assert_true(_has_color(image, COLOR_CASSOCK), "idle preserva a batina-breu (torre)")
	assert_true(_has_color(image, COLOR_CASSOCK_DK), "idle preserva a sombra da batina")
	assert_true(_has_color(image, COLOR_GOLD), "idle preserva o ouro litúrgico (cruz + guardas)")
	assert_true(_has_color(image, COLOR_EYE_GOLD), "idle preserva as fendas douradas de zelote")
	assert_true(_has_color(image, COLOR_STEEL), "idle preserva o aço das baionetas gêmeas")
	assert_true(_has_color(image, COLOR_HOLY), "idle preserva a água benta nas lâminas")
	assert_true(_has_color(image, COLOR_BLOOD), "idle preserva o sangue (barra/lâminas)")

func test_jesuita_windup_opens_the_steel_cross() -> void:
	# O telegraph é gameplay: o windup precisa existir E mudar a silhueta —
	# uma lâmina NIVELADA na Caipora, a outra erguida (o X de aço abre).
	var idle := Image.load_from_file(ProjectSettings.globalize_path(JESUITA_IDLE))
	var windup := Image.load_from_file(ProjectSettings.globalize_path(JESUITA_WINDUP))
	assert_false(windup.is_empty(), "jesuita windup carrega como Image")
	if idle.is_empty() or windup.is_empty():
		return
	assert_ne(idle.get_data(), windup.get_data(),
		"windup telegrafa: silhueta difere do idle")
	assert_gt(_opaque_width(windup), _opaque_width(idle),
		"windup abre o X de lâminas (silhueta mais larga que o idle)")

func test_jesuita_se_agiganta_sobre_a_caipora() -> void:
	# Invasor humano adulto: >1.25x a Caipora e no porte do caçador comum
	# (0.85–1.15x), ambos a escala de nó 1.2 — hierarquia vem do desenho.
	var caipora := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/player_idle.png"))
	var cacador := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/enemy_idle.png"))
	var jesuita := Image.load_from_file(ProjectSettings.globalize_path(JESUITA_IDLE))
	assert_false(caipora.is_empty(), "player_idle carrega como Image")
	assert_false(cacador.is_empty(), "enemy_idle carrega como Image")
	if caipora.is_empty() or cacador.is_empty() or jesuita.is_empty():
		return
	var jesuita_h := _opaque_height(jesuita)
	assert_gt(jesuita_h, int(_opaque_height(caipora) * 1.25),
		"Jesuíta desenhado se agiganta sobre a Caipora")
	var cacador_h := _opaque_height(cacador)
	assert_between(jesuita_h, int(cacador_h * 0.85), int(cacador_h * 1.15),
		"Jesuíta lê no porte do caçador adulto (caçador %dpx)" % cacador_h)

func test_jesuita_runtime_scale_matches_world() -> void:
	# Criatura._ready() reaplica o export sprite_scale por cima do scale do nó:
	# se o export não casar com 1.2, o default vence e quebra os texels uniformes.
	var boss := (load("res://scenes/arena/jesuita.tscn") as PackedScene).instantiate()
	add_child_autofree(boss)
	var spr := boss.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert_eq(spr.scale, Vector2(1.2, 1.2),
		"jesuita.tscn mantém escala 1.2 depois do _ready")
	assert_true(spr.sprite_frames.has_animation(&"windup"),
		"SpriteFrames do Jesuíta tem a anim windup (ActorAnimator toca sozinho)")

func test_jesuita_never_steals_caipora_brand() -> void:
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
