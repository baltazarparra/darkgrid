class_name PixelScale
extends RefCounted

## Quantização do zoom da câmera para texel inteiro em device pixels.
##
## Com FILTER_NEAREST global, o que deixa a pixel art "mole" é a escala final
## fracionária (zoom × escala do stretch): texels da arte ora ocupam 2, ora 3
## device-pixels. Snapando zoom*s para um inteiro, toda a arte 32/48/64px fica
## chunky e uniforme — sem SubViewport, sem tocar input/HUD.
##
## Funções de snap são puras (recebem `s` por parâmetro) para teste unitário.


## Device-pixels por unidade de canvas (a escala efetiva do stretch canvas_items).
## No export web, window_get_size() é o canvas em device px (DPR incluso).
static func device_scale(viewport: Viewport) -> float:
	if viewport == null:
		return 1.0
	var canvas: Vector2 = viewport.get_visible_rect().size
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	if canvas.x <= 0.0 or window.x <= 0.0:
		return 1.0
	return window.x / canvas.x


## Snap para fit "contain" (arena): arredonda o texel para o inteiro mais
## próximo (a folga do STAGE_FILL absorve subir ~8%); se estourar hard_max_z
## (cortaria o stage), cai para floor. Se nem texel 1 couber (viewport
## degenerada), mantém o zoom fracionário original.
static func snap_contain(raw_z: float, s: float, hard_max_z: float) -> float:
	if raw_z <= 0.0 or s <= 0.0:
		return raw_z
	var texel: float = maxf(roundf(raw_z * s), 1.0)
	if texel / s > hard_max_z:
		texel = maxf(floorf(raw_z * s), 1.0)
	if texel / s > hard_max_z:
		return raw_z
	return texel / s


## Snap para fit "cover" (exploração): arredonda o texel para CIMA — cover
## exige z >= raw_z, senão a área visível excede o mapa e vaza além dos
## limit_* da câmera. Texel bruto < 0.5 inflaria o zoom 2x+ (viewport
## degenerada): mantém o original.
static func snap_cover(raw_z: float, s: float) -> float:
	if raw_z <= 0.0 or s <= 0.0:
		return raw_z
	var t: float = raw_z * s
	if t < 0.5:
		return raw_z
	return ceilf(t) / s
