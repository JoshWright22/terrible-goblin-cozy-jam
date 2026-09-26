shader_type canvas_item;

// Fruit piece looks for the Heatwave and Brain Freeze twists.
// melt 0 -> 1: the fruit warms up, slumps into uneven drips and fades away at the end.
// frozen: icy tint with frosted edges, white cracks, and icicles hanging off the underside.
// Pieces rotate, so the script passes which way is down in texture space.

uniform float melt : hint_range(0.0, 1.0) = 0.0;
uniform bool frozen = false;
uniform float seed = 0.0;               // per piece so every fruit melts and cracks differently
uniform vec2 down = vec2(0.0, 1.0);

const vec3 MELT_TINT = vec3(1.0, 0.62, 0.35);
const vec3 ICE = vec3(0.72, 0.9, 1.0);
const vec3 ICE_EDGE = vec3(0.93, 0.98, 1.0);
const float ROOM = 44.0;                // texture pixels added on every side for drips and icicles
const float ICICLE_SPACING = 26.0;
const float ICICLE_LENGTH = 40.0;
const float DRIP_SPACING = 14.0;
const float DRIP_LENGTH = 34.0;

varying vec4 tint;   // modulate only; COLOR in fragment() already has the texture baked in

void vertex() {
	tint = COLOR;
	vec2 outward = sign(UV - 0.5);
	VERTEX += outward * ROOM;
	UV += outward * ROOM * TEXTURE_PIXEL_SIZE;
}

// Anything outside the texture (the extra room) is empty
vec4 sample_fruit(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(tex, uv);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(vec2(i, seed)), hash(vec2(i + 1.0, seed)), f * f * (3.0 - 2.0 * f));
}

// Distance to the nearest cell edge of a jittered grid, used for the crack lines
float crack_lines(vec2 p) {
	vec2 cell = floor(p);
	float first = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 other = cell + vec2(float(x), float(y));
			vec2 point = other + vec2(hash(other + seed), hash(other.yx + seed * 1.7));
			float d = length(p - point);
			if (d < first) {
				second = first;
				first = d;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return second - first;
}

vec4 melted(sampler2D tex, vec2 uv, vec2 pixel) {
	// Each strip slides down by a different amount, so the fruit sags into drips
	vec2 across_dir = vec2(-down.y, down.x);
	float strip = dot(uv / pixel, across_dir) / DRIP_SPACING;
	float drop = melt * DRIP_LENGTH * (0.2 + 0.8 * noise(strip));
	vec4 col = sample_fruit(tex, uv - down * drop * pixel);
	col.rgb = mix(col.rgb, col.rgb * MELT_TINT, melt * 0.8);
	col.a *= 1.0 - smoothstep(0.7, 1.0, melt);
	return col;
}

vec4 iced(sampler2D tex, vec2 uv, vec2 pixel, vec4 col) {
	if (col.a > 0.4) {
		// Frost is heaviest where the fruit meets empty space
		float edge = 0.0;
		for (int i = 0; i < 4; i++) {
			float a = float(i) * 1.5708;
			edge += 1.0 - sample_fruit(tex, uv + vec2(cos(a), sin(a)) * pixel * 6.0).a;
		}
		col.rgb = mix(col.rgb, ICE, 0.35);
		col.rgb = mix(col.rgb, ICE_EDGE, clamp(edge * 0.35, 0.0, 0.75));
		float crack = 1.0 - smoothstep(0.02, 0.06, crack_lines(uv * vec2(4.0, 3.0) + seed));
		col.rgb = mix(col.rgb, vec3(1.0), crack * 0.8);
		return col;
	}
	// Below the fruit: look up for the underside and hang an icicle from it
	vec2 across_dir = vec2(-down.y, down.x);
	float along = dot(uv / pixel, across_dir) / ICICLE_SPACING;
	float column = floor(along);
	float across = fract(along) - 0.5;
	float length_here = ICICLE_LENGTH * (0.35 + 0.65 * hash(vec2(column, seed)));
	for (int step_i = 1; step_i <= 12; step_i++) {
		float depth = float(step_i) / 12.0 * length_here;
		if (sample_fruit(tex, uv - down * depth * pixel).a > 0.4) {
			float width = 0.42 * (1.0 - depth / length_here);
			if (abs(across) < width) {
				float shine = 1.0 - abs(across) / max(width, 0.001);
				return vec4(mix(ICE, ICE_EDGE, shine), 0.9);
			}
			break;
		}
	}
	return col;
}

void fragment() {
	vec4 col = melted(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
	if (frozen) {
		col = iced(TEXTURE, UV, TEXTURE_PIXEL_SIZE, col);
	}
	COLOR = col * tint;
}
