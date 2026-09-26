extends Node2D

# Costume pieces live in the sprite's texture coordinates, following its mood,
# highlight scale and arrival/exit fades without covering customer badges.
var look: int = 0
const NOSES := [Vector2(0.255, 0.238), Vector2(0.503, 0.230), Vector2(0.55, 0.35), Vector2(0.54, 0.265), Vector2(0.28, 0.18)]
const WIGS := [Vector2(0.325, 0.15), Vector2(0.51, 0.17), Vector2(0.55, 0.19), Vector2(0.52, 0.105), Vector2(0.38, 0.09)]
const COLORS := [Color("ff5c96"), Color("7d5cff"), Color("22cbb5"), Color("ffb52e"), Color("55aaff")]
const EDGE := Color("49352f")

func _ready() -> void:
	name = "CarnivalCostume"
	get_parent().texture_changed.connect(queue_redraw)

func _draw() -> void:
	var sprite := get_parent() as Sprite2D
	if sprite.texture == null:
		return
	var size := sprite.texture.get_size()
	var origin := sprite.get_rect().position
	var wig: Vector2 = origin + WIGS[look] * size
	var radius := size.x * (0.045 if look == 4 else 0.065)
	var spread := size.x * (0.08 if look == 4 else 0.20)
	# Curly side wigs keep eyes, hats and facial expressions readable.
	for side in [-1, 1]:
		var center: Vector2 = wig + Vector2(side * spread, 0)
		for curl in 7:
			var angle := curl * TAU / 7.0
			var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.70
			draw_circle(pos, radius * 0.65 + 4.0, EDGE)
			draw_circle(pos, radius * 0.65, COLORS[(look + curl / 3) % COLORS.size()])
		var color: Color = COLORS[look]
		draw_circle(center, radius * 0.75, color)
		draw_arc(center, radius * 0.38, 0.0, PI * 1.5, 16, color.lightened(0.3), 4.0, true)
	var nose: Vector2 = origin + NOSES[look] * size
	var nose_radius := size.x * (0.035 if look == 4 else 0.04)
	draw_circle(nose, nose_radius + 4.0, EDGE)
	draw_circle(nose, nose_radius, Color("ef344b"))
	draw_circle(nose + Vector2(-0.28, -0.28) * nose_radius, nose_radius * 0.27, Color("ffd7dd"))
