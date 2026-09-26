shader_type canvas_item;

// Scene transition: three layers of smoothie pour up the screen one after another,
// like a layered drink, then carry on off the top.
// fill 0 -> 1 covers the screen, 1 -> 2 uncovers it from the bottom.

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform vec4 layer_back : source_color = vec4(0.55, 0.5, 0.85, 1.0);
uniform vec4 layer_middle : source_color = vec4(0.99, 0.7, 0.35, 1.0);
uniform vec4 layer_front : source_color = vec4(0.95, 0.52, 0.58, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.94, 0.88, 1.0);
uniform vec4 outline_color : source_color = vec4(0.13, 0.08, 0.08, 1.0);
uniform float aspect = 1.7778;

const float STAGGER = 0.22;   // how far behind each layer pours
const float SPREAD = 1.44;    // 1 + 2 * STAGGER so the last layer still finishes on time

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wave(float x, float seed, float speed) {
	return sin(x * 11.0 + seed * 3.7 + TIME * speed) * 0.018
		+ sin(x * 27.0 - seed * 1.3 - TIME * speed * 0.7) * 0.009;
}

// Returns rgb + coverage for one layer. order 0 pours first, 2 pours last.
vec4 layer(vec2 uv, float order, vec3 juice) {
	float height = 1.0 - uv.y;
	float cover = clamp(fill * SPREAD - order * STAGGER, 0.0, 1.0);
	// Draining happens front layer first so the stack peels away in reverse
	float drain = clamp((fill - 1.0) * SPREAD - (2.0 - order) * STAGGER, 0.0, 1.0);
	float top_edge = mix(-0.12, 1.12, cover) + wave(uv.x, order, 5.0 - order);
	float bottom_edge = mix(-0.12, 1.12, drain) + wave(uv.x + 3.1, order + 5.0, 4.0);

	float inside = step(height, top_edge) * step(bottom_edge, height);
	float draining = step(0.001, drain);
	float foam = step(top_edge - 0.028, height) + draining * step(height, bottom_edge + 0.022);

	vec2 grid = vec2(uv.x * aspect, height - TIME * (0.1 + order * 0.03)) * (13.0 + order * 3.0);
	vec2 cell = floor(grid) + order * 17.0;
	vec2 local = fract(grid) - 0.5;
	float bubble = step(length(local + (vec2(hash(cell + 3.0), hash(cell + 7.0)) - 0.5) * 0.4), hash(cell) * 0.28)
		* step(0.72, hash(cell + 11.0));

	vec3 col = mix(juice, foam_color.rgb, bubble * 0.35);
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	float ink = max(step(top_edge - 0.006, height), draining * step(height, bottom_edge + 0.006));
	col = mix(col, outline_color.rgb, ink);
	return vec4(col, inside);
}

void fragment() {
	vec4 back = layer(UV, 0.0, layer_back.rgb);
	vec4 middle = layer(UV, 1.0, layer_middle.rgb);
	vec4 front = layer(UV, 2.0, layer_front.rgb);

	vec3 col = back.rgb;
	float alpha = back.a;
	col = mix(col, middle.rgb, middle.a);
	alpha = max(alpha, middle.a);
	col = mix(col, front.rgb, front.a);
	alpha = max(alpha, front.a);
	COLOR = vec4(col, alpha);
}
