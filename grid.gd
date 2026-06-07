extends Node2D

@export var grid_rows: int = 9       # Change this in the inspector to resize your grid
@export var grid_columns: int = 9    # Change this in the inspector to resize your grid
@export var tile_texture: Texture2D  # Drop your background tile image here

var tile_size: Vector2 = Vector2(64, 64)
var grid_data: Dictionary = {}
var grid_start_pos: Vector2 = Vector2.ZERO

@onready var grid_anchor: Area2D = $GridAnchor
@onready var collision_shape: CollisionShape2D = $GridAnchor/CollisionShape2D
@onready var grid_visuals: Node2D = $GridVisuals

func _ready() -> void:
	calculate_grid_dimensions()
	initialize_grid_data()
	generate_visual_grid()

func calculate_grid_dimensions() -> void:
	# Save the top-left starting position of our grid
	grid_start_pos = grid_anchor.global_position
	
	# Extract the size directly from the RectangleShape2D resource
	if collision_shape and collision_shape.shape is RectangleShape2D:
		# RectangleShape2D 'size' is the total width and height
		tile_size = collision_shape.shape.size
	else:
		push_warning("GridAnchor needs a RectangleShape2D to calculate tile size dynamically!")

func initialize_grid_data() -> void:
	grid_data.clear()
	# Dynamically populate the matrix based on your chosen rows and columns
	for x in range(grid_columns):
		for y in range(grid_rows):
			grid_data[Vector2i(x, y)] = false

func generate_visual_grid() -> void:
	# Clear out old visuals if updating at runtime
	for child in grid_visuals.get_children():
		child.queue_free()
		
	if tile_texture == null:
		return # Skip drawing if no texture image was provided
		
	# Spawn a grid of background sprites automatically matching our dynamic dimensions
	for x in range(grid_columns):
		for y in range(grid_rows):
			var tile_sprite = Sprite2D.new()
			tile_sprite.texture = tile_texture
			
			# Calculate centered position for the sprite relative to the grid start position
			var local_pos = Vector2(
				(x * tile_size.x) + (tile_size.x / 2),
				(y * tile_size.y) + (tile_size.y / 2)
			)
			tile_sprite.global_position = grid_start_pos + local_pos
			grid_visuals.add_child(tile_sprite)

# Converts any screen space coordinate into a Grid coordinate (e.g., Vector2i(0, 4))
func world_to_grid(global_pos: Vector2) -> Vector2i:
	var relative_pos = global_pos - grid_start_pos
	return Vector2i(
		floor(relative_pos.x / tile_size.x),
		floor(relative_pos.y / tile_size.y)
	)

# Checks if a shape array fits onto the dynamic boundaries
func can_place_shape(cells: Array[Vector2i], start_grid_pos: Vector2i) -> bool:
	for cell in cells:
		var target_cell = start_grid_pos + cell
		
		# Out of bounds check using our dynamic row/col variables
		if target_cell.x < 0 or target_cell.x >= grid_columns or target_cell.y < 0 or target_cell.y >= grid_rows:
			return false
			
		# Check if cell is occupied
		if not grid_data.has(target_cell) or grid_data[target_cell] == true:
			return false
	return true

func place_shape(cells: Array[Vector2i], start_grid_pos: Vector2i) -> void:
	for cell in cells:
		var target_cell = start_grid_pos + cell
		if grid_data.has(target_cell):
			grid_data[target_cell] = true
