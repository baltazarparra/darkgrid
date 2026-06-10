class_name CaiporaSkin
extends RefCounted

## Aparência da Caipora dirigida pela meta-progressão — ponto ÚNICO de seleção
## E aplicação dos SpriteFrames (par do WeaponVisual.attach_to). Com a CHAMA
## conquistada é ELA que se incendeia: variante com juba mais longa/quente e
## brasas orbitando (docs/CONCEITO-protagonista.md, §6).
##
## As duas variantes têm o MESMO contrato de animações (idle/walk/windup/
## strike/recover), então ActorAnimator e cenas não percebem a troca.
## Consumidores: exploração (caipora.gd), arena (arena_manager.gd) e
## TitleWalker (menu/ending).

const FRAMES_PATH: String = "res://assets/sprites/caipora_sprite_frames.tres"
const FRAMES_CHAMA_PATH: String = "res://assets/sprites/caipora_sprite_frames_chama.tres"

## Path do SpriteFrames da Caipora conforme a meta-progressão.
static func frames_path() -> String:
	return FRAMES_CHAMA_PATH if MetaProgression.has_chama else FRAMES_PATH

## Aplica os frames corretos à sprite. Preserva a animação corrente quando ela
## existe na variante (senão volta ao idle); no-op se nada muda ou se o
## resource não carrega (nunca deixa a Caipora invisível).
static func apply(sprite: AnimatedSprite2D) -> void:
	if sprite == null:
		return
	var frames := load(frames_path()) as SpriteFrames
	if frames == null:
		push_warning("CaiporaSkin: SpriteFrames não carregou (%s)" % frames_path())
		return
	if sprite.sprite_frames == frames:
		return
	var current: StringName = sprite.animation
	sprite.sprite_frames = frames
	sprite.play(current if frames.has_animation(current) else &"idle")
