// Recorta a própria arte de fundo nos retângulos dos móveis, para o elenco passar
// por trás do balcão e sumir de cintura para baixo em vez de andar por cima dele.
shader_type canvas_item;

uniform vec4 rect0 = vec4(0.0);
uniform vec4 rect1 = vec4(0.0);
uniform vec4 rect2 = vec4(0.0);
uniform vec4 rect3 = vec4(0.0);

float box_mask(vec2 uv, vec4 r) {
	if (r.z <= 0.0 || r.w <= 0.0) {
		return 0.0;
	}
	vec2 inside = min(uv - r.xy, r.xy + r.zw - uv);
	return smoothstep(0.0, 0.006, min(inside.x, inside.y));
}

void fragment() {
	float mask = max(
		max(box_mask(UV, rect0), box_mask(UV, rect1)),
		max(box_mask(UV, rect2), box_mask(UV, rect3))
	);
	if (mask <= 0.002) {
		discard;
	}
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, color.a * mask);
}
