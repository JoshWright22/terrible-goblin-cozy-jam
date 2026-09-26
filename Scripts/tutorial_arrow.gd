extends Node2D

# Chunky inked arrow pointing down, tip at this node's origin

@export var fill_color: Color = Color(1.0, 0.84, 0.45)
@export var ink_color: Color = Color(0.13, 0.08, 0.08)

func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0, 0), Vector2(-38, -46), Vector2(-16, -46), Vector2(-16, -110),
		Vector2(16, -110), Vector2(16, -46), Vector2(38, -46),
	])
	draw_colored_polygon(points, fill_color)
	points.append(points[0])
	draw_polyline(points, ink_color, 6.0, true)
