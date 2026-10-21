shader_type canvas_item;

uniform vec2 rect_size = vec2(5600.0, 4600.0);
uniform vec2 arena_origin = vec2(1200.0, 1200.0);
uniform vec2 arena_size = vec2(3200.0, 2200.0);
uniform vec4 deep : source_color = vec4(0.010, 0.025, 0.060, 1.0);
uniform vec4 shallow : source_color = vec4(0.028, 0.075, 0.140, 1.0);
uniform vec4 glint : source_color = vec4(0.25, 0.70, 0.90, 1.0);
uniform float detail = 1.0;
uniform float use_fog = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 w = UV * rect_size;
	float t = TIME;
	vec2 p = w / 260.0;
	float n = noise(p + vec2(t * 0.05, t * 0.03)) * 0.6 + noise(p * 2.3 - vec2(t * 0.08, -t * 0.04)) * 0.4;
	vec3 col = mix(deep.rgb, shallow.rgb, n);
	float lines = noise(w / 90.0 + vec2(t * 0.15, t * 0.10));
	float lines2 = noise(w / 140.0 - vec2(t * 0.07, t * 0.12));
	float g = smoothstep(0.80, 0.88, lines) * 0.10 * detail + smoothstep(0.84, 0.90, lines2) * 0.06 * detail;
	col += glint.rgb * g;
	vec2 a0 = arena_origin;
	vec2 a1 = arena_origin + arena_size;
	vec2 d = max(a0 - w, w - a1);
	float outside = max(d.x, d.y);
	float fog = smoothstep(0.0, 260.0, outside) * use_fog;
	col = mix(col, vec3(0.004, 0.008, 0.018), fog * 0.85);
	COLOR = vec4(col, 1.0);
}
