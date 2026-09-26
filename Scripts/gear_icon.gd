@tool
extends Control
class_name GearIcon

# Drawn gear for the settings button, shaded like the icons on the other round buttons:
# flat fill with a darker copy peeking out below and to the left

@export var fill_color: Color = Color(0.46, 0.72, 0.87)
@export var shadow_color: Color = Color(0.22, 0.38, 0.52)
@export var hole_color: Color = Color(0.83, 0.68, 0.5)   # the disc sprite's flat middle
@export var shadow_offset: Vector2 = Vector2(-5, 6)
@export var teeth: int = 8

func _draw() -> void:
	var center := size / 2.0
	var outer := minf(size.x, size.y) / 2.0 - 4.0
	var gear := _gear_points(center, outer, outer * 0.74)
	var shadow := PackedVector2Array()
	for point in gear:
		shadow.append(point + shadow_offset)
	draw_colored_polygon(shadow, shadow_color)
	draw_colored_polygon(gear, fill_color)
	draw_circle(center, outer * 0.28, shadow_color)
	draw_circle(center - shadow_offset * 0.4, outer * 0.26, hole_color)

# Each tooth is a flat-topped bump: two points out, two points in
func _gear_points(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var step := TAU / teeth
	for i in teeth:
		for part in [[0.0, inner], [0.18, outer], [0.5, outer], [0.68, inner]]:
			var angle: float = step * i + step * part[0]
			points.append(center + Vector2(cos(angle), sin(angle)) * part[1])
	return points
