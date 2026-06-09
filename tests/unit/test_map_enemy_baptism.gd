extends GutTest

# Fase 5 — overlay de batismo: os 4 chefes convertidos carregam a marca da
# conversão forçada no mapa (pele fria + água benta escorrendo), SEM perder a
# aura de chefe. Comuns e o próprio Jesuíta (o batizador) ficam intocados.

func _spawn(boss: bool, boss_type: String, enemy_type: String) -> MapEnemy:
	var enemy: MapEnemy = MapEnemy.new()
	add_child_autofree(enemy)
	enemy.setup("e1", Vector2i.ZERO, boss, boss_type, Vector2i(-1, -1), enemy_type)
	return enemy

func _sprite_of(enemy: MapEnemy) -> Sprite2D:
	for child in enemy.get_children():
		if child is Sprite2D:
			return child
	return null

func _particle_colors(enemy: MapEnemy) -> Array[Color]:
	var colors: Array[Color] = []
	for child in enemy.get_children():
		if child is CPUParticles2D:
			colors.append(child.color)
	return colors

func test_miniboss_carries_baptism_mark_and_keeps_aura() -> void:
	var mula := _spawn(false, "", "mula")
	assert_eq(_sprite_of(mula).modulate, Constants.COLOR_BAPTISM_TINT,
		"convertido tem a pele fria do batismo forçado")
	var colors := _particle_colors(mula)
	assert_has(colors, Constants.COLOR_BAPTISM_DROP, "água benta escorre do convertido")
	assert_has(colors, Constants.COLOR_AURA_MULA, "a aura de chefe da Mula permanece")

func test_all_four_converted_bosses_are_baptized() -> void:
	for t: String in MapEnemy.MINIBOSS_TYPES:
		var enemy := _spawn(false, "", t)
		assert_has(_particle_colors(enemy), Constants.COLOR_BAPTISM_DROP,
			"%s convertido carrega a marca de batismo" % t)

func test_common_enemy_has_no_baptism() -> void:
	var cacador := _spawn(false, "", "cacador")
	assert_eq(_sprite_of(cacador).modulate, Color.WHITE, "comum não é batizado")
	assert_eq(_particle_colors(cacador).size(), 0, "comum não tem partículas")

func test_jesuita_boss_has_no_baptism() -> void:
	# O Jesuíta é o batizador, não o batizado: aura própria, sem pingos.
	var jesuita := _spawn(true, "jesuita", "")
	assert_eq(_sprite_of(jesuita).modulate, Color.WHITE, "o batizador não leva a marca")
	var colors := _particle_colors(jesuita)
	assert_has(colors, Constants.COLOR_AURA_JESUITA, "aura de incenso podre presente")
	assert_does_not_have(colors, Constants.COLOR_BAPTISM_DROP, "sem pingos de batismo")
