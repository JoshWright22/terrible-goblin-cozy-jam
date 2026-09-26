shader_type canvas_item;

// Scene transition: a wall of smoothie pours up the screen, then carries on off the top.
// fill 0 -> 1 covers the screen, 1 -> 2 uncovers it from the bottom.

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform vec4 juice_color : source_color = vec4(0.95, 0.52, 0.58, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.94, 0.88, 1.0);
uniform vec4 outline_color : source_color = vec4(0.13, 0.08, 0.08, 1.0);
uniform float aspect = 1.7778;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wave(float x, float speed) {
	return sin(x * 11.0 + TIME * speed) * 0.018 + sin(x * 27.0 - TIME * speed * 0.7) * 0.009;
}

void fragment() {
	float height = 1.0 - UV.y;                 // 0 at the bottom of the screen
	float top_edge = mix(-0.12, 1.12, clamp(fill, 0.0, 1.0)) + wave(UV.x, 5.0);
	float bottom_edge = mix(-0.12, 1.12, clamp(fill - 1.0, 0.0, 1.0)) + wave(UV.x + 3.1, 4.0);

	float inside = step(height, top_edge) * step(bottom_edge, height);
	float foam = inside * step(top_edge - 0.03, height);
	float drip = inside * step(height, bottom_edge + 0.025) * step(0.001, fill - 1.0);

	// Bubbles rising through the juice
	vec2 grid = vec2(UV.x * aspect, height - TIME * 0.12) * 14.0;
	vec2 cell = floor(grid);
	vec2 local = fract(grid) - 0.5;
	float bubble_size = hash(cell) * 0.28;
	float bubble = step(length(local + (vec2(hash(cell + 3.0), hash(cell + 7.0)) - 0.5) * 0.4), bubble_size)
		* step(0.7, hash(cell + 11.0));

	vec3 col = juice_color.rgb;
	col = mix(col, foam_color.rgb, bubble * 0.35);
	col = mix(col, foam_color.rgb, max(foam, drip));
	// Inked edges like the rest of the art
	float ink = inside * max(step(top_edge - 0.006, height), step(height, bottom_edge + 0.006) * step(0.001, fill - 1.0));
	col = mix(col, outline_color.rgb, ink);
	COLOR = vec4(col, inside);
}
