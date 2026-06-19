extends Node2D

# 1. RESOURCE DATA EXTRACTION BUCKETS
@export var fruit_profile: FruitData

@export var block_layout: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(2, 0),
	Vector2(1, 1)
]

# --- TOGGLEABLE MODIFIER CONFIGURATIONS ---
@export_group("Modifiers")
@export var change_shape_on_pickup: bool = false
@export var shapeshift_while_held: bool = false
@export var variant_pool: Array[FruitData] = [] # Assign allowed transformation resources here!

var is_dragging: bool = false
var is_locked: bool = false
var is_falling: bool = false
var fall_velocity: float = 0.0
var _pickup_fall_velocity: float = 0.0  # velocity stored when picking up mid-fall
var detached_from_conveyor: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

@export var fall_gravity: float = 800.0
@export var pop_up_speed: float = -250.0

# STATE GUARDS: Track rotation states to prevent mid-tween placement calculations
var is_rotating: bool = false
var check_placement_on_rotation_complete: bool = false

var locked_tiles: Array[Node2D] = []
var dynamic_cell_size: float = 64.0
var layout_center_offset: Vector2 = Vector2.ZERO
var blank_cell_layout: Array[Vector2] = []

# 2. PUBLIC DATA READOUTS
var current_fruit_type: int = 0
var total_block_count: int = 0

@onready var main_click_area: Area2D = $Area2D
@onready var block_detectors: Node2D = $BlockDetectors

# Internal tracking for tick transformations
var shifting_timer: Timer = null

# Cache local layout bounds for strict math validation
var local_min_x: float = 0.0
var local_min_y: float = 0.0

func _ready() -> void:
	spawn_position = global_position
	target_rotation = rotation
	
	if main_click_area:
		main_click_area.input_event.connect(_on_main_click_area_input)
	
	# Dynamically scale cell sizes using a nearby grid node context if available initially
	var fallback_grid = get_tree().current_scene.find_child("Grid*", true, false)
	if fallback_grid and "cell_pixel_size" in fallback_grid:
		dynamic_cell_size = fallback_grid.cell_pixel_size
		
	if fruit_profile != null:
		current_fruit_type = fruit_profile.fruit_name
		block_layout = fruit_profile.layout
		blank_cell_layout = fruit_profile.blank_cells

	total_block_count = block_layout.size()
	build_piece_from_layout()
	
	# Set up the internal processing timer engine loop for held shifting
	setup_shifting_timer()

func change_fruit_profile(new_profile: FruitData) -> void:
	if new_profile == null:
		return
	fruit_profile = new_profile
	current_fruit_type = fruit_profile.fruit_name
	block_layout = fruit_profile.layout
	blank_cell_layout = fruit_profile.blank_cells
	total_block_count = block_layout.size()
	build_piece_from_layout()

func build_piece_from_layout() -> void:
	if block_layout.is_empty():
		return

	for child in block_detectors.get_children():
		child.queue_free()

	# Filled-only bounds — used for the rotation/drag pivot
	var fill_min_x: float = 99999.0
	var fill_max_x: float = -99999.0
	var fill_min_y: float = 99999.0
	var fill_max_y: float = -99999.0

	for coord in block_layout:
		fill_min_x = min(fill_min_x, coord.x)
		fill_max_x = max(fill_max_x, coord.x)
		fill_min_y = min(fill_min_y, coord.y)
		fill_max_y = max(fill_max_y, coord.y)

	# Full bounds including blank cells — used for sprite sizing and click area
	var min_x: float = fill_min_x
	var max_x: float = fill_max_x
	var min_y: float = fill_min_y
	var max_y: float = fill_max_y

	for coord in blank_cell_layout:
		min_x = min(min_x, coord.x)
		max_x = max(max_x, coord.x)
		min_y = min(min_y, coord.y)
		max_y = max(max_y, coord.y)

	local_min_x = min_x
	local_min_y = min_y

	var cells_wide = (max_x - min_x) + 1.0
	var cells_high = (max_y - min_y) + 1.0

	layout_center_offset = Vector2(
		((fill_min_x + fill_max_x) / 2.0) * dynamic_cell_size,
		((fill_min_y + fill_max_y) / 2.0) * dynamic_cell_size
	)

	var main_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if fruit_profile != null and main_sprite:
		main_sprite.texture = fruit_profile.texture

	for i in range(block_layout.size()):
		var coord = block_layout[i]
		var detector = Area2D.new()
		detector.name = "Block_%d" % i
		detector.position = (coord * dynamic_cell_size) - layout_center_offset
		
		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(dynamic_cell_size - 4.0, dynamic_cell_size - 4.0)
		
		collision.shape = rect_shape
		detector.add_child(collision)
		block_detectors.add_child(detector)

	if main_sprite and main_sprite.texture:
		var native_block_pixel_size: float = 120.0
		var uniform_scale = dynamic_cell_size / native_block_pixel_size
		main_sprite.scale = Vector2(uniform_scale, uniform_scale)
		main_sprite.centered = false
		
		var structure_top_left = Vector2(min_x, min_y) * dynamic_cell_size
		var half_cell_compensation = Vector2(dynamic_cell_size, dynamic_cell_size) / 2.0
		main_sprite.position = structure_top_left - layout_center_offset - half_cell_compensation

	var click_shape = main_click_area.get_child(0) as CollisionShape2D
	if click_shape and click_shape.shape is RectangleShape2D:
		var unique_shape = click_shape.shape.duplicate() as RectangleShape2D
		var belt_padding := 0.0 if is_locked else 18.0
		unique_shape.size = Vector2(cells_wide * dynamic_cell_size + belt_padding, cells_high * dynamic_cell_size + belt_padding)
		click_shape.shape = unique_shape
		main_click_area.position = Vector2.ZERO
		click_shape.position = Vector2.ZERO

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_dragging:
		GameManager.fruit_held = false

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()
	elif is_falling:
		fall_velocity += fall_gravity * delta
		global_position.y += fall_velocity * delta
		if global_position.y > get_viewport_rect().size.y + 300.0:
			get_parent().queue_free()
	elif is_locked:
		pass
	elif detached_from_conveyor:
		spawn_position = global_position

