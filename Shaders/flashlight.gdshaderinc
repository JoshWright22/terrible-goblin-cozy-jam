// Night Shift flashlight, shared by the dark overlay and anything that hides outside the light.
// xy: light position in screen UV, z: screen aspect, w: 1 during Night Shift, 0 otherwise
global uniform vec4 flashlight;

const float FLASHLIGHT_RADIUS = 0.17;
const float FLASHLIGHT_SOFTNESS = 0.09;

// 0 inside the light, 1 in the dark, always 0 when Night Shift is off
float flashlight_shade(vec2 screen_uv) {
	vec2 offset = (screen_uv - flashlight.xy) * vec2(flashlight.z, 1.0);
	return smoothstep(FLASHLIGHT_RADIUS, FLASHLIGHT_RADIUS + FLASHLIGHT_SOFTNESS, length(offset)) * flashlight.w;
}
