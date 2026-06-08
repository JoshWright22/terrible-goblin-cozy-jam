extends Node2D

@export var block_layout: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(1, 0),
	Vector2(2, 0),
	Vector2(1, 1)
]

var is_dragging: bool = false
var is_locked: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

# STATE GUARDS: Track rotation states to prevent mid-tween placement calculations
var is_rotating: bool = false
var check_placement_on_rotation_complete: bool = false

var locked_tiles: Array[Node2D] = []
var dynamic_cell_size: float = 64.0
var layout_center_offset: Vector2 = Vector2.ZERO

@onready var main_click_area: Area2D = $Area2D
@onready var block_detectors: Node2D = $BlockDetectors

func _ready() -> void:
	spawn_position = global_position
	target_rotation = rotation
	main_click_area.input_event.connect(_on_area_2d_input_event)
	
	var grid_node = get_tree().current_scene.find_child("Grid", true, false)
	if grid_node and "cell_pixel_size" in grid_node:
		dynamic_cell_size = grid_node.cell_pixel_size
		
	build_piece_from_layout()

func build_piece_from_layout() -> void:
	if block_layout.is_empty():
		return

	for child in block_detectors.get_children():
		child.queue_free()

	var min_x: float = 99999.0
	var max_x: float = -99999.0
	var min_y: float = 99999.0
	var max_y: float = -99999.0

	for coord in block_layout:
		min_x = min(min_x, coord.x)
		max_x = max(max_x, coord.x)
		min_y = min(min_y, coord.y)
		max_y = max(max_y, coord.y)

	var cells_wide = (max_x - min_x) + 1.0
	var cells_high = (max_y - min_y) + 1.0

	layout_center_offset = Vector2(
		((min_x + max_x) / 2.0) * dynamic_cell_size,
		((min_y + max_y) / 2.0) * dynamic_cell_size
	)

	for i in range(block_layout.size()):
		var coord = block_layout[i]
		
		var detector = Area2D.new()
		detector.name = "Block_%d" % i
		detector.position = (coord * dynamic_cell_size) - layout_center_offset
		
		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(dynamic_cell_size - 6.0, dynamic_cell_size - 6.0)
		
		collision.shape = rect_shape
		detector.add_child(collision)
		block_detectors.add_child(detector)

	var main_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if main_sprite and main_sprite.texture:
		var raw_tex_size = main_sprite.texture.get_size()
		var target_width = cells_wide * dynamic_cell_size
		var target_height = cells_high * dynamic_cell_size
		
		main_sprite.scale = Vector2(target_width / raw_tex_size.x, target_height / raw_tex_size.y)
		main_sprite.position = Vector2.ZERO 

	var click_shape = main_click_area.get_child(0) as CollisionShape2D
	if click_shape and click_shape.shape is RectangleShape2D:
		var unique_shape = click_shape.shape.duplicate() as RectangleShape2D
		unique_shape.size = Vector2(cells_wide * dynamic_cell_size, cells_high * dynamic_cell_size)
		click_shape.shape = unique_shape
		
		main_click_area.position = Vector2.ZERO
		click_shape.position = Vector2.ZERO 

	print("[CENTERED BUILD] Piece '%s' initialized." % name)

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			check_placement_on_rotation_complete = false # Reset deferred drops
			if is_locked:
				for tile in locked_tiles:
					tile.set_meta("is_occupied", false)
				locked_tiles.clear()
				is_locked = false
			global_position = get_global_mouse_position()
			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not is_locked:
			rotate_piece_90_degrees()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			is_dragging = false
			
			# If we are mid-spin, queue up the drop to occur automatically when it finishes
			if is_rotating:
				print("[DEFER] Drop requested mid-rotation. Cueing up snap check execution...")
				check_placement_on_rotation_complete = true
			else:
				attempt_physical_placement()

func rotate_piece_90_degrees() -> void:
	is_rotating = true
	target_rotation += deg_to_rad(90)
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", target_rotation, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Listen directly for the animation complete signal
	tween.finished.connect(_on_rotation_finished)

func _on_rotation_finished() -> void:
	is_rotating = false
	print("[ROTATION COMPLETE] Clean angle locked: ", rad_to_deg(rotation), "°")
	
	# Execute placement now if the player released the click during the tween spin duration
	if check_placement_on_rotation_complete:
		check_placement_on_rotation_complete = false
		attempt_physical_placement()

func attempt_physical_placement() -> void:
	if block_detectors.get_child_count() == 0:
		return_to_spawn()
		return

	# Explicit structural check to confirm angle values are clean cardinal directions
	rotation = target_rotation

	var dynamic_anchor_block: Area2D = null
	var anchor_tile: Node2D = null
	var shortest_distance: float = 999999.0
	
	for detector in block_detectors.get_children():
		if detector is Area2D:
			var overlapping_areas = detector.get_overlapping_areas()
			for area in overlapping_areas:
				if area.name == "TileArea":
					var tile = area.get_parent()
					var dist = detector.global_position.distance_to(tile.global_position)
					if dist < shortest_distance:
						shortest_distance = dist
						dynamic_anchor_block = detector
						anchor_tile = tile
						
	if dynamic_anchor_block == null or anchor_tile == null:
		print("[DROP FAILED] Missing tile intersections.")
		return_to_spawn()
		return
		
	var anchor_gx = anchor_tile.get_meta("grid_x")
	var anchor_gy = anchor_tile.get_meta("grid_y")
	
	var grid_visuals_node = get_tree().current_scene.find_child("GridVisuals", true, false)
	var tiles_to_occupy: Array[Node2D] = []
	var placement_valid = true
	
	for detector in block_detectors.get_children():
		if detector is Area2D:
			var relative_offset = detector.position - dynamic_anchor_block.position
			var rotated_offset = relative_offset.rotated(rotation)
			
			var offset_x = round(snapped(rotated_offset.x, dynamic_cell_size) / dynamic_cell_size)
			var offset_y = round(snapped(rotated_offset.y, dynamic_cell_size) / dynamic_cell_size)
			
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
			locked_tiles.append(tile)
			
		is_locked = true
	else:
		return_to_spawn()

func return_to_spawn() -> void:
	check_placement_on_rotation_complete = false
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", spawn_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	target_rotation = 0.0
	tween.tween_property(self, "rotation", target_rotation, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
