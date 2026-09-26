class_name ButtonFx

# Same hover/press bounce the pause and game over buttons use, for any Control button

static func setup(btn: Control) -> void:
	btn.pivot_offset = btn.size / 2.0 if btn.size != Vector2.ZERO else btn.custom_minimum_size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func(): _hover_in(btn))
	btn.mouse_exited.connect(func(): _scale_to(btn, Vector2.ONE, 0.12))
	btn.button_down.connect(func():
		AudioManager.play_button_click()
		btn.create_tween().tween_property(btn, "scale", Vector2(0.9, 0.9), 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	)
	btn.button_up.connect(func(): _scale_to(btn, Vector2.ONE, 0.12))

static func _hover_in(btn: Control) -> void:
	if btn is BaseButton and btn.disabled:
		return
	AudioManager.play_button_hover()
	_scale_to(btn, Vector2(1.08, 1.08), 0.1)

static func _scale_to(btn: Control, target: Vector2, time: float) -> void:
	btn.create_tween().tween_property(btn, "scale", target, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Rounded, outlined text button that matches the game's chunky look
static func style_text_button(btn: Button, color: Color, font_size: int = 40) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		if state == "hover":
			box.bg_color = color.lightened(0.12)
		elif state == "pressed":
			box.bg_color = color.darkened(0.12)
		elif state == "disabled":
			box.bg_color = Color(0.55, 0.55, 0.55)
		elif state == "focus":
			box.draw_center = false
		box.set_corner_radius_all(22)
		box.set_border_width_all(5)
		box.border_color = Color(0.2, 0.13, 0.08)
		box.content_margin_left = 24
		box.content_margin_right = 24
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		btn.add_theme_stylebox_override(state, box)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	btn.add_theme_constant_override("outline_size", 8)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)

static func outline_label(lbl: Label, font_size: int, outline: int = 8) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("outline_size", outline)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hard_shadow(lbl, font_size, outline)

# Solid black drop shadow down and to the right, the same chunky offset the boards and buttons have
static func hard_shadow(lbl: Control, font_size: int, outline: int = 0) -> void:
	var offset := maxi(3, roundi(font_size * 0.06))
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", offset)
	lbl.add_theme_constant_override("shadow_offset_y", offset)
	lbl.add_theme_constant_override("shadow_outline_size", outline)
