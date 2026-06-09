extends GutTest

# A CHAMA incendeia a PRÓPRIA Caipora: com has_chama, os consumidores trocam o
# SpriteFrames pela variante de juba incendiada via MetaProgression.caipora_frames_path().
# A variante mantém o MESMO contrato de animações (idle/walk/windup/strike/recover),
# então ActorAnimator e cenas não percebem a troca.

func before_each():
	MetaProgression.has_chama = false

func after_each():
	MetaProgression.has_chama = false

# ─── Seleção de path ───────────────────────────────
func test_frames_path_sem_chama():
	assert_eq(MetaProgression.caipora_frames_path(),
		MetaProgression.CAIPORA_FRAMES_PATH,
		"sem CHAMA usa os frames base")

func test_frames_path_com_chama():
	MetaProgression.has_chama = true
	assert_eq(MetaProgression.caipora_frames_path(),
		MetaProgression.CAIPORA_FRAMES_CHAMA_PATH,
		"com CHAMA usa a variante incendiada")

# ─── Contrato de animações ─────────────────────────
func test_variante_chama_mantem_contrato_de_animacoes():
	var base: SpriteFrames = load(MetaProgression.CAIPORA_FRAMES_PATH)
	var chama: SpriteFrames = load(MetaProgression.CAIPORA_FRAMES_CHAMA_PATH)
	assert_not_null(base, "frames base carregam")
	assert_not_null(chama, "frames CHAMA carregam")
	for anim in base.get_animation_names():
		assert_true(chama.has_animation(anim), "variante tem a animação '%s'" % anim)
		assert_eq(chama.get_frame_count(anim), base.get_frame_count(anim),
			"mesma contagem de frames em '%s'" % anim)
		assert_eq(chama.get_animation_speed(anim), base.get_animation_speed(anim),
			"mesma velocidade em '%s'" % anim)
		assert_eq(chama.get_animation_loop(anim), base.get_animation_loop(anim),
			"mesmo loop em '%s'" % anim)

func test_variante_chama_usa_texturas_proprias():
	var base: SpriteFrames = load(MetaProgression.CAIPORA_FRAMES_PATH)
	var chama: SpriteFrames = load(MetaProgression.CAIPORA_FRAMES_CHAMA_PATH)
	var base_tex := base.get_frame_texture(&"idle", 0)
	var chama_tex := chama.get_frame_texture(&"idle", 0)
	assert_not_null(chama_tex, "idle da variante tem textura")
	assert_ne(chama_tex.resource_path, base_tex.resource_path,
		"a variante aponta para os PNGs _chama, não para os base")
