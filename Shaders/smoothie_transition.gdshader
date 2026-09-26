shader_type canvas_item;

// Scene transition. The default pour: three pours of smoothie come up the screen one after
// another, split by foam and ink edges, then carry on off the top. The other styles are
// unlockable alternatives. Every style mixes the three juices and has rising bubbles.
// fill 0 -> 1 covers the screen, 1 -> 2 uncovers it from the bottom.

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform vec4 juice : source_color = vec4(0.95, 0.52, 0.58, 1.0);
uniform vec4 juice2 : source_color = vec4(0.99, 0.7, 0.35, 1.0);
uniform vec4 juice3 : source_color = vec4(0.55, 0.5, 0.85, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 0.94, 0.88, 1.0);
uniform vec4 outline_color : source_color = vec4(0.13, 0.08, 0.08, 1.0);
uniform float aspect = 1.7778;
// 0 pour, 1 bubbles, 2 swirl, 3 splash, 4 drip, 5 ripple, 6 stripes, 7 spiral, 8 hearts
uniform int style = 0;

const float STAGGER = 0.22;   // how far behind each layer pours
const float SPREAD = 1.44;    // 1 + 2 * STAGGER so the last layer still finishes on time

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wave(float x, float seed, float speed) {
	return sin(x * 11.0 + seed * 3.7 + TIME * speed) * 0.018
		+ sin(x * 27.0 - seed * 1.3 - TIME * speed * 0.7) * 0.009;
}

// One of the three juices, key 0 -> 1
vec3 pick(float key) {
	key = fract(key);
	if (key < 0.3333) {
		return juice.rgb;
	}
	return key < 0.6667 ? juice2.rgb : juice3.rgb;
}

// Small bubbles drifting up through the juice
float fizz(vec2 uv, float seed) {
	float height = 1.0 - uv.y;
	vec2 grid = vec2(uv.x * aspect, height - TIME * (0.1 + seed * 0.03)) * (13.0 + seed * 3.0);
	vec2 cell = floor(grid) + seed * 17.0;
	vec2 local = fract(grid) - 0.5;
	return step(length(local + (vec2(hash(cell + 3.0), hash(cell + 7.0)) - 0.5) * 0.4), hash(cell) * 0.28)
		* step(0.72, hash(cell + 11.0));
}

// Returns rgb + coverage for one layer of the classic pour. order 0 pours first, 2 pours last.
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

	vec3 col = mix(base, foam_color.rgb, fizz(uv, order) * 0.35);
	col = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
	float ink = max(step(top_edge - 0.006, height), draining * step(height, bottom_edge + 0.006));
	col = mix(col, outline_color.rgb, ink);
	return vec4(col, inside);
}

// The other styles share one look: juice where it covers, bubbles inside, foam and ink along its edge.
// key picks the juice, so each shape can take a different one
vec4 shaped(vec2 uv, float inside, float edge_dist, float key) {
	vec3 col = pick(key);
	col = mix(col, foam_color.rgb, fizz(uv, floor(fract(key) * 3.0)) * 0.35);
	col = mix(col, foam_color.rgb, step(edge_dist, 0.016));
	col = mix(col, outline_color.rgb, step(edge_dist, 0.006));
	return vec4(col, inside);
}

// progress runs 0 -> 1 -> 0 as fill goes 0 -> 1 -> 2

// Bubbles: round blobs pop up from the bottom row by row until they swallow the screen
vec4 bubbles(vec2 uv, float progress) {
	vec2 grid = vec2(uv.x * aspect, uv.y) * 7.0;
	// Big bubbles spill into the next cells, so check the neighbours too
	float best = -1.0;
	float key = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = floor(grid) + vec2(float(x), float(y));
			float row = 1.0 - (cell.y + 0.5) / 7.0;
			float delay = row * 0.55 + hash(cell) * 0.25;
			float grow = clamp((progress * 1.8 - delay) / 0.9, 0.0, 1.0);
			float d = grow * 0.78 - length(grid - cell - 0.5);
			if (grow > 0.001 && d > best) {
				best = d;
				key = hash(cell + 19.0);
			}
		}
	}
	return shaped(uv, step(0.0, best), best / 7.0, key);
}

// Swirl: the juice spins out from the middle like the blender just switched on
vec4 swirl(vec2 uv, float progress) {
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float turn = atan(p.y, p.x) / 6.2832 + 0.5;
	float reach = length(p) * 0.9 + fract(turn * 2.0 + TIME * 0.3) * 0.3;
	float front = progress * 1.5;
	return shaped(uv, step(reach, front), (front - reach) * 0.5, turn * 3.0 + TIME * 0.1);
}

// Splash: waves wash across from the bottom left corner, a different juice in each wave
vec4 splash(vec2 uv, float progress) {
	float reach = (uv.x * aspect * 0.5 + (1.0 - uv.y)) / (aspect * 0.5 + 1.0);
	reach += wave(uv.y * 1.6, 2.0, 4.0) * 2.0;
	float front = progress * 1.3 - 0.12;
	return shaped(uv, step(reach, front), front - reach, reach * 2.2);
}

