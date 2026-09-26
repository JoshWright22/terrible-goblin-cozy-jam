extends Node2D

# Settings board: volume sliders and on/off toggles, all saved through SaveManager

const ON_COLOR := Palette.GREEN
const OFF_COLOR := Palette.MUTED

signal closed

@onready var _rows: VBoxContainer = $Board/Rows
@onready var _back_btn: TextureButton = $BackButton

var overlay: bool = false   # opened from the pause menu, so close instead of changing scene

var _slider_tick_cooldown: float = 0.0

func _ready() -> void:
	if not overlay:
		AudioManager.start_menu_music()
	_add_slider("Music", "Music")
	_add_slider("Sound effects", "SFX")
	if SaveManager.can_toggle_fullscreen():
		_add_toggle("Fullscreen", SaveManager.fullscreen, func(on: bool):
			SaveManager.fullscreen = on
			SaveManager.apply_window(not on)
		)
	_add_toggle("Screen shake", SaveManager.screen_shake, func(on: bool):
		SaveManager.screen_shake = on
	)
	if not OS.has_feature("mobile"):
		_add_toggle("Mute in background", SaveManager.mute_unfocused, func(on: bool):
			SaveManager.mute_unfocused = on
		)

	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		SaveManager.save_game()
		if overlay:
			closed.emit()
		else:
			get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
	)
	BoardPaint.apply($Board, true, 0.15)
	# Sliders and toggles paint on after their row's name, like the calendar buttons
	for i in _rows.get_child_count():
		for item in _rows.get_child(i).get_children():
			if item is BaseButton or item is Slider:
				BoardPaint.paint_tree(item, 0.45 + i * 0.2, false)

func _process(delta: float) -> void:
	_slider_tick_cooldown = maxf(0.0, _slider_tick_cooldown - delta)

func _row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.custom_minimum_size = Vector2(0, 96)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(560, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 58)
	row.add_child(lbl)
	_rows.add_child(row)
	return row

func _add_slider(label_text: String, bus_name: String) -> void:
	var row := _row(label_text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(380, 60)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(slider)
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var db := AudioServer.get_bus_volume_db(idx)
		slider.value = db_to_linear(db) if db > -60.0 else 0.0
	row.add_child(slider)

	var pct := Label.new()
	pct.custom_minimum_size = Vector2(120, 0)
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct.add_theme_font_size_override("font_size", 52)
	pct.text = "%d%%" % int(round(slider.value * 100.0))
	row.add_child(pct)

	slider.mouse_entered.connect(AudioManager.play_button_hover)
	slider.value_changed.connect(func(value: float):
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, linear_to_db(value) if value > 0.0 else -80.0)
		pct.text = "%d%%" % int(round(value * 100.0))
		if _slider_tick_cooldown <= 0.0:
			_slider_tick_cooldown = 0.08
			AudioManager.play_slider_tick(0.7 + value * 0.6)
	)

func _add_toggle(label_text: String, start_on: bool, on_change: Callable) -> void:
	var row := _row(label_text)
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.button_pressed = start_on
	toggle.custom_minimum_size = Vector2(180, 80)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_toggle(toggle)
	toggle.toggled.connect(func(on: bool):
		_style_toggle(toggle)
		on_change.call(on)
		SaveManager.save_game()
	)
	ButtonFx.setup(toggle)
	row.add_child(toggle)

func _style_toggle(toggle: Button) -> void:
	toggle.text = "On" if toggle.button_pressed else "Off"
	ButtonFx.style_text_button(toggle, ON_COLOR if toggle.button_pressed else OFF_COLOR, 50)

# Chunky wooden slider: dark groove, cream fill, round knob, no new art needed
func _style_slider(slider: HSlider) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.3, 0.18, 0.08)
	groove.set_corner_radius_all(14)
	groove.content_margin_top = 12
	groove.content_margin_bottom = 12
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.86, 0.5)
	fill.set_corner_radius_all(14)
	fill.set_border_width_all(3)
	fill.border_color = Palette.WOOD_INK
	slider.add_theme_stylebox_override("slider", groove)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _knob_texture(Color(0.95, 0.52, 0.58))
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", _knob_texture(Color(1.0, 0.65, 0.7)))

func _knob_texture(color: Color) -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.72, 0.78, 0.9, 0.95])
	gradient.colors = PackedColorArray([color, color, Palette.WOOD_INK, Palette.WOOD_INK, Color(0.24, 0.13, 0.05, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 52
	tex.height = 52
	return tex
