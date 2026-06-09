shader_type canvas_item;

// Vento na vegetação: desloca vértices em X com seno ponderado pela altura —
// raiz cravada (peso 0 em base_y), copa balançando (peso máximo a `span` px
// acima). Fase varia com VERTEX.x: árvores da mesma silhueta dessincronizam.
// Vertex shader puro: anima via TIME sem queue_redraw (gl_compatibility-safe).

uniform float base_y = 560.0;  // y local da raiz (abaixo disso nada balança)
uniform float span = 140.0;    // px acima da raiz até o sway máximo
uniform float amount = 2.5;    // deslocamento máximo no topo (px)
uniform float speed = 1.1;

void vertex() {
	float w = clamp((base_y - VERTEX.y) / span, 0.0, 1.0);
	VERTEX.x += sin(TIME * speed + VERTEX.x * 0.021 + VERTEX.y * 0.05) * amount * w * w;
}
