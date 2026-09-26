@tool
extends Control
class_name GearIcon

# Drawn gear for the settings button, so it matches the round pause buttons without new art

@export var fill_color: Color = Color(0.45, 0.62, 0.85)
@export var outline_color: Color = Color(0.2, 0.13, 0.08)
@export var teeth: int = 8

func _draw() -> void:
	var center := size / 2.0
	var outer := minf(size.x, size.y) / 2.0 - 4.0
	var inner := outer * 0.74
	var points := PackedVector2Array()
	# Each tooth is a flat-topped bump: two points out, two points in
	for i in teeth:
		var start := TAU * i / teeth
		var step := TAU / teeth
		for part in [[0.0, inner], [0.18, outer], [0.5, outer], [0.68, inner]]:
			var angle: float = start + step * part[0]
			points.append(center + Vector2(cos(angle), sin(angle)) * part[1])
	draw_colored_polygon(points, fill_color)
	points.append(points[0])
	draw_polyline(points, outline_color, 5.0, true)
	draw_circle(center, outer * 0.32, outline_color)
	draw_circle(center, outer * 0.22, Color(0.99, 0.95, 0.82))
