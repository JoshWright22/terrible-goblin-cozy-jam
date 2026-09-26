shader_type canvas_item;

// Night Shift: everything is dark except a soft circle of light around the cursor

#include "res://Shaders/flashlight.gdshaderinc"

uniform float darkness : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	COLOR = vec4(0.02, 0.03, 0.09, flashlight_shade(SCREEN_UV) * darkness);
}
