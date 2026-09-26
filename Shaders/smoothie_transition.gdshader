shader_type canvas_item;

// Scene transition. The default pour: three pours of the same smoothie come up the screen one
// after another, split by foam and ink edges, then carry on off the top. Bubbles, swirl and splash
// are unlockable alternatives.
// fill 0 -> 1 covers the screen, 1 -> 2 uncovers it from the bottom.

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform vec4 juice : source_color = vec4(0.95, 0.52, 0.58, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.94, 0.88, 1.0);
uniform vec4 outline_color : source_color = vec4(0.13, 0.08, 0.08, 1.0);
uniform float aspect = 1.7778;
uniform int style = 0;         // 0 pour, 1 bubbles, 2 swirl, 3 splash

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
vec4 layer(vec2 uv, float order, vec3 base) {
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

	vec3 col = mix(base, foam_color.rgb, bubble * 0.35);
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	float ink = max(step(top_edge - 0.006, height), draining * step(height, bottom_edge + 0.006));
	col = mix(col, outline_color.rgb, ink);
	return vec4(col, inside);
}

// The other pour styles share one shape: juice where cover > 0, foam and ink along its edge.
// progress runs 0 -> 1 -> 0 as fill goes 0 -> 1 -> 2
vec4 shaped(float inside, float edge_dist) {
	vec3 col = juice.rgb;
	col = mix(col, foam_color.rgb, step(edge_dist, 0.016));
	col = mix(col, outline_color.rgb, step(edge_dist, 0.006));
	return vec4(col, inside);
}

// Bubbles: round blobs pop up from the bottom row by row until they swallow the screen
vec4 bubbles(vec2 uv, float progress) {
	vec2 grid = vec2(uv.x * aspect, uv.y) * 7.0;
	// Big bubbles spill into the next cells, so check the neighbours too
	float best = -1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = floor(grid) + vec2(float(x), float(y));
			float row = 1.0 - (cell.y + 0.5) / 7.0;
			float delay = row * 0.55 + hash(cell) * 0.25;
			float grow = clamp((progress * 1.8 - delay) / 0.9, 0.0, 1.0);
			float radius = grow * 0.78;
			float d = length(grid - cell - 0.5);
			if (grow > 0.001) {
				best = max(best, radius - d);
			}
		}
	}
	return shaped(step(0.0, best), best / 7.0);
}

// Swirl: the juice spins out from the middle like the blender just switched on
vec4 swirl(vec2 uv, float progress) {
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float turn = atan(p.y, p.x) / 6.2832 + 0.5;
	float reach = length(p) * 0.9 + fract(turn * 2.0 + TIME * 0.3) * 0.3;
	float front = progress * 1.5;
	return shaped(step(reach, front), (front - reach) * 0.5);
}

// Splash: one big wave washes across from the bottom left corner
vec4 splash(vec2 uv, float progress) {
	float reach = (uv.x * aspect * 0.5 + (1.0 - uv.y)) / (aspect * 0.5 + 1.0);
	reach += wave(uv.y * 1.6, 2.0, 4.0) * 2.0;
	float front = progress * 1.3 - 0.12;
	return shaped(step(reach, front), front - reach);
}

// The original three layer pour
vec4 pour(vec2 uv) {
	vec4 back = layer(uv, 0.0, juice.rgb);
	vec4 middle = layer(uv, 1.0, juice.rgb);
	vec4 front = layer(uv, 2.0, juice.rgb);

	vec3 col = back.rgb;
	float alpha = back.a;
	col = mix(col, middle.rgb, middle.a);
	alpha = max(alpha, middle.a);
	col = mix(col, front.rgb, front.a);
	alpha = max(alpha, front.a);
	return vec4(col, alpha);
}

void fragment() {
	float progress = fill <= 1.0 ? fill : 2.0 - fill;
	if (style == 1) {
		COLOR = bubbles(UV, progress);
	} else if (style == 2) {
		COLOR = swirl(UV, progress);
	} else if (style == 3) {
		COLOR = splash(UV, progress);
	} else {
		COLOR = pour(UV);
	}
}
