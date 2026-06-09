extends GutTest

# Props de igreja (Fase 5): ambientação não-bloqueante. Valida o wiring do enum
# novo + z-index (atrás das entidades) e que NÃO vazam para a paleta da Fase 1.

func test_church_props_are_decoration_layer() -> void:
	for t: int in MapObject.CHURCH_PROPS:
		var obj := MapObject.new()
		add_child_autofree(obj)
		obj.setup(t, Vector2i(2, 2))
		assert_eq(obj.z_index, -1, "prop de igreja %d renderiza atrás das entidades" % t)

func test_church_props_not_in_phase1_palette() -> void:
	# DECO_TYPES dobra como paleta da Fase 1 — os props de igreja NÃO podem vazar.
	for t: int in MapObject.CHURCH_PROPS:
		assert_false(t in MapObject.DECO_TYPES, "prop de igreja %d fora da paleta da Fase 1" % t)

func test_church_props_cover_the_five_liturgical_objects() -> void:
	assert_eq(MapObject.CHURCH_PROPS.size(), 5, "5 props: cruz, espelho, pia, círio, banco")
	for t: int in [MapObject.Type.CROSS, MapObject.Type.MIRROR, MapObject.Type.FONT,
			MapObject.Type.CANDLE, MapObject.Type.PEW]:
		assert_true(t in MapObject.CHURCH_PROPS, "prop %d é litúrgico" % t)
