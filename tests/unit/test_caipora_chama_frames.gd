extends GutTest

# A CHAMA incendeia a PRÓPRIA Caipora: CaiporaSkin é o ponto único de seleção
# (frames_path) E aplicação (apply) dos SpriteFrames — consumidores: exploração,
# arena (incluindo conquista NO MEIO do combate, via SignalBus.chama_gained) e
# TitleWalker. A variante mantém o MESMO contrato de animações
# (idle/walk/windup/strike/recover), então ActorAnimator e cenas não percebem.

func before_each():
	MetaProgression.has_chama = false

func after_each():
	MetaProgression.has_chama = false

# ─── Seleção de path ───────────────────────────────
func test_frames_path_sem_chama():
	assert_eq(CaiporaSkin.frames_path(), CaiporaSkin.FRAMES_PATH,
		"sem CHAMA usa os frames base")

func test_frames_path_com_chama():
	MetaProgression.has_chama = true
	assert_eq(CaiporaSkin.frames_path(), CaiporaSkin.FRAMES_CHAMA_PATH,
		"com CHAMA usa a variante incendiada")

# ─── Aplicação ─────────────────────────────────────
func test_apply_troca_para_variante_chama():
	MetaProgression.has_chama = true
	var sprite: AnimatedSprite2D = autofree(AnimatedSprite2D.new())
	CaiporaSkin.apply(sprite)
	assert_not_null(sprite.sprite_frames, "apply atribui frames")
	assert_eq(sprite.sprite_frames.resource_path, CaiporaSkin.FRAMES_CHAMA_PATH,
		"com CHAMA a sprite recebe a variante incendiada")

func test_apply_sem_chama_usa_base():
	var sprite: AnimatedSprite2D = autofree(AnimatedSprite2D.new())
	CaiporaSkin.apply(sprite)
	assert_eq(sprite.sprite_frames.resource_path, CaiporaSkin.FRAMES_PATH,
		"sem CHAMA a sprite recebe os frames base")

func test_apply_preserva_animacao_corrente():
	# Conquista no meio do combate: a pose corrente não pode resetar pro idle.
	var sprite: AnimatedSprite2D = autofree(AnimatedSprite2D.new())
	sprite.sprite_frames = load(CaiporaSkin.FRAMES_PATH)
	sprite.play(&"walk")
	MetaProgression.has_chama = true
	CaiporaSkin.apply(sprite)
	assert_eq(sprite.sprite_frames.resource_path, CaiporaSkin.FRAMES_CHAMA_PATH,
		"frames trocam na conquista")
	assert_eq(String(sprite.animation), "walk", "animação corrente preservada")

func test_apply_null_eh_noop():
	CaiporaSkin.apply(null)
	pass_test("apply(null) não explode")

# ─── Contrato de animações ─────────────────────────
func test_variante_chama_mantem_contrato_de_animacoes():
	var base: SpriteFrames = load(CaiporaSkin.FRAMES_PATH)
	var chama: SpriteFrames = load(CaiporaSkin.FRAMES_CHAMA_PATH)
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
	var base: SpriteFrames = load(CaiporaSkin.FRAMES_PATH)
	var chama: SpriteFrames = load(CaiporaSkin.FRAMES_CHAMA_PATH)
	var base_tex := base.get_frame_texture(&"idle", 0)
	var chama_tex := chama.get_frame_texture(&"idle", 0)
	assert_not_null(base_tex, "idle base tem textura")
	assert_not_null(chama_tex, "idle da variante tem textura")
	if base_tex == null or chama_tex == null:
		return
	assert_ne(chama_tex.resource_path, base_tex.resource_path,
		"a variante aponta para os PNGs _chama, não para os base")
