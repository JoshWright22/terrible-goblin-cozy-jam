shader_type canvas_item;

// Dry brush look for text painted on the wooden boards:
// small speckles plus faint horizontal brush streaks eat into the paint.

uniform float grain : hint_range(0.0, 1.0) = 0.22;
uniform float streak_strength : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / 2.5);
	float speckle = hash(cell);
	float streak = hash(vec2(floor(FRAGCOORD.y / 3.0), 7.0));
	float wear = grain * (speckle * 0.65 + streak * streak_strength);
	COLOR.a *= clamp(1.0 - wear, 0.0, 1.0);
	COLOR.rgb *= 0.93 + 0.07 * streak;
}
