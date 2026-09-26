extends Node

@onready var belt: Sprite2D = $Sprite2D

@export_group("Spawning")
@export var initial_spawn_interval: float = 3.5
@export var min_spawn_interval: float = 0.8
@export var ramp_duration: float = 250.0   # seconds to reach max speed (~5-min game target)

@export_group("Belt Speed")
@export var initial_belt_speed: float = 120.0
@export var max_belt_speed: float = 280.0

@export_group("Type")
## Leave empty to allow all fruit types
@export var fruit_pool: Array[FruitData] = []

@export_group("Quality")
## Block count range — 1x1 = 1 block, 2x1 = 2, 3x2 shapes = 4-6
@export_range(1, 9) var min_blocks: int = 1
@export_range(1, 9) var max_blocks: int = 9

const SPAWN_X: float = 1300.0
const DESPAWN_X: float = -950.0   # well off the left edge of screen

var fruit_piece_packed: PackedScene = load("res://Scenes/FruitPiece.tscn")

var pieces: Array = []
var spawn_timer: float = 0.0
var _resolved_pool: Array[FruitData] = []
var _scroll_offset: float = 0.0
var _tex_width: float = 1.0
var _shader_mat: ShaderMaterial = null
var _elapsed: float = 0.0
var _current_belt_speed: float = 0.0
var _current_spawn_interval: float = 0.0
var _current_tc: float = 0.0

# RNG protection: cycle through all types before repeating
var _type_pools: Dictionary = {}   # int (FruitType) → Array[FruitData]
var _pending_types: Array[int] = []  # types not yet seen this cycle

const MELT_TIME: float = 7.0   # Heatwave: seconds a piece survives on the belt
const SHIFT_TIME: float = 2.2  # Shifty Fruit: seconds between fruit changes
const STALL_TIME: float = 2.5  # Belt Hiccups: how long the belt stops
const RUN_TIME := Vector2(8.0, 13.0)  # Belt Hiccups: running time between stalls

var _stall_timer: float = 0.0
var _stalled: bool = false
var _belt_tint: Color = Color.WHITE  # belt color while running, restored after a stall
var _shape_pools: Dictionary = {}  # shape name ("3x2_T") -> Array[FruitData], for shifty fruit

var _day: DayConfig = null

func _ready() -> void:
	_day = GameManager.current_day
	if _day:
		initial_belt_speed *= _day.belt_speed_scale
		max_belt_speed *= _day.belt_speed_scale
		initial_spawn_interval /= _day.spawn_rate_scale
		min_spawn_interval /= _day.spawn_rate_scale
		ramp_duration = _day.duration
	_build_pool()
	_stall_timer = randf_range(RUN_TIME.x, RUN_TIME.y)
	_current_belt_speed = initial_belt_speed
	_current_spawn_interval = initial_spawn_interval
	spawn_timer = 0.0
	_setup_belt()

func _setup_belt() -> void:
	if belt.texture:
		_tex_width = float(belt.texture.get_width()) * belt.scale.x

	belt.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = load("res://Shaders/belt_scroll.gdshader")
	belt.material = _shader_mat

func _build_pool() -> void:
	var base: Array[FruitData] = fruit_pool if not fruit_pool.is_empty() else _scan_all_fruit_data("res://")
	_resolved_pool.clear()
	_type_pools.clear()
	for fd in base:
		if fd == null:
			continue
		if _day and not (_day.allows_fruit(fd.fruit_name) and _day.allows_shape(fd)):
			continue
		if fd.layout.size() >= min_blocks and fd.layout.size() <= max_blocks:
			_resolved_pool.append(fd)
			if not _type_pools.has(fd.fruit_name):
				_type_pools[fd.fruit_name] = []
			(_type_pools[fd.fruit_name] as Array).append(fd)
			var shape := _shape_of(fd)
			if not _shape_pools.has(shape):
				_shape_pools[shape] = []
			(_shape_pools[shape] as Array).append(fd)
	if _resolved_pool.is_empty():
		push_warning("RandomBlockGenerator: no FruitData matches the current quality range.")
	_reset_type_cycle()