// Drip: juice runs down from the top in columns of different lengths with round ends
float drip_tip(float cell, float local, float progress) {
	float length_here = progress * 1.55 - hash(vec2(cell, 3.0)) * 0.4;
	return length_here + cos(local * 3.1416) * 0.05 - 0.05;
}

vec4 drip(vec2 uv, float progress) {
	float columns = 9.0;
	float x = uv.x * columns;
	float cell = floor(x);
	float local = fract(x) - 0.5;
	float tip = drip_tip(cell, local, progress);
	float edge = tip - uv.y;
	// Outline the sides wherever the neighbouring drip is shorter
	float side = (0.5 - abs(local)) / columns * aspect;
	float neighbour = cell + sign(local);
	if (uv.y > drip_tip(neighbour, 0.0, progress) - 0.05) {
		edge = min(edge, side);
	}
	return shaped(uv, step(uv.y, tip), edge, hash(vec2(cell, 8.0)));
}


// Ripple: rings of juice spread out from the middle
vec4 ripple(vec2 uv, float progress) {
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float d = length(p) + sin(atan(p.y, p.x) * 6.0 + TIME * 2.0) * 0.012;
	float front = progress * 1.2;
	return shaped(uv, step(d, front), front - d, d * 3.0 - TIME * 0.15);
}

// Stripes: diagonal bands slide in, each from the opposite side to its neighbour
vec4 stripes(vec2 uv, float progress) {
	float across = (uv.x * aspect + uv.y) / (aspect + 1.0);
	float band = floor(across * 8.0);
	float along = (uv.x * aspect - uv.y + 1.0) / (aspect + 1.0);
	if (mod(band, 2.0) > 0.5) {
		along = 1.0 - along;
	}
	float front = progress * 1.4 - hash(vec2(band, 5.0)) * 0.3;
	// Ink down the long sides of each band as well as its front
	float f = fract(across * 8.0);
	float side = min(f, 1.0 - f) / 8.0 * (aspect + 1.0) * 0.5;
	return shaped(uv, step(along, front), min(front - along, side), band / 3.0 + 0.1);
}

// Spiral: one arm of juice winds out from the middle until it fills the screen
vec4 spiral(vec2 uv, float progress) {
	vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
	float turn = atan(p.y, p.x) / 6.2832 + 0.5;
	float r = length(p);
	float s = r * 1.1 + fract(turn - r * 1.5 + TIME * 0.2) * 0.35;
	float front = progress * 1.7;
	return shaped(uv, step(s, front), (front - s) * 0.5, r * 2.5 + turn);
}

// Hearts: like bubbles, but hearts. Signed distance to a heart about one unit tall, tip at the
// origin and y pointing up (negative inside)
float heart_dist(vec2 p) {
	p.x = abs(p.x);
	if (p.y + p.x > 1.0) {
		return length(p - vec2(0.25, 0.75)) - 0.35355;
	}
	vec2 a = p - vec2(0.0, 1.0);
	vec2 b = p - 0.5 * max(p.x + p.y, 0.0);
	return sqrt(min(dot(a, a), dot(b, b))) * sign(p.x - p.y);
}

vec4 hearts(vec2 uv, float progress) {
	vec2 grid = vec2(uv.x * aspect, uv.y) * 6.0;
	float best = -1.0;
	float key = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cell = floor(grid) + vec2(float(x), float(y));
			float row = 1.0 - (cell.y + 0.5) / 6.0;
			float delay = row * 0.55 + hash(cell) * 0.25;
			float grow = clamp((progress * 1.8 - delay) / 0.9, 0.0, 1.0);
			if (grow > 0.001) {
				float size = grow * 1.5;
				vec2 q = (grid - cell - 0.5) / size;
				q.y = -q.y + 0.5;
				float d = -heart_dist(q) * size;
				if (d > best) {
					best = d;
					key = hash(cell + 23.0);
				}
			}
		}
	}
	return shaped(uv, step(0.0, best), best / 6.0, key);
}

// The original three layer pour, one juice per layer
vec4 pour(vec2 uv) {
	vec4 back = layer(uv, 0.0, juice.rgb);
	vec4 middle = layer(uv, 1.0, juice2.rgb);
	vec4 front = layer(uv, 2.0, juice3.rgb);

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
	} else if (style == 4) {
		COLOR = drip(UV, progress);
	} else if (style == 5) {
		COLOR = ripple(UV, progress);
	} else if (style == 6) {
		COLOR = stripes(UV, progress);
	} else if (style == 7) {
		COLOR = spiral(UV, progress);
	} else if (style == 8) {
		COLOR = hearts(UV, progress);
	} else {
		COLOR = pour(UV);
	}
}
