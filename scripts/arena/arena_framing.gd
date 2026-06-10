class_name ArenaFraming
extends RefCounted

## Enquadramento da arena por orientação (estático e puro — testável, padrão
## PixelScale). Em paisagem vale o palco clássico: atores em 160/480 e fit
## "contain" do retângulo 560x340. Em retrato a tela é estreita: os atores se
## aproximam (~220px) e o fit usa um retângulo de ação de 360px de largura —
## o combate enche a tela do celular em vez de boiar num palco largo.
##
## 360 é deliberado: nos viewports de phone (~360-393 CSS px) o snap de texel
## inteiro (PixelScale.snap_contain) resolve para zoom 1.0 em vez de cair para
## ~0.67 como o palco de 560 força hoje.

# Palco lógico (fundo, chão e limites de bolha) — não muda com a orientação.
const STAGE_CENTER: Vector2 = Vector2(320.0, 225.0)
const STAGE_SIZE: Vector2 = Vector2(560.0, 340.0)
const GROUND_Y: float = 240.0

const LANDSCAPE_ACTION: Vector2 = Vector2(560.0, 340.0)
const PORTRAIT_ACTION: Vector2 = Vector2(360.0, 340.0)
const LANDSCAPE_CAIPORA_X: float = 160.0
const LANDSCAPE_ENEMY_X: float = 480.0
const PORTRAIT_CAIPORA_X: float = 210.0
const PORTRAIT_ENEMY_X: float = 430.0

# Encolhimento da área de spawn de bolhas: raio máximo da bolha + respiro,
# para o disco inteiro caber na tela (não só o centro).
const BUBBLE_MARGIN: float = 40.0


## Retângulo de ação que o fit "contain" da câmera deve encaixar.
static func action_size(vp: Vector2) -> Vector2:
	return PORTRAIT_ACTION if Constants.is_portrait(vp) else LANDSCAPE_ACTION


static func caipora_pos(vp: Vector2) -> Vector2:
	var x := PORTRAIT_CAIPORA_X if Constants.is_portrait(vp) else LANDSCAPE_CAIPORA_X
	return Vector2(x, GROUND_Y)


static func enemy_pos(vp: Vector2) -> Vector2:
	var x := PORTRAIT_ENEMY_X if Constants.is_portrait(vp) else LANDSCAPE_ENEMY_X
	return Vector2(x, GROUND_Y)


## Mundo visível pela câmera (centro + viewport/zoom).
static func visible_rect(camera_pos: Vector2, vp: Vector2, zoom: float) -> Rect2:
	var size := vp / maxf(zoom, 0.001)
	return Rect2(camera_pos - size * 0.5, size)


## Área válida para spawn de bolhas de timing: interseção do que a câmera vê
## com o palco, encolhida pela margem — NADA nasce fora da tela, em nenhuma
## orientação (substitui as faixas absolutas BOSS_BUBBLE_X/Y, que vazariam
## da tela com o zoom de retrato).
static func bubble_rect(camera_pos: Vector2, vp: Vector2, zoom: float) -> Rect2:
	var stage := Rect2(STAGE_CENTER - STAGE_SIZE * 0.5, STAGE_SIZE)
	var rect := visible_rect(camera_pos, vp, zoom).intersection(stage)
	var grown := rect.grow(-BUBBLE_MARGIN)
	# Viewport degenerada (janela minúscula): a margem engoliria o rect e o
	# randf_range receberia min > max — devolve a interseção sem margem.
	if grown.size.x <= 0.0 or grown.size.y <= 0.0:
		return rect
	return grown


## Clamp de um ponto para dentro do retângulo de bolhas.
static func clamp_to_bubble_rect(pos: Vector2, rect: Rect2) -> Vector2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return pos
	return pos.clamp(rect.position, rect.end)
