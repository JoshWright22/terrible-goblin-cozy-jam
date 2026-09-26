@tool
extends Control
class_name StarIcon

# Drawn star so star ratings don't need new art

@export var filled: bool = true:
	set(value):
		filled = value
		queue_redraw()
@export var fill_color: Color = Palette.GOLD
@export var empty_color: Color = Color(0.2, 0.12, 0.05, 0.35)
@export var outline_color: Color = Palette.WOOD_INK
@export var draw_offset: Vector2 = Vector2.ZERO   # nudges the star, e.g. down to line up with text

func _draw() -> void:
	var center := size / 2.0 + draw_offset
	var outer := minf(size.x, size.y) / 2.0 - 3.0
	var inner := outer * 0.45
	var points := PackedVector2Array()
	for i in 10:
		var r := outer if i % 2 == 0 else inner
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, fill_color if filled else empty_color)
	points.append(points[0])
	draw_polyline(points, outline_color, 4.0, true)
