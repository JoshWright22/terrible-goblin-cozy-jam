extends Node2D

@export var grid_rows: int = 3
@export var grid_columns: int = 3
@export var cell_pixel_size: float = 64.0  # The piece automatically stretches to match this value!
@export var tile_texture: Texture2D  

# --- SMOOTHIE BLENDER CONFIGURATION ---
@export var smoothie_texture: Texture2D  # Assign your full-grid smoothie image asset here
@export var reset_delay_seconds: float = 3.0  # Time before the smoothie disappears and grid resets

# --- AUTOMATIC BUTTON LAYOUT CONFIGURATION ---
@export var blend_button: Button  # Drag your Button node into this slot in the inspector!
@export var button_spacing_y: float = 20.0  # Pixels of clearance below the grid row boundary

var tile_size: Vector2 = Vector2.ZERO
var grid_start_pos: Vector2 = Vector2.ZERO

# --- STATE GUARD ---
var is_blending: bool = false  # Read this from your piece scripts to block drop logic!

@onready var grid_anchor: Area2D = $GridAnchor
@onready var grid_visuals: Node2D = $GridVisuals

func _ready() -> void:
	tile_size = Vector2(cell_pixel_size, cell_pixel_size)
	calculate_grid_dimensions()
	generate_physical_grid()
	
	# Call deferred to let the UI engine calculate the button's native size boundary box first
	position_and_wire_blend_button.call_deferred()

func calculate_grid_dimensions() -> void:
	var total_grid_width: float = grid_columns * tile_size.x
	var total_grid_height: float = grid_rows * tile_size.y
	
	# FIX: Calculate relative to the GridAnchor's LOCAL position instead of global world coordinates.
	# This ensures that moving the Grid root node moves all visual elements cleanly with it.
	grid_start_pos = grid_anchor.position - Vector2(total_grid_width / 2.0, total_grid_height / 2.0)

func generate_physical_grid() -> void:
	var old_smoothie = grid_visuals.get_node_or_null("SmoothieOverlay")
	if old_smoothie:
		old_smoothie.queue_free()

	for child in grid_visuals.get_children():
		child.queue_free()
		
	for x in range(grid_columns):
		for y in range(grid_rows):
			var tile_node = Node2D.new()
			tile_node.name = "Tile_%d_%d" % [x, y]
			tile_node.set_meta("is_occupied", false)
			tile_node.set_meta("grid_x", x)
			tile_node.set_meta("grid_y", y)
			
			var tile_sprite = Sprite2D.new()
			tile_sprite.texture = tile_texture if tile_texture != null else load("res://icon.svg")
			var img_size = tile_sprite.texture.get_size()
			tile_sprite.scale = Vector2(tile_size.x / img_size.x, tile_size.y / img_size.y)
			tile_node.add_child(tile_sprite)
			
			var tile_area = Area2D.new()
			tile_area.name = "TileArea"
			var tile_collision = CollisionShape2D.new()
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = tile_size - Vector2(4, 4)
			
			tile_collision.shape = rect_shape
			tile_area.add_child(tile_collision)
			tile_node.add_child(tile_area)
			
			# FIX: Position tiles using relative local offsets added to our base grid starting position
			var local_offset = Vector2((x * tile_size.x) + (tile_size.x / 2.0), (y * tile_size.y) + (tile_size.y / 2.0))
			tile_node.position = grid_start_pos + local_offset
			grid_visuals.add_child(tile_node)

# --- FIXED LOCAL LAYOUT ALIGNMENT PASS ---
func position_and_wire_blend_button() -> void:
	if not blend_button:
		print("[UI WARN] No blend button assigned in the Grid inspector slot.")
		return
		
	# Ensure the button lives inside our local transform space hierarchy
	if blend_button.get_parent() != self:
		blend_button.get_parent().remove_child(blend_button)
		add_child(blend_button)
		
	if not blend_button.pressed.is_connected(blend_grid_into_smoothie):
		blend_button.pressed.connect(blend_grid_into_smoothie)
		
	blend_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blend_button.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var total_grid_height = grid_rows * tile_size.y
	
	# FIX: Calculate the layout using local positions relative to the Grid root node origin.
	# Center horizontally along the GridAnchor's local x axis, and drop below the bottom grid bounds.
	var target_local_center_x = grid_anchor.position.x
	var target_local_bottom_y = grid_anchor.position.y + (total_grid_height / 2.0) + button_spacing_y
	
	# Set local position while adjusting for the button's own layout width midpoint
	blend_button.position = Vector2(
		target_local_center_x - (blend_button.size.x / 2.0),
		target_local_bottom_y
	)

# --- BLENDING AND TIMED RESET LOOPS ---

func blend_grid_into_smoothie() -> void:
	# Block interaction if the script is already processing a blend loop
	if not grid_visuals or blend_button.disabled or is_blending:
		return
		
	var collected_fruits: Array[Node2D] = []
	var has_pieces: bool = false
	
	for tile in grid_visuals.get_children():
		if tile.get_meta("is_occupied") == true:
			has_pieces = true
			if tile.has_meta("occupied_by_fruit"):
				var fruit_piece = tile.get_meta("occupied_by_fruit") as Node2D
				if fruit_piece and not fruit_piece in collected_fruits:
					collected_fruits.append(fruit_piece)

	if not has_pieces:
		print("[SMOOTHIE WARN] Blender empty! Place pieces on the grid first.")
		return

	# Set the guards to lock operations completely
	is_blending = true
	blend_button.disabled = true

	for fruit in collected_fruits:
		fruit.queue_free()
		
	for tile in grid_visuals.get_children():
		tile.set_meta("is_occupied", false)
		if tile.has_meta("occupied_by_fruit"):
			tile.remove_meta("occupied_by_fruit")

	create_smoothie_overlay()

func create_smoothie_overlay() -> void:
	var smoothie_container = Node2D.new()
	smoothie_container.name = "SmoothieOverlay"
	grid_visuals.add_child(smoothie_container)
	
	var smoothie_sprite = Sprite2D.new()
	smoothie_sprite.name = "SmoothieSprite"
	smoothie_sprite.texture = smoothie_texture if smoothie_texture != null else load("res://icon.svg")
	smoothie_sprite.centered = false
	smoothie_container.add_child(smoothie_sprite)
	
	# FIX: Anchor container precisely to our relative local grid start coordinates
	smoothie_container.position = grid_start_pos
	
	# FIX: Scale uniformly to span the full grid footprint layout matrix boundaries
	var tex_size = smoothie_sprite.texture.get_size()
	var total_grid_width = grid_columns * tile_size.x
	var total_grid_height = grid_rows * tile_size.y
	
	smoothie_sprite.scale = Vector2(
		total_grid_width / tex_size.x,
		total_grid_height / tex_size.y
	)
		
	smoothie_sprite.z_index = 50
	
	smoothie_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(smoothie_sprite, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# --- TIMER DELAY REVERT RUNTIME LOOP ---
	await get_tree().create_timer(reset_delay_seconds).timeout
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(smoothie_sprite, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fade_out_tween.finished
	
	smoothie_container.queue_free()
	
	# Clear the guards to allow placing/blending again
	is_blending = false
	blend_button.disabled = false
