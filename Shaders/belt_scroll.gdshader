shader_type canvas_item;

uniform float scroll : hint_range(0.0, 100.0) = 0.0;

// Vertex color carries modulate, so conveyor style unlocks can tint the belt
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(scroll, 0.0)) * tint;
}
