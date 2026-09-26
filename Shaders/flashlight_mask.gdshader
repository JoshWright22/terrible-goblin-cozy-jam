shader_type canvas_item;

// Night Shift: orders vanish completely outside the flashlight instead of just going dim

#include "res://Shaders/flashlight.gdshaderinc"

void fragment() {
	COLOR.a *= 1.0 - flashlight_shade(SCREEN_UV);
}