# Returns competing fruit pieces whose click area overlaps this one
func _get_overlapping_pieces() -> Array:
	var result := []
	for area in main_click_area.get_overlapping_areas():
		var parent = area.get_parent()
		if parent != self and "total_block_count" in parent:
			result.append(parent)
	return result

# Master bounding click processor
func _on_main_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if GameManager.paused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Only one fruit piece held at a time
		if GameManager.fruit_held:
			return

		var local_mouse_pos = to_local(get_global_mouse_position())
		var block_space_pos = local_mouse_pos + layout_center_offset

		var clicked_cell_x = round(block_space_pos.x / dynamic_cell_size)
		var clicked_cell_y = round(block_space_pos.y / dynamic_cell_size)
		var targeted_cell = Vector2(clicked_cell_x, clicked_cell_y)

		if not targeted_cell in block_layout:
			return

		# If overlapping another piece on the belt/mid-air, defer to the larger one.
		# Skip this check for locked grid pieces — they should always be re-pickable.
		# Never defer to a locked blender piece — belt/falling pieces take priority.
		if not is_locked:
			for other in _get_overlapping_pieces():
				if other.is_locked:
					continue
				if other.total_block_count > total_block_count:
					return
				if other.total_block_count == total_block_count and other.get_instance_id() > get_instance_id():
					return

		GameManager.fruit_held = true
		AudioManager.play_fruit_pickup()

		if is_falling:
			_pickup_fall_velocity = fall_velocity
			is_falling = false
			fall_velocity = 0.0

		is_dragging = true
		check_placement_on_rotation_complete = false
		z_as_relative = false
		z_index = 600

		# Pop animation on pickup
		var pickup_tw := create_tween()
		pickup_tw.tween_property(self, "scale", Vector2(1.18, 1.18), 0.07)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pickup_tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		if is_locked:
			for tile in locked_tiles:
				tile.set_meta("is_occupied", false)
				if tile.has_meta("occupied_by_fruit"):
					tile.remove_meta("occupied_by_fruit")
			locked_tiles.clear()
			is_locked = false

		global_position = get_global_mouse_position()

		# --- MODIFIER RUNTIME TRIGGERS ---
		if change_shape_on_pickup:
			trigger_random_transformation()

		if shapeshift_while_held:
			shifting_timer.start()

func _input(event: InputEvent) -> void:
	if GameManager.paused and is_dragging:
		is_dragging = false
		if shifting_timer:
			shifting_timer.stop()
		return_to_spawn()
		return
	if not is_dragging:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			GameManager.fruit_held = false

			# Stop the constant shift cycles upon releasing the piece
			if shifting_timer:
				shifting_timer.stop()

			if is_rotating:
				check_placement_on_rotation_complete = true
			else:
				attempt_physical_placement()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not is_locked:
			rotate_piece_90_degrees()

func rotate_piece_90_degrees() -> void:
	AudioManager.play_fruit_rotate()
	is_rotating = true
	target_rotation += deg_to_rad(90)
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", target_rotation, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_rotation_finished)

func _on_rotation_finished() -> void:
	is_rotating = false
	if check_placement_on_rotation_complete:
		check_placement_on_rotation_complete = false
		attempt_physical_placement()

# --- MODIFIER UTILITY ENGINES ---

func setup_shifting_timer() -> void:
	shifting_timer = Timer.new()
	shifting_timer.wait_time = 1.0
	shifting_timer.one_shot = false
	shifting_timer.timeout.connect(trigger_random_transformation)
	add_child(shifting_timer)

