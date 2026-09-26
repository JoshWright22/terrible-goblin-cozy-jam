extends Node

# Endless mode: starts plain, then every so often adds a campaign twist and makes customers a bit less patient

const FIRST_TWIST_TIME := 40.0
const TWIST_INTERVAL := 45.0
const PATIENCE_STEP := 0.94
const MIN_PATIENCE := 0.6

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

func _ready() -> void:
	_queue = TWISTS.duplicate()
	_queue.shuffle()
	_queue.push_front(FIRST_TWIST)
	_layer = CanvasLayer.new()
	_layer.layer = 11
	add_child(_layer)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.game_over:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = TWIST_INTERVAL
	_step_up()

func _step_up() -> void:
	var twists := GameManager.twists()
	twists.patience_scale = maxf(MIN_PATIENCE, twists.patience_scale * PATIENCE_STEP)
	if _queue.is_empty():
		_announce("Getting Busy", "Customers are losing patience")
		return
	var twist: Dictionary = _queue.pop_front()
	twists.set(twist["key"], twist["value"])
	_announce(twist["name"], twist["text"])

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
