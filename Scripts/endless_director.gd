extends Node

# Unlimited survival: score milestones offer upgrades while time adds pressure and twists.

const FIRST_TWIST_TIME := 40.0
const TWIST_INTERVAL := 45.0
const PATIENCE_STEP := 0.94
const MIN_PATIENCE := 0.6
const SCORE_STEP := 2500
const STATUS_CENTER_X := 585.0   # middle of the customer window, same spot as the day board
const DAILY_BUFFS := Vector2i(1, 3)    # the seed picks how many of each
const DAILY_DEBUFFS := Vector2i(1, 4)
const UPGRADES := [
	{"id": "tips", "name": "Tip Jar", "text": "+20% base score\non every smoothie"},
	{"id": "patience", "name": "Friendly Service", "text": "+15% base patience\nfor new customers"},
	{"id": "capacity", "name": "Bigger Reserve", "text": "+15 maximum health\nand restore 15 health"},
	{"id": "recovery", "name": "Feel Good Blend", "text": "+2 health restored\nper earned star"},
	{"id": "belt", "name": "Easy Conveyor", "text": "Belt moves 10% slower\nwithout slowing deliveries"},
	{"id": "refresh", "name": "Fresh Start", "text": "Restore half your\nmaximum health now"},
]

# Angry reorders always come first, the rest are shuffled
const FIRST_TWIST := {"key": "angry_reorder", "value": true, "name": "Fickle Customers", "text": "Angry customers change their order"}
const TWISTS := [
	{"key": "rush_orders", "value": true, "name": "Rush Hour", "text": "Some customers are in a hurry"},
	{"key": "frozen_chance", "value": 0.25, "name": "Brain Freeze", "text": "Frozen fruit won't rotate"},
	{"key": "allergy_orders", "value": true, "name": "Allergies", "text": "Watch for fruit marked NO!"},
	{"key": "double_orders", "value": true, "name": "Seconds", "text": "Some customers want two smoothies"},
	{"key": "mystery_orders", "value": true, "name": "Mystery Orders", "text": "One fruit per order is a secret"},
	{"key": "heatwave", "value": true, "name": "Heatwave", "text": "Fruit melts if it sits on the belt"},
	{"key": "overheat", "value": true, "name": "Hot Blenders", "text": "Blend too fast and they overheat"},
	{"key": "belt_stops", "value": true, "name": "Belt Hiccups", "text": "The conveyor stalls now and then"},
	{"key": "shifty_fruit", "value": true, "name": "Shifty Fruit", "text": "Loose fruit keeps changing"},
	{"key": "fading_orders", "value": true, "name": "Short Memory", "text": "Orders fade, hover to peek"},
	{"key": "min_accuracy", "value": 60.0, "name": "Food Critics", "text": "Sloppy smoothies don't count"},
]

var _queue: Array = []
var _timer: float = FIRST_TWIST_TIME
var _layer: CanvasLayer
var _next_score: int = SCORE_STEP
var _choosing: bool = false
var _offers: Array = []
var _choice_screen: Control
var _status: Label
var _level_lbl: Label
var _time_lbl: Label
var _run_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The daily seed fixes the twist order, upgrade offers and belt fruit for everyone that day
	if GameManager.daily_run:
		seed(GameManager.daily_seed())
	_queue = TWISTS.duplicate()
	_queue.shuffle()
	_queue.push_front(FIRST_TWIST)
	_layer = CanvasLayer.new()
	_layer.layer = 11
	add_child(_layer)
	_build_status_board()
	if GameManager.daily_run:
		_start_daily()
	_update_status()

# Daily Slush opens with two campaign twists as debuffs and two free upgrades as buffs
func _start_daily() -> void:
	var twists := GameManager.twists()
	var debuffs: Array = []
	for i in randi_range(DAILY_DEBUFFS.x, DAILY_DEBUFFS.y):
		var twist: Dictionary = _queue.pop_back()
		twists.set(twist["key"], twist["value"])
		debuffs.append(twist["name"])
	var buffs: Array = UPGRADES.filter(func(upgrade): return upgrade["id"] != "refresh")
	buffs.shuffle()
	buffs = buffs.slice(0, randi_range(DAILY_BUFFS.x, DAILY_BUFFS.y))
	for buff in buffs:
		_apply_upgrade(buff["id"])
	_announce("Daily Slush", "Buffs: %s\nDebuffs: %s" % [
		", ".join(buffs.map(func(buff): return buff["name"])), ", ".join(debuffs)])

# Same cream board as the campaign's day HUD
func _build_status_board() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Centered over the customer window; the text changes width, so re-center on resize
	panel.resized.connect(func(): panel.position = Vector2(STATUS_CENTER_X - panel.size.x / 2.0, 8))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.99, 0.95, 0.82, 0.92)
	box.border_color = Color(0.24, 0.13, 0.05)
	box.set_border_width_all(5)
	box.set_corner_radius_all(26)
	box.content_margin_left = 22.0
	box.content_margin_right = 22.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", box)
	_layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	_level_lbl = _status_label(row, 52)
	_time_lbl = _status_label(row, 52)
	_time_lbl.custom_minimum_size.x = 110
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status = _status_label(row, 40)

