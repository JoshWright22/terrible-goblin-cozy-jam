extends Node2D

var sets: float = 0.0
var score_gain: int = 0

@onready var label: Label = $Label

func _ready() -> void:
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 5)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))

	if score_gain > 0:
		label.text = "+%d" % score_gain
		_play_success()
	else:
		label.text = "MISS!"
		label.add_theme_font_size_override("font_size", 46)
		_play_fail()

func _play_success() -> void:
	var orig_scale := scale
	var start_pos := position
	scale = Vector2.ZERO
	rotation = randf_range(-0.25, 0.25)

	var float_h := 170.0 + orig_scale.x * 55.0
	var end_pos := start_pos + Vector2(randf_range(-30.0, 30.0), -float_h)

	var tw := create_tween()

	# Slam in with big overshoot, snap rotation to 0
	tw.tween_property(self, "scale", orig_scale * 1.8, 0.12) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "rotation", 0.0, 0.12) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Squash-stretch bounce
	tw.tween_property(self, "scale", Vector2(orig_scale.x * 1.35, orig_scale.y * 0.72), 0.07)
	tw.tween_property(self, "scale", Vector2(orig_scale.x * 0.82, orig_scale.y * 1.22), 0.07)
	tw.tween_property(self, "scale", Vector2(orig_scale.x * 1.08, orig_scale.y * 0.94), 0.06)
	tw.tween_property(self, "scale", orig_scale, 0.05) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Float up, fade in last third
	tw.tween_property(self, "position", end_pos, 1.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.55) \
		.set_delay(1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tw.finished.connect(queue_free)

func _play_fail() -> void:
	var orig_scale := scale
	var orig_pos := position

	# Start skinny and stretched tall above target
	scale = Vector2(orig_scale.x * 0.25, orig_scale.y * 2.4)
	position = orig_pos + Vector2(randf_range(-8.0, 8.0), -70.0)
	rotation = randf_range(-0.12, 0.12)

	var tw := create_tween()

	# Slam straight down — squash hard on impact
	tw.tween_property(self, "position", orig_pos, 0.07) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2(orig_scale.x * 2.5, orig_scale.y * 0.28), 0.07)
	tw.parallel().tween_property(self, "rotation", 0.0, 0.07)

	# Bounce up: tall again
	tw.tween_property(self, "scale", Vector2(orig_scale.x * 0.6, orig_scale.y * 1.7), 0.07)
	tw.tween_property(self, "scale", Vector2(orig_scale.x * 1.3, orig_scale.y * 0.8), 0.06)
	tw.tween_property(self, "scale", orig_scale, 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Violent side shake with decaying amplitude
	tw.tween_method(func(t: float): _shake(orig_pos.x, t), 0.0, 1.0, 0.5)

	# Crash off screen: spin, drop, fade
	var exit_x := orig_pos.x + randf_range(-50.0, 50.0)
	tw.tween_property(self, "position", Vector2(exit_x, orig_pos.y + 90.0), 0.35) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(self, "rotation", randf_range(-0.8, 0.8), 0.35)
	tw.parallel().tween_property(self, "scale", orig_scale * 0.4, 0.35)

	tw.finished.connect(queue_free)

func _shake(base_x: float, t: float) -> void:
	var amp := 22.0 * (1.0 - t)
	position.x = base_x + sin(t * PI * 10.0) * amp
