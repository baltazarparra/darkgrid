extends GutTest

# Popup de ganho de fragmentos (HUD). Regressão do bug em que "+%.4g fragmento%s" aparecia
# LITERAL na tela (o format do Godot não suporta "%g"), notado ao recuperar a bolsa souls-like.
# Cobre a função pura de formatação — o texto nunca pode conter especificadores de format crus.

func test_inteiro_sem_casas_decimais():
	assert_eq(Hud.format_fragment_popup(3.0), "+3 fragmentos")
	assert_eq(Hud.format_fragment_popup(12.0), "+12 fragmentos")

func test_singular_sem_s():
	assert_eq(Hud.format_fragment_popup(1.0), "+1 fragmento")

func test_fracionario_uma_casa():
	# Drop de 1.5/kill na Fase 2: somas são múltiplos de 0.5.
	assert_eq(Hud.format_fragment_popup(1.5), "+1.5 fragmentos")
	assert_eq(Hud.format_fragment_popup(12.5), "+12.5 fragmentos")

func test_nunca_vaza_especificador_de_format():
	# O sintoma do bug: "%" cru sobrando no texto renderizado.
	for amount: float in [0.0, 1.0, 1.5, 2.0, 7.0, 12.5, 30.0]:
		var txt := Hud.format_fragment_popup(amount)
		assert_false(txt.contains("%"), "texto não pode conter '%%' cru: %s" % txt)
		assert_false(txt.contains("g"), "texto não pode conter o 'g' do %%g: %s" % txt)
