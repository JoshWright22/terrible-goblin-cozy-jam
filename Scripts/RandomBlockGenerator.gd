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

func _ready() -> void:
	_build_pool()
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
		if fd != null and fd.layout.size() >= min_blocks and fd.layout.size() <= max_blocks:
			_resolved_pool.append(fd)
			if not _type_pools.has(fd.fruit_name):
				_type_pools[fd.fruit_name] = []
			(_type_pools[fd.fruit_name] as Array).append(fd)
	if _resolved_pool.is_empty():
		push_warning("RandomBlockGenerator: no FruitData matches the current quality range.")
	_reset_type_cycle()

func _scan_all_fruit_data(path: String) -> Array[FruitData]:
	var result: Array[FruitData] = []
	var dir = DirAccess.open(path)
	if not dir:
		return result
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if dir.current_is_dir() and not file.begins_with("."):
			result.append_array(_scan_all_fruit_data(path + file + "/"))
		elif file.ends_with(".tres"):
			var res = load(path + file)
			if res is FruitData:
				result.append(res)
		file = dir.get_next()
	dir.list_dir_end()
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

	for p in to_remove:
		pieces.erase(p)

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

	piece.position = Vector2(x, 8)
	add_child(piece)
	pieces.append({ "root": piece, "ctrl": ctrl })
