// Recorta a própria arte de fundo no contorno dos móveis, para o elenco passar por
// trás do balcão e sumir na linha certa em vez de dentro de um retângulo reto.
// Cada móvel é um quadrilátero em coordenadas normais da arte: a borda de cima
// segue o tampo pintado nas duas pontas (que na perspectiva nunca é horizontal) e a
// base desce até fora da tela. Vagas vazias ficam em zero e não cortam nada.
shader_type canvas_item;

uniform vec4 prop0a = vec4(0.0);
uniform vec4 prop0b = vec4(0.0);
uniform vec4 prop1a = vec4(0.0);
uniform vec4 prop1b = vec4(0.0);
uniform vec4 prop2a = vec4(0.0);
uniform vec4 prop2b = vec4(0.0);
uniform vec4 prop3a = vec4(0.0);
uniform vec4 prop3b = vec4(0.0);
uniform vec4 prop4a = vec4(0.0);
uniform vec4 prop4b = vec4(0.0);
uniform vec4 prop5a = vec4(0.0);
uniform vec4 prop5b = vec4(0.0);
uniform vec4 prop6a = vec4(0.0);
uniform vec4 prop6b = vec4(0.0);
uniform vec4 prop7a = vec4(0.0);
uniform vec4 prop7b = vec4(0.0);

// Distância assinada do ponto ao lado da aresta, em fração da arte: o contorno é
// medido no mesmo espaço dos cantos, então a pena de suavização é a mesma da
// versão antiga de retângulos.
float edge_dist(vec2 from, vec2 to, vec2 p) {
	vec2 dir = to - from;
	return ((p.x - from.x) * dir.y - (p.y - from.y) * dir.x) / max(length(dir), 0.000001);
}

float quad_mask(vec2 uv, vec4 ab, vec4 cd) {
	vec2 v0 = ab.xy;
	vec2 v1 = ab.zw;
	vec2 v2 = cd.xy;
	vec2 v3 = cd.zw;
	float d0 = edge_dist(v0, v1, uv);
	float d1 = edge_dist(v1, v2, uv);
	float d2 = edge_dist(v2, v3, uv);
	float d3 = edge_dist(v3, v0, uv);
	// Aceita o contorno em qualquer sentido: dentro é o lado positivo para um
	// sentido de volta, ou o negativo para o outro.
	float inside = max(
		min(min(d0, d1), min(d2, d3)),
		-max(max(d0, d1), max(d2, d3))
	);
	if (inside <= 0.0) {
		return 0.0;
	}
	return smoothstep(0.0, 0.004, inside);
}

void fragment() {
	float mask = max(
		max(
			max(quad_mask(UV, prop0a, prop0b), quad_mask(UV, prop1a, prop1b)),
			max(quad_mask(UV, prop2a, prop2b), quad_mask(UV, prop3a, prop3b))
		),
		max(
			max(quad_mask(UV, prop4a, prop4b), quad_mask(UV, prop5a, prop5b)),
			max(quad_mask(UV, prop6a, prop6b), quad_mask(UV, prop7a, prop7b))
		)
	);
	if (mask <= 0.002) {
		discard;
	}
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, color.a * mask);
}
