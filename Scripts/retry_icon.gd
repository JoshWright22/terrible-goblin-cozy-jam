@tool
extends Control
class_name RetryIcon

# Drawn circular arrow for retry buttons, shaded like the icons on the round buttons:
# flat fill with a darker copy peeking out below and to the left

@export var fill_color: Color = Color(0.95, 0.62, 0.3)
@export var shadow_color: Color = Color(0.6, 0.33, 0.12)
@export var shadow_offset: Vector2 = Vector2(-5, 6)

const GAP := 0.9   # radians left open where the arrow head sits

func _draw() -> void:
	_draw_arrow(shadow_offset, shadow_color)
	_draw_arrow(Vector2.ZERO, fill_color)

func _draw_arrow(offset: Vector2, color: Color) -> void:
	var center := size / 2.0 + offset
	var radius := minf(size.x, size.y) * 0.32
	var thickness := radius * 0.42
	# The arc runs clockwise from just right of the top, round to the head at the top
	var start := -PI / 2.0 + GAP
	var finish := -PI / 2.0 + TAU - 0.15
	draw_arc(center, radius, start, finish, 48, color, thickness, true)
	draw_circle(center + Vector2(cos(start), sin(start)) * radius, thickness / 2.0, color)
	# Head points along the arc, clockwise
	var tip_angle := finish + 0.05
	var base := center + Vector2(cos(finish), sin(finish)) * radius
	var along := Vector2(-sin(tip_angle), cos(tip_angle))
	var outward := Vector2(cos(finish), sin(finish))
	var head := PackedVector2Array([
		base + outward * thickness * 1.15,
		base - outward * thickness * 1.15,
		base + along * thickness * 1.5,
	])
	draw_colored_polygon(head, color)
