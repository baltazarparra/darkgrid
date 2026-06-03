class_name ForestLight
extends RefCounted

## Fábrica de luzes 2D da floresta (PointLight2D). Centraliza textura radial e
## blend aditivo para reuso por fogueiras, saída e Caipora. Sobre um CanvasModulate
## escuro, a luz "devolve" brilho/cor só no raio iluminado — poça de luz quente na
## mata. Compatível com gl_compatibility (export web).
##
## texture_scale: a textura é 256px (raio ~128px); scale 0.75 ≈ 3 tiles de raio,
## scale 1.25 ≈ 5 tiles. Use blend ADD para somar sobre a noite.

const LIGHT_TEXTURE := preload("res://assets/sprites/light_radial.png")

static func make(color: Color, energy: float, texture_scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = LIGHT_TEXTURE
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	return light
