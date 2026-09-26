shader_type canvas_item;

// Text painted on the wooden boards.
// reveal 0 -> 1 sweeps a brush across the label: a ragged, bristly edge wipes the paint on
// and a wet, slightly darker band trails behind it before it dries.

uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float label_width = 600.0;       // local pixels, set per label
uniform float line_height = 60.0;
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

void fragment() {
	// Dry brush wear, fixed to the label so it doesn't swim when the label moves
	vec2 cell = floor(local_pos / 2.5);
	float speckle = hash(cell);
	float streak = hash(vec2(floor(local_pos.y / 3.0), 7.0));
	float wear = grain * (speckle * 0.65 + streak * streak_strength);

	// Brush edge: bristles make the front uneven line by line
	float feather = 38.0;
	float bristles = (hash(vec2(floor(local_pos.y / 4.0), 3.0)) - 0.5) * 26.0;
	float line = clamp(floor(local_pos.y / line_height), 0.0, line_count - 1.0);
	float line_reveal = clamp(reveal * line_count - line, 0.0, 1.0);
	float front = line_reveal * (label_width + feather * 2.0) - feather + bristles;
	float painted = smoothstep(front + 6.0, front - 6.0, local_pos.x);
	float wet = smoothstep(front - feather * 2.5, front, local_pos.x) * step(line_reveal, 0.999);

	COLOR.a *= clamp(1.0 - wear, 0.0, 1.0) * painted;
	COLOR.rgb *= (0.93 + 0.07 * streak) * (1.0 - wet * 0.18);
}