func _scan_all_fruit_data(_path: String) -> Array[FruitData]:
	# DirAccess doesn't work in HTML5 exports, so we use an explicit list.
	var paths := [
		"res://Resource/apple_1x1.tres",
		"res://Resource/apple_2x1.tres",
		"res://Resource/apple_3x1.tres",
		"res://Resource/apple_2x2_L.tres",
		"res://Resource/apple_3x2_L.tres",
		"res://Resource/apple_3x2_T.tres",
		"res://Resource/apple_3x2_IL.tres",
		"res://Resource/banana_1x1.tres",
		"res://Resource/banana_2x1.tres",
		"res://Resource/banana_3x1.tres",
		"res://Resource/banana_2x2_L.tres",
		"res://Resource/banana_3x2_L.tres",
		"res://Resource/banana_3x2_T.tres",
		"res://Resource/banana_3x2_IL.tres",
		"res://Resource/strawberry_1x1.tres",
		"res://Resource/strawberry_2x1.tres",
		"res://Resource/strawberry_3x1.tres",
		"res://Resource/strawberry_2x2_L.tres",
		"res://Resource/strawberry_3x2_L.tres",
		"res://Resource/strawberry_3x2_T.tres",
		"res://Resource/strawberry_3x2_IL.tres",
		"res://Resource/blueberry_1x1.tres",
		"res://Resource/blueberry_2x1.tres",
		"res://Resource/blueberry_3x1.tres",
		"res://Resource/blueberry_2x2_L.tres",
		"res://Resource/blueberry_3x2_L.tres",
		"res://Resource/blueberry_3x2_T.tres",
		"res://Resource/blueberry_3x2_IL.tres",
		"res://Resource/mango_1x1.tres",
		"res://Resource/mango_2x1.tres",
		"res://Resource/mango_3x1.tres",
		"res://Resource/mango_2x2_L.tres",
		"res://Resource/mango_3x2_L.tres",
		"res://Resource/mango_3x2_T.tres",
		"res://Resource/mango_3x2_IL.tres",
	]
	var result: Array[FruitData] = []
	for p in paths:
		var res = load(p)
		if res is FruitData:
			result.append(res)
	return result

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	# Ramp difficulty over time
	_elapsed += delta
	var t := clampf(_elapsed / ramp_duration, 0.0, 1.0)
	var tc := minf(pow(t, 0.75), 0.75)  # ramps to medium-hard quickly, then plateaus there
	_current_tc = tc
	_current_belt_speed = lerpf(initial_belt_speed, max_belt_speed, tc)
	_current_spawn_interval = lerpf(initial_spawn_interval, min_spawn_interval, tc)
	var twists := GameManager.twists()
	if twists.belt_stops:
		_update_stall(delta)
	if _stalled:
		_current_belt_speed = 0.0

	if _shader_mat:
		_scroll_offset += (_current_belt_speed / _tex_width) * delta
		if _scroll_offset >= 1.0:
			_scroll_offset -= 1.0
		_shader_mat.set_shader_parameter("scroll", _scroll_offset)

	var to_remove: Array = []
	for p in pieces:
		if not is_instance_valid(p.root) or not is_instance_valid(p.ctrl):
			to_remove.append(p)
			continue
		var ctrl = p.ctrl
		var root = p.root
		if ctrl.is_locked or ctrl.detached_from_conveyor:
			continue
		root.position.x -= _current_belt_speed * delta
		if root.position.x < DESPAWN_X and not ctrl.is_dragging:
			root.queue_free()
			to_remove.append(p)
		if twists.shifty_fruit and not ctrl.is_dragging:
			p.shift += delta
			if p.shift >= SHIFT_TIME:
				p.shift = 0.0
				_shift_fruit(ctrl)
		if twists.heatwave and not ctrl.is_dragging:
			p.age += delta
			# Tint toward a melty orange, then drip away
			var melt := clampf(p.age / MELT_TIME, 0.0, 1.0)
			ctrl.modulate = Color(1.0, 1.0 - melt * 0.35, 1.0 - melt * 0.6, 1.0 - maxf(0.0, melt - 0.8) * 5.0)
			if melt >= 1.0:
				root.queue_free()
				to_remove.append(p)

	for p in to_remove:
		pieces.erase(p)

	if not _stalled:
		spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_at(SPAWN_X)
		spawn_timer = _current_spawn_interval

func _reset_type_cycle() -> void:
	_pending_types.clear()
	for k in _type_pools.keys():
		_pending_types.append(k)
	_pending_types.shuffle()

func _pick_next_profile() -> FruitData:
	# Strict round-robin: every type appears exactly once per cycle before reshuffling.
	# Worst-case gap between any fruit type = (type_count - 1) spawns.
	if _pending_types.is_empty():
		_reset_type_cycle()
	var t: int = _pending_types.pop_front()
	return (_type_pools[t] as Array).pick_random()

func _spawn_at(x: float) -> void:
	if _resolved_pool.is_empty():
		return
	var piece = fruit_piece_packed.instantiate()
	var ctrl = piece.get_node("FruitPiece")
	var profile: FruitData = _pick_next_profile()
	ctrl.fruit_profile = profile

	# Track seen types for customer order filtering
	if profile.fruit_name not in GameManager.seen_fruit_types:
		GameManager.seen_fruit_types.append(profile.fruit_name)

	if randf() < GameManager.twists().frozen_chance:
		ctrl.frozen = true

	piece.position = Vector2(x, 8)
	add_child(piece)
	pieces.append({ "root": piece, "ctrl": ctrl, "age": 0.0, "shift": randf() * SHIFT_TIME })

func _shape_of(fd: FruitData) -> String:
	var file := fd.resource_path.get_file().get_basename()  # "apple_3x2_T"
	return file.substr(file.find("_") + 1)

# Belt Hiccups: run for a while, stall for a moment
func _update_stall(delta: float) -> void:
	_stall_timer -= delta
	if _stall_timer > 0.0:
		return
	_stalled = not _stalled
	if _stalled:
		_stall_timer = STALL_TIME
		AudioManager.play_pause_close()
		_belt_tint = belt.modulate
		belt.modulate = _belt_tint.darkened(0.25)
	else:
		_stall_timer = randf_range(RUN_TIME.x, RUN_TIME.y)
		AudioManager.play_pause_open()
		belt.modulate = _belt_tint

# Shifty Fruit: same shape, different fruit, with a little squash so the change reads
func _shift_fruit(ctrl) -> void:
	var options: Array = _shape_pools.get(_shape_of(ctrl.fruit_profile), [])
	options = options.filter(func(fd): return fd.fruit_name != ctrl.fruit_profile.fruit_name)
	if options.is_empty():
		return
	var next: FruitData = options.pick_random()
	ctrl.change_fruit_profile(next)
	if next.fruit_name not in GameManager.seen_fruit_types:
		GameManager.seen_fruit_types.append(next.fruit_name)
	var tw = ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2(1.25, 0.8), 0.06)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
