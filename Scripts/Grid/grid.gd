extends Node2D

@export var grid_rows: int = 3
@export var grid_columns: int = 3
@export var cell_pixel_size: float = 64.0  # The piece automatically stretches to match this value!
@export var tile_texture: Texture2D  

# --- SMOOTHIE BLENDER CONFIGURATION ---
# CHANGED: Changed from Texture2D to PackedScene so you can design it in the editor
@export var smoothie_scene: PackedScene  
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
			
			var local_offset = Vector2((x * tile_size.x) + (tile_size.x / 2.0), (y * tile_size.y) + (tile_size.y / 2.0))
			tile_node.position = grid_start_pos + local_offset
			grid_visuals.add_child(tile_node)

func position_and_wire_blend_button() -> void:
	if not blend_button:
		print("[UI WARN] No blend button assigned in the Grid inspector slot.")
		return
		
	if blend_button.get_parent() != self:
		blend_button.get_parent().remove_child(blend_button)
		add_child(blend_button)
		
	if not blend_button.pressed.is_connected(blend_grid_into_smoothie):
		blend_button.pressed.connect(blend_grid_into_smoothie)
		
	blend_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blend_button.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var total_grid_height = grid_rows * tile_size.y
	
	var target_local_center_x = grid_anchor.position.x
	var target_local_bottom_y = grid_anchor.position.y + (total_grid_height / 2.0) + button_spacing_y
	
	blend_button.position = Vector2(
		target_local_center_x - (blend_button.size.x / 2.0),
		target_local_bottom_y
	)

func blend_grid_into_smoothie() -> void:
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

	is_blending = true
	blend_button.disabled = true

	var ingredient_data: Array = []
	for fruit in collected_fruits:
		if "fruit_profile" in fruit and fruit.fruit_profile != null:
			ingredient_data.append(fruit.fruit_profile)
		fruit.queue_free()

	for tile in grid_visuals.get_children():
		tile.set_meta("is_occupied", false)
		if tile.has_meta("occupied_by_fruit"):
			tile.remove_meta("occupied_by_fruit")

	create_smoothie_overlay(ingredient_data)

# --- REFACTORED TO INSTANTIATE SCENE ---
func create_smoothie_overlay(ingredients: Array = []) -> void:
	if not smoothie_scene:
		print("[SMOOTHIE WARN] No smoothie scene assigned in the inspector!")
		is_blending = false
		blend_button.disabled = false
		return

	# 1. Instantiate your pre-made scene node
	var smoothie_instance = smoothie_scene.instantiate() as Node2D
	smoothie_instance.name = "SmoothieOverlay"
	
	# 2. Position at grid center so the sprite's centered=true aligns with the collision origin
	smoothie_instance.position = grid_anchor.position

	# 3. Add it to the visual hierarchy
	grid_visuals.add_child(smoothie_instance)

	if smoothie_instance.has_method("initialize_smoothie_data"):
		smoothie_instance.initialize_smoothie_data(ingredients, Array([], TYPE_VECTOR2, &"", null))

	# Scale the sprite to fill the grid, then re-sync the collision shape to match
	var sprite = smoothie_instance if smoothie_instance is Sprite2D else smoothie_instance.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		var total_grid_width = grid_columns * tile_size.x
		var total_grid_height = grid_rows * tile_size.y
		sprite.scale = Vector2(total_grid_width / tex_size.x, total_grid_height / tex_size.y)
		sprite.centered = true
		sprite.position = Vector2.ZERO
		if smoothie_instance.has_method("enforce_strict_centering"):
			smoothie_instance.enforce_strict_centering()

	# --- SMOOTHIE LIFECYCLE MANAGEMENT ---
	smoothie_instance.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(smoothie_instance, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(reset_delay_seconds).timeout

	if not is_instance_valid(smoothie_instance):
		is_blending = false
		blend_button.disabled = false
		return

	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(smoothie_instance, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fade_out_tween.finished

	if is_instance_valid(smoothie_instance):
		smoothie_instance.queue_free()
	
	# Clear guards for layout interactions
	is_blending = false
	blend_button.disabled = false
