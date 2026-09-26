shader_type canvas_item;

// Palette swap for the blue parts of existing art (blender style unlocks).
// Only saturated pixels in the blue hue range change, so outlines and white glass stay put.

uniform float target_hue = -1.0;           // 0-1, negative keeps the original colors
uniform float saturation_scale = 1.0;
uniform float value_scale = 1.0;
uniform vec2 source_hue_range = vec2(0.5, 0.72);

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (target_hue >= 0.0) {
		vec3 hsv = rgb2hsv(tex.rgb);
		float in_range = step(source_hue_range.x, hsv.x) * step(hsv.x, source_hue_range.y) * step(0.12, hsv.y);
		vec3 swapped = hsv2rgb(vec3(target_hue, clamp(hsv.y * saturation_scale, 0.0, 1.0), clamp(hsv.z * value_scale, 0.0, 1.0)));
		tex.rgb = mix(tex.rgb, swapped, in_range);
	}
	COLOR = tex;
}
