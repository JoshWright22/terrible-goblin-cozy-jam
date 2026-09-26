shader_type canvas_item;

// Night Shift: everything is dark except a soft circle of light around the cursor

uniform vec2 light_uv = vec2(0.5);
uniform float aspect = 1.7778;
uniform float radius = 0.17;
uniform float softness = 0.09;
uniform float darkness : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec2 offset = (UV - light_uv) * vec2(aspect, 1.0);
	float shade = smoothstep(radius, radius + softness, length(offset));
	COLOR = vec4(0.02, 0.03, 0.09, shade * darkness);
}
