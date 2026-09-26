extends Control

# Short card shown before days 2+ (day 1 uses the full tutorial)

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: Sprite2D = $BgSprite
@onready var _day_lbl: Label = $DayLabel
@onready var _title_lbl: Label = $TitleLabel
@onready var _intro_lbl: Label = $IntroLabel
@onready var _goal_box: HBoxContainer = $GoalBox
@onready var _fruit_reveal: HBoxContainer = $FruitReveal

const REVEAL_SHAPES := ["1x1", "2x1", "3x2_T"]
const REVEAL_HEIGHT := 72.0
const REVEAL_SHIFT := 60.0
const REVEAL_GAP := 30          # between the name, the order icon, "=" and each piece
const MIN_INTRO_SIZE := 34
const CELL_PIXELS := 120
const PIECE_CELL := 52.0         # on-screen size of one piece cell, the same for every piece   # fruit piece art is drawn at 120 px per cell
@onready var _start_btn: TextureButton = $StartButton

var _closing: bool = false

func _ready() -> void:
	GameManager.paused = true
	var day: DayConfig = GameManager.current_day
	_day_lbl.text = "DAY %d" % day.day_number
	_title_lbl.text = day.title
	_intro_lbl.text = day.intro_text
	if day.day_number > 1 and day.blender_count > GameManager.load_day(day.day_number - 1).blender_count:
		_intro_lbl.text += "\nA new blender is open!"
	var new_fruits := _new_fruits(day)
	if not new_fruits.is_empty():
		# Make room under the intro for the new fruit: everything below shifts down
		for item in [_fruit_reveal, _goal_box]:
			item.position.y += REVEAL_SHIFT
		_start_btn.position.y += REVEAL_SHIFT / 3.0
		_fruit_reveal.add_theme_constant_override("separation", REVEAL_GAP)
		_intro_lbl.offset_bottom = _fruit_reveal.offset_top
		for fruit in new_fruits:
			_show_new_fruit(fruit)
	_fit_intro()
	var goals := BoardPaint.star_row([BoardPaint.STAR, "%d   " % day.star_scores[0], BoardPaint.STAR, "%d   " % day.star_scores[1],
		BoardPaint.STAR, str(day.star_scores[2])], 52, true)
	var hints := day.star_hints()
	for star in goals.get_children().filter(func(child): return child is StarIcon):
		star.tooltip_text = hints.pop_front()
		star.mouse_filter = Control.MOUSE_FILTER_PASS
	_goal_box.add_child(goals)
	BoardPaint.apply(self, true, 0.25)
	# Keep multi-line story text level instead of using the board's random tilt.
	_intro_lbl.rotation = 0.0
	BoardPaint.paint_tree(_fruit_reveal, 0.55, false)
	BoardPaint.paint_tree(_goal_box, 0.7, false)
	BoardPaint.paint_tree(_start_btn, 0.85, false)
	ButtonFx.setup(_start_btn)
	_start_btn.pressed.connect(_close)
	_play_in()

# Story text comes from a file anyone can edit, so shrink it until it fits its space
func _fit_intro() -> void:
	var font := _intro_lbl.get_theme_font("font")
	var font_size := _intro_lbl.get_theme_font_size("font_size")
	var room := _intro_lbl.offset_bottom - _intro_lbl.offset_top
	var width := _intro_lbl.offset_right - _intro_lbl.offset_left
	while font_size > MIN_INTRO_SIZE and font.get_multiline_string_size(_intro_lbl.text,
			HORIZONTAL_ALIGNMENT_CENTER, width, font_size).y > room:
		font_size -= 2
	_intro_lbl.add_theme_font_size_override("font_size", font_size)

# Fruits on today's belt that weren't on yesterday's. Day 1 has the tutorial instead
func _new_fruits(day: DayConfig) -> Array:
	if day.day_number <= 1:
		return []
	var today := _fruits_of(day)
	var yesterday := _fruits_of(GameManager.load_day(day.day_number - 1))
	return today.filter(func(fruit): return fruit not in yesterday)

func _fruits_of(day: DayConfig) -> Array:
	return Array(day.fruits) if not day.fruits.is_empty() else range(FruitData.FruitType.size())

# "Mango  [order icon]  =  [a few mango pieces]" so the player knows both looks before it arrives
func _show_new_fruit(fruit: int) -> void:
	var fruit_name: String = FruitData.FruitType.keys()[fruit].to_lower()
	var title := Label.new()
	title.text = "New: %s" % fruit_name.capitalize()
	title.add_theme_font_size_override("font_size", 52)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fruit_reveal.add_child(title)
	BoardPaint.style(title, true, false)

	_fruit_reveal.add_child(_picture(_trimmed(load("res://Assets/sprites/fruitSprites/%sSprite.PNG" % fruit_name))))
	var equals := Label.new()
	equals.text = "="
	equals.add_theme_font_size_override("font_size", 52)
	equals.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fruit_reveal.add_child(equals)
	BoardPaint.style(equals, false, false)

	for shape in REVEAL_SHAPES:
		var piece: FruitData = load("res://Resource/%s_%s.tres" % [fruit_name, shape])
		var art := _piece_art(piece)
		_fruit_reveal.add_child(_picture(art, art.get_size() * PIECE_CELL / CELL_PIXELS))

# Just the cells the piece fills, not the empty canvas around a small piece
func _piece_art(piece: FruitData) -> Texture2D:
	var cells := Vector2.ZERO
	for cell in piece.layout:
		cells = cells.max(cell + Vector2.ONE)
	return _trimmed(piece.texture, Rect2(Vector2.ZERO, (cells * CELL_PIXELS).min(piece.texture.get_size())))

# Crops to the pixels actually drawn, so every picture in the row is spaced by its art, not its padding
func _trimmed(texture: Texture2D, area: Rect2 = Rect2()) -> Texture2D:
	if area.size == Vector2.ZERO:
		area = Rect2(Vector2.ZERO, texture.get_size())
	var image := texture.get_image()
	if image:
		if image.is_compressed():
			image.decompress()
		var used := image.get_region(Rect2i(area)).get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			area = Rect2(area.position + Vector2(used.position), Vector2(used.size))
	var art := AtlasTexture.new()
	art.atlas = texture
	art.region = area
	return art

func _picture(texture: Texture2D, fixed_size := Vector2.ZERO) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var size := texture.get_size()
	picture.custom_minimum_size = fixed_size if fixed_size != Vector2.ZERO else Vector2(REVEAL_HEIGHT * size.x / size.y, REVEAL_HEIGHT)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture

func _play_in() -> void:
	var base := _panel.scale
	_panel.scale = Vector2.ZERO
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_panel, "scale", base, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	if _closing:
		return
	_closing = true
	GameManager.paused = false
	# The board slides off while the dimmer just fades where it is
	var slide := -get_viewport_rect().size.x - 50.0
	var tw := create_tween().set_parallel()
	for child in get_children():
		if child == _dimmer:
			tw.tween_property(child, "modulate:a", 0.0, 0.3)
		else:
			tw.tween_property(child, "position:x", child.position.x + slide, 0.22) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		var parent = get_parent()
		if parent is CanvasLayer:
			parent.queue_free()
		else:
			queue_free()
	)
