extends Node2D

# 1. Define the grid layout of this piece relative to its center (0,0)
# This example represents an L-shape piece
@export var shape_cells: Array[Vector2i] = [
	Vector2i(0, 0),  # Pivot point
	Vector2i(0, 1),  # One block down
	Vector2i(0, 2),  # Two blocks down
	Vector2i(1, 2)   # One block right at the bottom
]

var is_dragging: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	spawn_position = global_position
	target_rotation = rotation
	area_2d.input_event.connect(_on_area_2d_input_event)

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			global_position = get_global_mouse_position()
			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			rotate_piece_90_degrees()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			is_dragging = false
			attempt_placement()

func rotate_piece_90_degrees() -> void:
	target_rotation += deg_to_rad(90)
	
	# Rotate the logical data array so it matches the visual rotation
	# Clockwise 90-degree formula: (x, y) becomes (-y, x)
	for i in range(shape_cells.size()):
		var current_cell = shape_cells[i]
		shape_cells[i] = Vector2i(-current_cell.y, current_cell.x)
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", target_rotation, 0.15)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func attempt_placement() -> void:
	# Try to find the board in your active scene tree hierarchy
	var board = get_tree().current_scene.get_node_or_null("Board")
	
	if board != null:
		# Ask the board what grid coordinate (0 to 8) your mouse/pivot is currently hovering over
		var grid_pos = board.world_to_grid(global_position)
		
		# Validate if the layout array fits into the board data matrix
		if board.can_place_shape(shape_cells, grid_pos):
			# Lock it perfectly into place on the board map visually
			global_position = board.to_global(Vector2(grid_pos * board.TILE_SIZE))
			board.place_shape(shape_cells, grid_pos)
			
			# Disable any further interaction with this piece
			area_2d.input_event.disconnect(_on_area_2d_input_event)
			set_process(false)
			return

	# Return to spawn if it doesn't fit or board wasn't found
	return_to_spawn()

func return_to_spawn() -> void:
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property(self, "global_position", spawn_position, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# If we reset rotation, we must reset our math data back to 0 degrees too
	while wrapf(target_rotation, 0, TAU) > 0.01:
		rotate_piece_90_degrees() # Rotate until it matches structural origin
		
	target_rotation = 0.0
	tween.tween_property(self, "rotation", target_rotation, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
