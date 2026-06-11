extends GutTest

# Contrato de proporção dos bosses na arena — fiel à lore (interim do KI-012).
# A Caipora é uma CRIANÇA da mata; cada chefe escala a partir dela:
#
#   Saci (menino de uma perna) < Caipora ≈ Curupira (criança da mata)
#   < humanos adultos (Jesuíta, caçador-de-machados ≈ caçador/bruxo comuns)
#   < Boitatá (serpente gigante — massa horizontal enrolada)
#   < Mula sem Cabeça (montaria + coluna de fogo, agiganta sobre todos).
#
# Enquanto a arte legada é 48×48, a hierarquia vem do sprite_scale por cena.
# Bosses redesenhados em canvas ≥128 (KI-012) herdam ESTAS alturas visuais
# (corpo desenhado × escala) e voltam à escala premium 1.2 — Curupira via
# gen_bosses.py, Boitatá via gen_boitata.py.

const CAIPORA_PNG := "res://assets/sprites/player_idle.png"
const CACADOR_PNG := "res://assets/sprites/enemy_idle.png"
const CAIPORA_ARENA_SCALE := 1.2
const CAIPORA_ARENA_OFFSET_Y := -30.0
const CACADOR_ARENA_SCALE := 1.2

# Cena da arena → [png idle, sprite_scale esperado, offset.y esperado]
const BOSSES: Dictionary = {
	# Mula segue legada (48×48, scale 3.5): a cena e o sprite reais — a entry
	# 0.9/-77 que entrou junto do redesign do Boitatá não correspondia a nada.
	"res://scenes/arena/mula.tscn": ["res://assets/sprites/mula_idle.png", 3.5, -18.0],
	"res://scenes/arena/boitata.tscn": ["res://assets/sprites/boitata_idle.png", 1.2, -38.0],
	"res://scenes/arena/curupira.tscn": ["res://assets/sprites/curupira_idle.png", 1.2, -47.0],
	"res://scenes/arena/saci.tscn": ["res://assets/sprites/saci_idle.png", 1.8, -16.0],
	"res://scenes/arena/jesuita.tscn": ["res://assets/sprites/jesuita_idle.png", 2.7, -18.0],
	"res://scenes/arena/boss.tscn": ["res://assets/sprites/boss_idle.png", 2.8, -18.0],
}

# Pés na linha de chão: Caipora e caçador assentam ~13.8px abaixo da origem
# do ator (offset −30/−40 × escala 1.2). Todo boss deve assentar na mesma faixa.
const FEET_TOLERANCE := 4.0

func test_boss_scenes_keep_scale_and_offset() -> void:
	# Criatura._ready() reaplica o export sprite_scale por cima do scale do nó:
	# valida o valor EFETIVO depois do _ready, não só o salvo na cena.
	for scene_path: String in BOSSES:
		var expected_scale: float = BOSSES[scene_path][1]
		var expected_offset_y: float = BOSSES[scene_path][2]
		var boss := (load(scene_path) as PackedScene).instantiate()
		add_child_autofree(boss)
		var spr := boss.get_node("AnimatedSprite2D") as AnimatedSprite2D
		assert_eq(spr.scale, Vector2(expected_scale, expected_scale),
			"%s mantém sprite_scale %s depois do _ready" % [scene_path, expected_scale])
		assert_eq(spr.offset.y, expected_offset_y,
			"%s mantém offset de pés %s" % [scene_path, expected_offset_y])

