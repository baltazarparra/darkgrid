class_name BackdropLayer
extends Node2D

## Camada estática do palco da arena: desenha UMA vez (via `draw_callback`) e
## faz o parallax do screenshake movendo `position` — mudar o transform de um
## nó é grátis, re-gravar comandos de desenho não é. Substitui o padrão antigo
## do ArenaBackdrop de queue_redraw a cada frame de shake, que re-gravava
## ~370 draw_texture_rect_region por frame exatamente nos frames de impacto
## (PLANO-performance-60fps §4, G3).

## Fração do offset da câmera que esta camada segue (profundidade do parallax).
var shake_follow: float = 0.0
## Recebe esta camada como canvas e desenha o conteúdo estático nela.
var draw_callback: Callable = Callable()

func _draw() -> void:
	if draw_callback.is_valid():
		draw_callback.call(self)
