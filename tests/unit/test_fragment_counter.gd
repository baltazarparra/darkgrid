extends GutTest

# FragmentCounter substitui o antigo "+".repeat(n) (que estourava a tela). A propriedade
# essencial: a largura cresce só com o nº de dígitos, nunca proporcional à contagem.

var _fc: FragmentCounter

func before_each():
	_fc = FragmentCounter.new()
	add_child_autofree(_fc)

func test_set_count_updates_label():
	_fc.set_count(23)
	assert_eq(_fc._count, 23)
	assert_eq(_fc._label.text, "23")

func test_set_count_clamps_negative():
	_fc.set_count(-4)
	assert_eq(_fc._count, 0)

func test_width_stays_bounded_with_huge_count():
	_fc.configure_size(18)
	_fc.set_count(9)
	var small: float = _fc.custom_minimum_size.x
	_fc.set_count(999999)
	var big: float = _fc.custom_minimum_size.x
	# largura cresce só com dígitos — diferença minúscula, não explode linearmente.
	assert_lt(big, small + 200.0)
