extends Node2D

# Style unlocks: pick blender, wall, conveyor, transition and paint colors earned with stars

const SWATCH_SIZE := Vector2(96, 96)
const SELECTED_BORDER := Color(1.0, 0.84, 0.3)
const NORMAL_BORDER := Color(0.24, 0.13, 0.05)

@onready var _rows: VBoxContainer = $Board/Rows
@onready var _stars_lbl: Label = $Board/StarsLabel
@onready var _hint_lbl: Label = $Board/HintLabel
@onready var _back_btn: TextureButton = $BackButton

var _swatches: Dictionary = {}   # category -> Array[Button]

func _ready() -> void:
	AudioManager.start_menu_music()
	_stars_lbl.text = "%d stars" % SaveManager.total_stars()
	_hint_lbl.text = "Earn stars to unlock more"
	for category in Cosmetics.OPTIONS:
		_rows.add_child(_make_row(category))
	_refresh()

	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.daySelectScene)
	)
	for lbl in [$Board/Title, _stars_lbl, _hint_lbl]:
		BoardPaint.style(lbl)
		BoardPaint.paint_on(lbl, 0.2)

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
			swatch.mouse_entered.connect(func(): _hint_lbl.text = option["name"])
		else:
			swatch.disabled = true
			swatch.add_child(_lock_badge(option))
			swatch.mouse_entered.connect(func(): _hint_lbl.text = "%s: unlock at %s" % [option["name"], Cosmetics.requirement_text(option)])
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
	ButtonFx.outline_label(lbl, 38, 6)
	box.add_child(lbl)
	if option.has("endless"):
		lbl.text = "%dk\nendless" % int(option["endless"] / 1000)
		lbl.add_theme_font_size_override("font_size", 28)
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
	_hint_lbl.text = Cosmetics.options(category)[index]["name"]
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
