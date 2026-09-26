shader_type canvas_item;

// Text painted on the wooden boards.
// reveal 0 -> 1 sweeps a brush across the label like a mask: a ragged, bristly edge wipes the paint on
// and a wet, slightly darker band trails behind it before it dries. Streaks follow the stroke.

uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float label_width = 600.0;       // local pixels, set per label
uniform float line_height = 60.0;
uniform float text_top = 0.0;           // where the first line starts inside the label
uniform float line_count = 1.0;          // lines paint one after another
uniform float grain : hint_range(0.0, 1.0) = 0.22;
uniform float streak_strength : hint_range(0.0, 1.0) = 0.35;

varying vec2 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(vec2(i, 1.0)), hash(vec2(i + 1.0, 1.0)), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	// Brush streaks run along the stroke: soft light and dark bands, no holes in the paint.
	// Fixed to the label so they don't swim when the label moves
	float streak = noise1(local_pos.y / 3.5) * 0.6 + noise1(local_pos.y / 9.0 + 20.0) * 0.4;
	streak += (noise1(local_pos.x / 40.0 + local_pos.y / 5.0) - 0.5) * 0.3;
	float wear = grain * smoothstep(0.75, 1.0, noise1(local_pos.y / 2.5 + 50.0)) * smoothstep(0.55, 0.9, noise1(local_pos.x / 25.0 + 7.0));

	// Brush edge: bristles make the front uneven line by line
	float feather = 38.0;
	float bristles = (noise1(local_pos.y / 3.0 + 90.0) - 0.5) * 30.0;
	float line = clamp(floor((local_pos.y - text_top) / line_height), 0.0, line_count - 1.0);
	float line_reveal = clamp(reveal * line_count - line, 0.0, 1.0);
	float front = line_reveal * (label_width + feather * 2.0) - feather + bristles;
	float painted = smoothstep(front + 6.0, front - 6.0, local_pos.x);
	float wet = smoothstep(front - feather * 2.5, front, local_pos.x) * step(line_reveal, 0.999);

	COLOR.a *= clamp(1.0 - wear, 0.0, 1.0) * painted;
	COLOR.rgb *= (1.0 - streak_strength * 0.3 + streak * streak_strength * 0.45) * (1.0 - wet * 0.18);
}
