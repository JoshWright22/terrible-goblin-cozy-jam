extends Node2D

# Summer calendar: pick an unlocked day, or endless once it's open

const TILE_SIZE := Vector2(180, 160)
const OPEN_COLOR := Color(0.93, 0.6, 0.35)
const DONE_COLOR := Color(0.55, 0.75, 0.4)

@onready var _grid: GridContainer = $Board/DayGrid
@onready var _stars_lbl: Label = $Board/StarsLabel
@onready var _endless_btn: Button = $Board/EndlessButton
@onready var _back_btn: TextureButton = $BackButton
@onready var _style_btn: Button = $Board/StyleButton

func _ready() -> void:
	AudioManager.start_menu_music()
	for day_number in range(1, GameManager.DAY_COUNT + 1):
		_grid.add_child(_make_tile(day_number))

	_stars_lbl.text = "%d / %d stars" % [SaveManager.total_stars(), GameManager.DAY_COUNT * 3]
	ButtonFx.style_text_button(_endless_btn, Color(0.45, 0.62, 0.85), 50)
	if GameManager.endless_unlocked():
		_endless_btn.text = "Endless  (best %d)" % SaveManager.endless_best
	else:
		_endless_btn.text = "Endless: finish summer to unlock"
		_endless_btn.disabled = true
	ButtonFx.setup(_endless_btn)
	_endless_btn.pressed.connect(func(): _go(GameManager.start_endless))

	ButtonFx.style_text_button(_style_btn, Color(0.85, 0.5, 0.65), 50)
	ButtonFx.setup(_style_btn)
	_style_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.styleScene)
	)
	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
	)
	for lbl in [$Board/Title, $Board/StarsLabel]:
		BoardPaint.style(lbl)
		BoardPaint.paint_on(lbl, 0.2)

func _make_tile(day_number: int) -> Button:
	var unlocked := day_number <= SaveManager.unlocked_day
	var stars: int = SaveManager.day_stars.get(day_number, 0)

	var tile := Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.disabled = not unlocked
	ButtonFx.style_text_button(tile, DONE_COLOR if stars > 0 else OPEN_COLOR, 70)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(box)

	var number := Label.new()
	number.text = str(day_number) if unlocked else "?"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ButtonFx.outline_label(number, 75)
	box.add_child(number)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	for i in 3:
		var star := StarIcon.new()
		star.custom_minimum_size = Vector2(36, 36)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.filled = i < stars
		row.add_child(star)
	row.visible = unlocked

	if unlocked:
		tile.tooltip_text = GameManager.load_day(day_number).title
		ButtonFx.setup(tile)
		tile.pressed.connect(func(): _go(GameManager.start_day.bind(day_number)))
	return tile

func _go(start: Callable) -> void:
	AudioManager.stop_menu_music(start)
