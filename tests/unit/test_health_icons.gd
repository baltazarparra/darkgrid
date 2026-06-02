extends GutTest

# HealthIcons agora tem tamanho parametrizável (raio/espaçamento) para o HP responsivo.
# Determinístico: valida custom_minimum_size sem depender de render.

var _icons: HealthIcons

func before_each():
	_icons = HealthIcons.new()
	add_child_autofree(_icons)

func test_set_metrics_updates_min_size():
	_icons.setup(5, HealthIcons.Shape.PENTAGRAM, Color.RED, Color.BLACK)
	_icons.set_metrics(24.0, 56.0)
	# largura = total * spacing + radius ; altura = radius * 2.8
	assert_almost_eq(_icons.custom_minimum_size.x, 5 * 56.0 + 24.0, 0.01)
	assert_almost_eq(_icons.custom_minimum_size.y, 24.0 * 2.8, 0.01)

func test_set_metrics_preserves_current():
	_icons.setup(5, HealthIcons.Shape.PENTAGRAM, Color.RED, Color.BLACK)
	_icons.set_current(2)
	_icons.set_metrics(20.0, 48.0)
	# set_metrics não pode resetar o HP atual
	assert_eq(_icons._current, 2)
	assert_eq(_icons._total, 5)