func trigger_random_transformation() -> void:
	# Fallback safety: If nothing is explicitly assigned to variant_pool, populate it from resource files
	if variant_pool.is_empty():
		populate_fallback_variant_pool("res://")
		
	if variant_pool.is_empty():
		print("[MODIFIER WARN] No valid FruitData resources found for transformation processing.")
		return
		
	var random_profile = variant_pool.pick_random()
	change_fruit_profile(random_profile)

# Scans project directories to dynamically harvest compatible profile configurations
func populate_fallback_variant_pool(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				populate_fallback_variant_pool(path + file_name + "/")
			elif file_name.ends_with(".tres"):
				var res = load(path + file_name)
				if res is FruitData and not res in variant_pool:
					variant_pool.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()

# --- FIXED MULTI-BOARD INSTANCE DETECTOR ---
func attempt_physical_placement() -> void:
	if block_detectors.get_child_count() == 0:
		return_to_spawn()
		return

	rotation = target_rotation

	var dynamic_anchor_block: Area2D = null
	var anchor_tile: Node2D = null
	var target_grid_node: Node2D = null
	var shortest_distance: float = 999999.0
	
	for detector in block_detectors.get_children():
		if detector is Area2D:
			var overlapping_areas = detector.get_overlapping_areas()
			for area in overlapping_areas:
				if area.name == "TileArea":
					var tile = area.get_parent()
					var possible_grid = tile.get_parent().get_parent() 
					
					var dist = detector.global_position.distance_to(tile.global_position)
					if dist < shortest_distance:
						shortest_distance = dist
						dynamic_anchor_block = detector
						anchor_tile = tile
						target_grid_node = possible_grid
						
	if dynamic_anchor_block == null or anchor_tile == null or target_grid_node == null:
		if detached_from_conveyor:
			start_falling()
		else:
			return_to_spawn()
		return

	if "is_blending" in target_grid_node and target_grid_node.is_blending:
		print("[DROP REJECTED] That specific blender board is currently busy processing!")
		if detached_from_conveyor:
			start_falling()
		else:
			return_to_spawn()
		return
		
	var anchor_gx = anchor_tile.get_meta("grid_x")
	var anchor_gy = anchor_tile.get_meta("grid_y")
	
	var grid_visuals_node = target_grid_node.get_node_or_null("GridVisuals")
	var tiles_to_occupy: Array[Node2D] = []
	var placement_valid = true
	
	var anchor_global_pos = dynamic_anchor_block.global_position
	
	for detector in block_detectors.get_children():
		if detector is Area2D:
			var global_delta = detector.global_position - anchor_global_pos
			
			var offset_x = int(roundf(global_delta.x / dynamic_cell_size))
			var offset_y = int(roundf(global_delta.y / dynamic_cell_size))
			
			var target_gx = anchor_gx + offset_x
			var target_gy = anchor_gy + offset_y
			
			var target_tile_name = "Tile_%d_%d" % [target_gx, target_gy]
			var target_tile = grid_visuals_node.get_node_or_null(target_tile_name) if grid_visuals_node else null
			
			if target_tile != null:
				if target_tile.get_meta("is_occupied") == true:
					placement_valid = false
					break
				else:
					tiles_to_occupy.append(target_tile)
			else:
				placement_valid = false
				break

	if placement_valid and tiles_to_occupy.size() == block_detectors.get_child_count():
		var global_anchor_offset = dynamic_anchor_block.position.rotated(rotation)
		global_position = anchor_tile.global_position - global_anchor_offset

		for tile in tiles_to_occupy:
			tile.set_meta("is_occupied", true)
			tile.set_meta("occupied_by_fruit", self)
			locked_tiles.append(tile)

		is_locked = true
		detached_from_conveyor = true
		spawn_position = global_position
		z_as_relative = true
		z_index = 0
		AudioManager.play_fruit_land()
		var bounce = create_tween()
		bounce.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bounce.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		if detached_from_conveyor:
			start_falling()
		else:
			return_to_spawn()

func return_to_spawn() -> void:
	AudioManager.play_fruit_putdown()
	check_placement_on_rotation_complete = false
	z_as_relative = true
	z_index = 0
	target_rotation = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	if not detached_from_conveyor:
		# Tween local position back to (0,0) within the moving belt root node
		tween.tween_property(self, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(self, "global_position", spawn_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target_rotation, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func start_falling() -> void:
	detached_from_conveyor = true
	check_placement_on_rotation_complete = false
	z_as_relative = false
	z_index = 200
	is_falling = true
	# Restore momentum if picked up mid-fall, otherwise use default pop
	fall_velocity = _pickup_fall_velocity if _pickup_fall_velocity != 0.0 else pop_up_speed
	_pickup_fall_velocity = 0.0
