extends Node2D

const MAX_PAGE := 4
const SLIDE_DIST := 380.0

@onready var _pages: Array[Node] = [$pg1, $pg2, $pg3, $pg4]
@onready var _right_label: Label = $Label
@onready var _left_label: Label  = $Label2

var _page: int = 1
var _transitioning: bool = false
var _right_origin_x: float
var _left_origin_x: float
var _right_pulse: Tween = null
var _left_pulse: Tween = null

var _float_nodes: Array = []
var _float_time: float = 0.0
var _origins_initialized: bool = false

func _ready() -> void:
	_pages[0].visible = true

	_right_origin_x = _right_label.position.x
	_left_origin_x  = _left_label.position.x

	$Label/Button2.mouse_entered.connect(_on_right_hover)
	$Label/Button2.mouse_exited.connect(_on_right_unhover)
	$Label2/button.mouse_entered.connect(_on_left_hover)
	$Label2/button.mouse_exited.connect(_on_left_unhover)

	_register_float_nodes()
	_update_nav()
	_play_popup()

	# Wait one frame so all Container nodes finish their deferred layout
	# before we record origin_y for each float node.
	await get_tree().process_frame
	for p in _float_nodes:
		p["origin_y"] = p["node"].position.y
	_origins_initialized = true

# ---------- Popup ----------

func _play_popup() -> void:
	modulate.a = 0.0
	position.y = 50.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", 0.0, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---------- Floating images ----------

func _register_float_nodes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for page in _pages:
		if page == $pg4:
			continue  # pg4 handles its own drag animation
		for child in page.find_children("*", "TextureRect", true, false):
			# pg3's blender and button sprites stay static; container children float individually
			if page == $pg3 and child.get_parent() == page:
				continue
			_float_nodes.append({
				"node": child,
				"origin_y": child.position.y,
				"amp": rng.randf_range(5.0, 11.0),
				"period": rng.randf_range(2.6, 4.5),
				"phase": rng.randf_range(0.0, TAU),
			})

func _process(delta: float) -> void:
	if not _origins_initialized:
		return
	_float_time += delta
	for p in _float_nodes:
		var node: Control = p["node"]
		node.position.y = p["origin_y"] + sin(_float_time / p["period"] * TAU + p["phase"]) * p["amp"]

# ---------- Input ----------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_go_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_go_left()
		get_viewport().set_input_as_handled()

func _go_right() -> void:
	if _transitioning:
		return
	if _page >= MAX_PAGE:
		_close()
	else:
		_transition_to(_page + 1)

func _go_left() -> void:
	if _transitioning or _page <= 1:
		return
	_transition_to(_page - 1)

func _close() -> void:
	GameManager.paused = false
	var slide_w := get_viewport_rect().size.x + 50.0
	var tw := create_tween()
	tw.tween_property(self, "position:x", -slide_w, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		var parent = get_parent()
		if parent is CanvasLayer:
			parent.queue_free()
		else:
			queue_free()
	)

# ---------- Nav state ----------

func _update_nav(restart_pulse: bool = true) -> void:
	_left_label.visible = (_page > 1)
	_right_label.text = "Start!" if _page >= MAX_PAGE else "→"
	call_deferred("_sync_right_btn")
	if restart_pulse:
		_restart_pulses()

func _sync_right_btn() -> void:
	($Label/Button2 as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# ---------- Page transition (slide + bounce) ----------

func _transition_to(new_page: int) -> void:
	_transitioning = true
	var direction: int = sign(new_page - _page)
	var old_node: Control = _pages[_page - 1] as Control

	# Pause arrow pulses for the duration
	if _right_pulse: _right_pulse.kill()
	if _left_pulse:  _left_pulse.kill()

	var slide_w := get_viewport_rect().size.x + 50.0

	# Phase 1: slide the whole scene fully off screen
	var tw_out := create_tween()
	tw_out.tween_property(self, "position:x", -slide_w * direction, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw_out.finished

	# Swap content while off-screen
	old_node.visible = false
	_page = new_page
	_update_nav(false)
	_pages[_page - 1].visible = true
	position.x = slide_w * direction

	# Phase 2: bounce the whole scene back in from the other side
	var tw_in := create_tween()
	tw_in.tween_property(self, "position:x", 0.0, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.finished.connect(func():
		_transitioning = false
		_restart_pulses()
	)

# ---------- Arrow pulses ----------

func _restart_pulses() -> void:
	if _right_pulse:
		_right_pulse.kill()
	_right_label.position.x = _right_origin_x
	_right_pulse = _right_label.create_tween().set_loops()
	_right_pulse.tween_property(_right_label, "position:x", _right_origin_x + 7.0, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_right_pulse.tween_property(_right_label, "position:x", _right_origin_x, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _left_pulse:
		_left_pulse.kill()
	_left_label.position.x = _left_origin_x
	if _left_label.visible:
		_left_pulse = _left_label.create_tween().set_loops()
		_left_pulse.tween_property(_left_label, "position:x", _left_origin_x - 7.0, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_left_pulse.tween_property(_left_label, "position:x", _left_origin_x, 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------- Arrow hover ----------

func _on_right_hover() -> void:
	AudioManager.play_button_hover()
	if _right_pulse:
		_right_pulse.kill()
	_right_label.create_tween() \
		.tween_property(_right_label, "modulate", Color(1.0, 0.9, 0.2, 1.0), 0.1)

func _on_right_unhover() -> void:
	_right_label.create_tween() \
		.tween_property(_right_label, "modulate", Color.WHITE, 0.15)
	_restart_pulses()

func _on_left_hover() -> void:
	if not _left_label.visible:
		return
	AudioManager.play_button_hover()
	if _left_pulse:
		_left_pulse.kill()
	_left_label.create_tween() \
		.tween_property(_left_label, "modulate", Color(1.0, 0.9, 0.2, 1.0), 0.1)

func _on_left_unhover() -> void:
	_left_label.create_tween() \
		.tween_property(_left_label, "modulate", Color.WHITE, 0.15)
	_restart_pulses()

# ---------- Button callbacks ----------

func _on_button_2_button_down() -> void:
	AudioManager.play_button_click()
	_go_right()

func _on_button_button_down() -> void:
	AudioManager.play_button_click()
	_go_left()
