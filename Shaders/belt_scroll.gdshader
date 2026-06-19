shader_type canvas_item;

uniform float scroll : hint_range(0.0, 100.0) = 0.0;

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(scroll, 0.0));
}
