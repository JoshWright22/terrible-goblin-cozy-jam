extends Control
class_name PrizeWheel

# Boardwalk Carnival prize wheel, drawn so it needs no art. It spins, lands the chosen
# slice under the pointer at the top, then hands control back and fades away

const SLICE_COLORS := [Color(0.95, 0.45, 0.55), Color(1.0, 0.82, 0.3), Color(0.45, 0.72, 0.9), Color(0.6, 0.82, 0.45)]
const INK := Color(0.24, 0.13, 0.05)
const SPIN_TIME := 1.6
const TURNS := 4

var prizes: Array = []   # one label per slice
var _angle: float = 0.0

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 8.0
	var step := TAU / prizes.size()
	var font := get_theme_default_font()
	for i in prizes.size():
		var start := _angle + i * step - PI / 2.0
		var points := PackedVector2Array([center])
		for s in 17:
			var a := start + step * s / 16.0
			points.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_colored_polygon(points, SLICE_COLORS[i % SLICE_COLORS.size()])
		draw_line(center, points[1], INK, 4.0, true)
		# Labels stay upright so they're readable while it spins
		var mid := start + step / 2.0
		var at := center + Vector2(cos(mid), sin(mid)) * radius * 0.6
		var text: String = prizes[i]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var spot := at + Vector2(-width / 2.0, 9.0)
		draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 8, INK)
		draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	draw_arc(center, radius, 0.0, TAU, 64, INK, 7.0, true)
	draw_circle(center, radius * 0.12, INK)
	draw_circle(center, radius * 0.07, Color(1.0, 0.95, 0.8))
	# Pointer over the top edge, pointing down into the winning slice
	var top := center + Vector2(0.0, -radius)
	var pointer := PackedVector2Array([top + Vector2(-18, -26), top + Vector2(18, -26), top + Vector2(0, 14)])
	draw_colored_polygon(pointer, Color(1.0, 0.95, 0.8))
	pointer.append(pointer[0])
	draw_polyline(pointer, INK, 4.0, true)

# Spins a few turns and stops with prize `index` under the pointer
func spin(index: int, on_landed: Callable) -> void:
	var step := TAU / prizes.size()
	var target := TAU * TURNS - (index + 0.5) * step
	pivot_offset = size / 2.0
	scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_angle, 0.0, target, SPIN_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_callback(on_landed)
	tw.tween_interval(0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func _set_angle(value: float) -> void:
	_angle = value
	queue_redraw()