func test_hierarquia_de_alturas_fiel_a_lore() -> void:
	var caipora_h := _visual_height(CAIPORA_PNG, CAIPORA_ARENA_SCALE)
	var cacador_h := _visual_height(CACADOR_PNG, CACADOR_ARENA_SCALE)
	var saci_h := _boss_visual_height("res://scenes/arena/saci.tscn")
	var curupira_h := _boss_visual_height("res://scenes/arena/curupira.tscn")
	var jesuita_h := _boss_visual_height("res://scenes/arena/jesuita.tscn")
	var machados_h := _boss_visual_height("res://scenes/arena/boss.tscn")
	var boitata_h := _boss_visual_height("res://scenes/arena/boitata.tscn")
	var mula_h := _boss_visual_height("res://scenes/arena/mula.tscn")

	# Crianças leem como criança.
	assert_lt(saci_h, caipora_h, "Saci (menino de uma perna) lê MENOR que a Caipora")
	assert_between(curupira_h, caipora_h * 0.9, caipora_h * 1.1,
		"Curupira (criança da mata) lê do tamanho da Caipora")

	# Humanos adultos se agigantam sobre ela — mesmo porte do caçador comum.
	assert_gt(jesuita_h, caipora_h * 1.25, "Jesuíta (adulto) se agiganta sobre a Caipora")
	assert_between(jesuita_h, cacador_h * 0.85, cacador_h * 1.15,
		"Jesuíta lê no porte do caçador adulto")
	assert_between(machados_h, cacador_h * 0.85, cacador_h * 1.15,
		"Caçador-de-machados lê no porte do caçador adulto")

	# Bestas: a serpente gigante e a montaria dominam a cena.
	assert_gt(boitata_h, caipora_h, "Boitatá enrolado ainda lê mais alto que a Caipora")
	var boitata_w := _boss_visual_width("res://scenes/arena/boitata.tscn")
	var cacador_w := _visual_width(CACADOR_PNG, CACADOR_ARENA_SCALE)
	assert_gt(boitata_w, cacador_w * 1.2,
		"Boitatá (serpente gigante) tem massa horizontal maior que um humano")
	for other_h: float in [caipora_h, cacador_h, saci_h, curupira_h, jesuita_h, machados_h, boitata_h]:
		assert_gt(mula_h, other_h, "Mula sem Cabeça (montaria + fogo) agiganta sobre todos")

func test_pes_de_todos_os_bosses_na_linha_do_chao() -> void:
	# Mesma linha de chão da Caipora: fundo do desenho × escala ± tolerância.
	var ref := _feet_below_origin(CAIPORA_PNG, CAIPORA_ARENA_SCALE, CAIPORA_ARENA_OFFSET_Y)
	for scene_path: String in BOSSES:
		var feet := _feet_below_origin(BOSSES[scene_path][0],
			BOSSES[scene_path][1], BOSSES[scene_path][2])
		assert_between(feet, ref - FEET_TOLERANCE, ref + FEET_TOLERANCE,
			"%s assenta os pés na linha de chão da Caipora (%.1fpx ± %.0f, leu %.1f)"
			% [scene_path, ref, FEET_TOLERANCE, feet])

# ─── Helpers ─────────────────────────────────────

func _boss_visual_height(scene_path: String) -> float:
	return _visual_height(BOSSES[scene_path][0], BOSSES[scene_path][1])

func _boss_visual_width(scene_path: String) -> float:
	return _visual_width(BOSSES[scene_path][0], BOSSES[scene_path][1])

func _visual_height(png_path: String, sprite_scale: float) -> float:
	return float(_opaque_bounds(png_path).size.y) * sprite_scale

func _visual_width(png_path: String, sprite_scale: float) -> float:
	return float(_opaque_bounds(png_path).size.x) * sprite_scale

## Pixels abaixo da origem do ator onde o desenho termina (linha dos pés).
func _feet_below_origin(png_path: String, sprite_scale: float, offset_y: float) -> float:
	var image := Image.load_from_file(ProjectSettings.globalize_path(png_path))
	var bottom_local := float(_opaque_bounds(png_path).end.y) - image.get_height() * 0.5
	return (offset_y + bottom_local) * sprite_scale

## Retângulo (em pixels do canvas) que o desenho opaco realmente ocupa.
func _opaque_bounds(png_path: String) -> Rect2i:
	var image := Image.load_from_file(ProjectSettings.globalize_path(png_path))
	assert_false(image.is_empty(), "%s carrega como Image" % png_path)
	var top := image.get_height()
	var bottom := -1
	var left := image.get_width()
	var right := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				left = mini(left, x)
				right = maxi(right, x)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)
