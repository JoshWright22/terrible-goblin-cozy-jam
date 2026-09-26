extends CanvasLayer

# Day 1 hands-on tutorial: one painted step at a time on a little wooden sign,
# with an inked arrow pointing where to look. Each step waits for the player to do it.
# The sign sits over the bottom right blender, clear of the order bubbles, and fades
# while a piece is dragged over it.

const SIGN_TIP_TIME := 6.0
const SIGN_FADED_ALPHA := 0.25

@onready var _step_lbl: Label = $Sign/StepLabel
@onready var _count_lbl: Label = $Sign/CountLabel
@onready var _skip_btn: Button = $Sign/SkipButton
@onready var _arrow: Node2D = $Arrow

var _steps: Array[Dictionary] = []
var _index: int = -1
var _step_time: float = 0.0
var _arrow_target: Vector2 = Vector2.ZERO
var _time: float = 0.0

func _ready() -> void:
	var touch := OS.has_feature("mobile")
	_steps = [
		{"text": "Grab a fruit off the conveyor belt", "target": _belt_point, "done": func(): return GameManager.fruit_held},
		{"text": "Drop it into a blender", "target": _blender_point, "done": _any_piece_in_blender},
		{"text": ("Tap with a second finger while dragging to turn a piece" if touch else "Right click while holding a piece to turn it"),
			"target": _blender_point, "done": func(): return GameManager.rotations > 0, "skip_after": 14.0},
		{"text": "Fill it to match the order, then press Blend", "target": _blend_button_point, "done": _smoothie_ready},
		{"text": "Drag the smoothie onto the customer", "target": _customer_point, "done": func(): return GameManager.smoothies_served > 0},
		{"text": "Happy customers fill the bar on the left. Reach the star goals before the shop closes!", "target": _health_point,
			"done": func(): return _step_time > SIGN_TIP_TIME},
	]
	visible = false
	ButtonFx.style_text_button(_skip_btn, Palette.MUTED, 36)
	ButtonFx.setup(_skip_btn)
	_skip_btn.pressed.connect(_finish)

func _process(delta: float) -> void:
	_time += delta
	# Wait for the day intro card to close
	if _index < 0:
		if not GameManager.paused:
			visible = true
			_next_step()
		return
	if GameManager.paused:
		return

	_step_time += delta
	var over_sign: bool = GameManager.fruit_held and $Sign.get_global_rect().grow(40.0).has_point(get_viewport().get_mouse_position())
	$Sign.modulate.a = move_toward($Sign.modulate.a, SIGN_FADED_ALPHA if over_sign else 1.0, delta * 5.0)
	var step := _steps[_index]
	_arrow_target = step["target"].call()
	_arrow.position = _arrow_target + Vector2(0, -20.0 - absf(sin(_time * 4.0)) * 22.0)

	if step["done"].call() or _step_time > step.get("skip_after", INF):
		_next_step()

func _next_step() -> void:
	_index += 1
	_step_time = 0.0
	if _index >= _steps.size():
		_finish()
		return
	AudioManager.play_health_gain()
	_count_lbl.text = "%d / %d" % [_index + 1, _steps.size()]
	_step_lbl.text = _steps[_index]["text"]
	BoardPaint.style(_step_lbl)
	BoardPaint.style(_count_lbl, true)
	BoardPaint.paint_on(_step_lbl, 0.05)
	_arrow.visible = true

func _finish() -> void:
	GameManager.tutorial_active = false
	var tw := create_tween()
	tw.tween_property($Sign, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(_arrow, "modulate:a", 0.0, 0.3)
	tw.finished.connect(queue_free)
	set_process(false)

# --- Where the arrow points ---

func _game_loop() -> Node:
	var control := get_tree().get_first_node_in_group("orderControl")
	return control.get_parent() if control else null

func _first_grid() -> Node2D:
	var loop := _game_loop()
	return loop.get_node_or_null("GridScene/Blender/Grid") if loop else null

func _belt_point() -> Vector2:
	return Vector2(1160, 960)

func _blender_point() -> Vector2:
	var grid := _first_grid()
	if grid:
		return grid.get_node("GridAnchor").global_position + Vector2(0, -60)
	return Vector2(1200, 250)

func _blend_button_point() -> Vector2:
	var grid := _first_grid()
	if grid and grid.blend_button:
		return grid.blend_button.global_position + Vector2(grid.blend_button.size.x / 2.0, 0)
	return Vector2(1200, 400)

func _customer_point() -> Vector2:
	return Vector2(580, 190)

func _health_point() -> Vector2:
	return Vector2(56, 90)

# --- Step checks ---

func _any_piece_in_blender() -> bool:
	for piece in get_tree().get_nodes_in_group("fruit_piece"):
		if piece.is_locked:
			return true
	return false

func _smoothie_ready() -> bool:
	var loop := _game_loop()
	return loop != null and loop.find_child("SmoothieOverlay", true, false) != null