func _status_label(row: HBoxContainer, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.add_theme_color_override("font_color", Color(0.36, 0.2, 0.08))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	return lbl

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.game_over:
		return
	_update_status()
	# Avoid interrupting a held piece. A score jump can earn several choices;
	# each is offered once, and time does not advance while choosing.
	if GameManager.score >= _next_score and not GameManager.fruit_held and not GameManager.hold:
		_offer_upgrades()
		return
	_run_time += delta
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = TWIST_INTERVAL
	_step_up()

func _step_up() -> void:
	var twists := GameManager.twists()
	GameManager.rogue_pressure += 0.06
	twists.patience_scale = maxf(MIN_PATIENCE, twists.patience_scale * PATIENCE_STEP)
	if _queue.is_empty():
		_announce("Getting Busy", "Health drains faster and mistakes cost more")
		return
	var twist: Dictionary = _queue.pop_front()
	twists.set(twist["key"], twist["value"])
	_announce(twist["name"], twist["text"])

func _update_status() -> void:
	_level_lbl.text = "Lv %d" % GameManager.rogue_level
	_time_lbl.text = "%d:%02d" % [int(_run_time) / 60, int(_run_time) % 60]
	_status.text = "Next upgrade %d" % _next_score

func _offer_upgrades() -> void:
	if _choosing or GameManager.game_over:
		return
	_choosing = true
	GameManager.paused = true
	get_tree().paused = true
	_offers = UPGRADES.filter(func(upgrade): return upgrade["id"] != "belt" or GameManager.rogue_belt_mult > 0.51)
	_offers.shuffle()
	_offers = _offers.slice(0, 3)
	_choice_screen = Control.new()
	_layer.add_child(_choice_screen)
	_choice_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.65)
	_choice_screen.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_choice_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := VBoxContainer.new()
	board.add_theme_constant_override("separation", 28)
	center.add_child(board)
	var title := Label.new()
	title.text = "Level %d: choose an upgrade" % (GameManager.rogue_level + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	board.add_child(title)
	BoardPaint.style(title, true, false)
	var subtitle := Label.new()
	subtitle.text = "Keep it for this run. The shop is paused while you choose."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 36)
	board.add_child(subtitle)
	BoardPaint.style(subtitle, false, false)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 24)
	board.add_child(cards)
	for index in _offers.size():
		var offer: Dictionary = _offers[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(440, 280)
		card.text = "%s\n\n%s" % [offer["name"], offer["text"]]
		ButtonFx.style_text_button(card, Color(0.7, 0.48, 0.3), 36)
		cards.add_child(card)
		ButtonFx.setup(card)
		card.pressed.connect(_choose_upgrade.bind(index))
	BoardPaint.paint_tree(board, 0.1)
	cards.get_child(0).grab_focus()

func _choose_upgrade(index: int) -> void:
	if not _choosing or index < 0 or index >= _offers.size() or GameManager.game_over:
		return
	_choosing = false
	_apply_upgrade(_offers[index]["id"])
	GameManager.rogue_level += 1
	_next_score += SCORE_STEP * GameManager.rogue_level
	_offers.clear()
	_choice_screen.queue_free()
	get_tree().paused = false
	GameManager.paused = false
	_update_status()

func _apply_upgrade(id: String) -> void:
	var control = get_parent()
	match id:
		"tips": GameManager.rogue_score_mult += 0.2
		"patience": GameManager.rogue_patience_mult += 0.15
		"capacity":
			control.MAX_TIME += 15.0
			control.REMAIN_TIME += 15.0
		"recovery": control.ADD_TIME += 2.0
		"belt": GameManager.rogue_belt_mult = maxf(0.5, GameManager.rogue_belt_mult - 0.1)
		"refresh": control.REMAIN_TIME = minf(control.MAX_TIME, control.REMAIN_TIME + control.MAX_TIME * 0.5)
	control.healthBar.max_value = control.MAX_TIME
	control.healthBar.value = control.REMAIN_TIME

func _announce(title: String, text: String) -> void:
	AudioManager.play_pause_open()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(box)

	var head := Label.new()
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ButtonFx.outline_label(head, 90, 14)
	head.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
	box.add_child(head)

	var sub := Label.new()
	sub.text = text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ButtonFx.outline_label(sub, 50, 10)
	box.add_child(sub)

	var view := get_viewport().get_visible_rect().size
	box.size = Vector2(view.x, 0.0)
	box.position = Vector2(0.0, view.y * 0.36)
	box.pivot_offset = Vector2(view.x / 2.0, 60.0)
	box.scale = Vector2(0.6, 0.6)
	box.modulate.a = 0.0

	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(box, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	tw.finished.connect(box.queue_free)
