extends Node2D

# Style unlocks: pick blender, wall, conveyor, transition, pour style and paint options earned with stars

const SWATCH_SIZE := Vector2(84, 84)
const SELECTED_BORDER := Color(1.0, 0.84, 0.3)
const NORMAL_BORDER := Color(0.24, 0.13, 0.05)

@onready var _rows: VBoxContainer = $Board/Rows
@onready var _stars_box: HBoxContainer = $Board/StarsBox
@onready var _hint_box: HBoxContainer = $Board/HintBox
@onready var _back_btn: TextureButton = $BackButton

var _swatches: Dictionary = {}   # category -> Array[Button]

func _ready() -> void:
	AudioManager.start_menu_music()
	_stars_box.add_child(BoardPaint.star_row([str(SaveManager.total_stars()), BoardPaint.STAR], 60, true))
	_set_hint(["Earn", BoardPaint.STAR, "to unlock more"])
	for category in Cosmetics.OPTIONS:
		_rows.add_child(_make_row(category))
	_refresh()

	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.daySelectScene)
	)
	BoardPaint.style($Board/Title)
	BoardPaint.paint_tree($Board/Title, 0.15)
	for i in _rows.get_child_count():
		BoardPaint.paint_tree(_rows.get_child(i), 0.25 + i * 0.12)
	BoardPaint.paint_tree(_stars_box, 0.7, false)
	BoardPaint.paint_tree(_hint_box, 0.7, false)

func _set_hint(parts: Array) -> void:
	for child in _hint_box.get_children():
		_hint_box.remove_child(child)
		child.queue_free()
	_hint_box.add_child(BoardPaint.star_row(parts, 36))
	BoardPaint.paint_tree(_hint_box, 0.0, false)

func _show_option(option: Dictionary) -> void:
	if Cosmetics.is_unlocked(option):
		_set_hint([option["name"]])
	elif option.has("endless"):
		_set_hint(["%s: %dk in endless" % [option["name"], int(option["endless"] / 1000)]])
	else:
		_set_hint(["%s: %d" % [option["name"], Cosmetics.stars_needed(option)], BoardPaint.STAR, "to unlock"])

func _make_row(category: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var name_lbl := Label.new()
	name_lbl.text = Cosmetics.CATEGORY_NAMES[category]
	name_lbl.custom_minimum_size = Vector2(250, 0)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 55)
	row.add_child(name_lbl)
	BoardPaint.style(name_lbl)

	var buttons: Array = []
	var options: Array = Cosmetics.options(category)
	for i in options.size():
		var option: Dictionary = options[i]
		var swatch := Button.new()
		swatch.custom_minimum_size = SWATCH_SIZE
		swatch.tooltip_text = option["name"]
		var unlocked := Cosmetics.is_unlocked(option)
		if unlocked:
			swatch.pressed.connect(_select.bind(category, i))
		else:
			swatch.disabled = true
			swatch.add_child(_lock_badge(option))
		swatch.mouse_entered.connect(_show_option.bind(option))
		ButtonFx.setup(swatch)
		row.add_child(swatch)
		buttons.append(swatch)
	_swatches[category] = buttons
	return row

# "12 + star" for star unlocks, "20k endless" for score unlocks
func _lock_badge(option: Dictionary) -> Control:
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ButtonFx.outline_label(lbl, 38, 6)
	box.add_child(lbl)
	if option.has("endless"):
		lbl.text = "%dk\nendless" % int(option["endless"] / 1000)
		lbl.add_theme_font_size_override("font_size", 24)
	else:
		lbl.text = str(Cosmetics.stars_needed(option))
		var star := StarIcon.new()
		star.custom_minimum_size = Vector2(30, 30)
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(star)
	return box

func _select(category: String, index: int) -> void:
	SaveManager.cosmetics[category] = index
	SaveManager.save_game()
	_show_option(Cosmetics.options(category)[index])
	_refresh()

func _refresh() -> void:
	for category in _swatches:
		var chosen: Dictionary = Cosmetics.selected(category)
		var options: Array = Cosmetics.options(category)
		for i in options.size():
			_style_swatch(_swatches[category][i], options[i], options[i] == chosen)

func _style_swatch(swatch: Button, option: Dictionary, is_selected: bool) -> void:
	var unlocked := Cosmetics.is_unlocked(option)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = option["color"] if unlocked else Color(0.45, 0.4, 0.36)
		if state == "hover":
			box.bg_color = box.bg_color.lightened(0.1)
		elif state == "focus":
			box.draw_center = false
		box.set_corner_radius_all(20)
		box.set_border_width_all(9 if is_selected else 4)
		box.border_color = SELECTED_BORDER if is_selected else NORMAL_BORDER
		swatch.add_theme_stylebox_override(state, box)
	swatch.add_theme_color_override("font_disabled_color", Color(1.0, 0.95, 0.85))
	if option.has("label") and unlocked:
		swatch.text = option["label"]
		swatch.add_theme_font_size_override("font_size", 32)
		swatch.add_theme_constant_override("outline_size", 6)
		swatch.add_theme_color_override("font_outline_color", Color.BLACK)
