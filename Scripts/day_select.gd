extends Node2D

# Campaign calendar: flip between campaigns, pick an unlocked day, or endless once it's open

const TILE_SIZE := Vector2(180, 160)
const OPEN_COLOR := Color(0.93, 0.6, 0.35)
const DONE_COLOR := Color(0.55, 0.75, 0.4)

@onready var _title: Label = $Board/Title
@onready var _grid: GridContainer = $Board/DayGrid
@onready var _locked_lbl: Label = $Board/LockedLabel
@onready var _locked_stars: VBoxContainer = $Board/LockedStars
@onready var _stars_box: HBoxContainer = $Board/StarsBox
@onready var _endless_btn: Button = $Board/EndlessButton
@onready var _back_btn: TextureButton = $BackButton
@onready var _style_btn: Button = $Board/StyleButton
@onready var _prev_btn: Button = $Board/PrevButton
@onready var _next_btn: Button = $Board/NextButton

func _ready() -> void:
	AudioManager.start_menu_music()

	ButtonFx.style_text_button(_endless_btn, Color(0.45, 0.62, 0.85), 50)
	if GameManager.endless_unlocked():
		_endless_btn.text = "Roguelike  (best %d)" % SaveManager.endless_best
	else:
		_endless_btn.text = "Roguelike: beat summer"
		_endless_btn.disabled = true
	ButtonFx.setup(_endless_btn)
	_endless_btn.pressed.connect(func(): _go(GameManager.start_endless))

	ButtonFx.style_text_button(_style_btn, Color(0.85, 0.5, 0.65), 50)
	ButtonFx.setup(_style_btn)
	_style_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.styleScene)
	)
	for arrow in [_prev_btn, _next_btn]:
		ButtonFx.style_text_button(arrow, Color(0.93, 0.6, 0.35), 60)
		ButtonFx.setup(arrow)
	_prev_btn.pressed.connect(_flip.bind(-1))
	_next_btn.pressed.connect(_flip.bind(1))

	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
	)
	BoardPaint.style(_locked_lbl)
	_show_campaign()
	for item in [_prev_btn, _next_btn, _style_btn, _endless_btn]:
		BoardPaint.paint_tree(item, 0.5, false)

func _flip(direction: int) -> void:
	var index := GameManager.campaigns.find(GameManager.current_campaign)
	index = wrapi(index + direction, 0, GameManager.campaigns.size())
	GameManager.current_campaign = GameManager.campaigns[index]
	AudioManager.play_transition()
	_show_campaign()

func _show_campaign() -> void:
	var campaign := GameManager.current_campaign
	_title.text = campaign.title
	_title.tooltip_text = "Campaign: complete days and earn stars to progress"
	for box in [_grid, _stars_box, _locked_stars]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()

	var unlocked := GameManager.campaign_unlocked(campaign)
	_grid.visible = unlocked
	_locked_lbl.visible = not unlocked
	_locked_stars.visible = not unlocked
	var stars_row: HBoxContainer
	if unlocked:
		for day_number in range(1, campaign.day_count() + 1):
			var tile := _make_tile(campaign, day_number)
			_grid.add_child(tile)
			# Tiles paint on in reading order, one swish per row
			var index := day_number - 1
			BoardPaint.paint_tree(tile, 0.25 + index * 0.035, index % _grid.columns == 0)
		stars_row = BoardPaint.star_row(["%d / %d" % [SaveManager.campaign_stars(campaign.id), campaign.day_count() * 3], BoardPaint.STAR], 60, true)
	else:
		_locked_lbl.text = campaign.unlock_hint
		BoardPaint.paint_on(_locked_lbl, 0.1)
		var need := BoardPaint.star_row(["Earn %d" % campaign.stars_to_unlock, BoardPaint.STAR, "to open"], 70)
		var have := BoardPaint.star_row(["You have %d" % SaveManager.total_stars(), BoardPaint.STAR], 56, true)
		_locked_stars.add_child(need)
		_locked_stars.add_child(have)
		BoardPaint.paint_tree(need, 0.35)
		BoardPaint.paint_tree(have, 0.6)
		stars_row = BoardPaint.star_row(["%d" % SaveManager.total_stars(), BoardPaint.STAR], 60, true)
	stars_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	stars_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stars_box.add_child(stars_row)
	BoardPaint.paint_tree(stars_row, 0.4, false)

	var many := GameManager.campaigns.size() > 1
	_prev_btn.visible = many
	_next_btn.visible = many
	BoardPaint.style(_title)
	BoardPaint.paint_on(_title, 0.1)

func _make_tile(campaign: Campaign, day_number: int) -> Button:
	var unlocked := day_number <= SaveManager.unlocked_day(campaign.id)
	var stars: int = SaveManager.stars_for(campaign.id, day_number)

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
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		tile.tooltip_text = campaign.days[day_number - 1].title
		ButtonFx.setup(tile)
		tile.pressed.connect(func(): _go(GameManager.start_day.bind(day_number)))
	return tile

func _go(start: Callable) -> void:
	AudioManager.stop_menu_music(start)
