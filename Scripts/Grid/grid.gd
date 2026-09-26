extends Node2D

@export var grid_rows: int = 4
@export var grid_columns: int = 4
@export var cell_pixel_size: float = 64.0 # The piece automatically stretches to match this value!
@export var tile_texture: Texture2D
@export var blender_texture: Texture2D
@export var blender_scale: float = 1.9
@export var blender_offset: Vector2 = Vector2.ZERO
@export var blend_button_normal_texture: Texture2D
@export var blend_button_pressed_texture: Texture2D
@export var blend_button_sprite_scale: float = 0.5

# --- SMOOTHIE BLENDER CONFIGURATION ---
# CHANGED: Changed from Texture2D to PackedScene so you can design it in the editor
@export var smoothie_scene: PackedScene
@export var reset_delay_seconds: float = 3.0 # Time before the smoothie disappears and grid resets

# --- AUTOMATIC BUTTON LAYOUT CONFIGURATION ---
@export var blend_button: Button # Drag your Button node into this slot in the inspector!
@export var button_spacing_y: float = 20.0 # Pixels of clearance below the grid row boundary

var tile_size: Vector2 = Vector2.ZERO
var grid_start_pos: Vector2 = Vector2.ZERO

# --- STATE GUARD ---
var is_blending: bool = false # Read this from your piece scripts to block drop logic!
var out_of_order: bool = false

@onready var grid_anchor: Area2D = $GridAnchor
@onready var grid_visuals: Node2D = $GridVisuals

func _ready() -> void:
	var day: DayConfig = GameManager.current_day
	if day:
		grid_rows = day.grid_size
		grid_columns = day.grid_size
		out_of_order = _blender_number() > day.blender_count
	tile_size = Vector2(cell_pixel_size, cell_pixel_size)
	calculate_grid_dimensions()
	generate_physical_grid()
	if out_of_order:
		_show_out_of_order()
	elif day and day.rotten_cells > 0:
		_add_rotten_cells(day.rotten_cells)

	# Call deferred to let the UI engine calculate the button's native size boundary box first
	position_and_wire_blend_button.call_deferred()

# GridScene, GridScene2, GridScene3... in the game loop -> 1, 2, 3...
func _blender_number() -> int:
	var node: Node = self
	while node and not String(node.name).begins_with("GridScene"):
		node = node.get_parent()
	if node == null:
		return 1
	var suffix := String(node.name).trim_prefix("GridScene")
	return int(suffix) if suffix.is_valid_int() else 1

# Blender Down day: grey it out and remove the tiles so nothing can be dropped in
func _show_out_of_order() -> void:
	for tile in grid_visuals.get_children():
		if tile.has_meta("is_occupied"):
			tile.queue_free()
	grid_visuals.modulate = Color(0.45, 0.45, 0.5, 0.8)
	if blend_button:
		blend_button.modulate = Color(0.5, 0.5, 0.55)
		blend_button.disabled = true
	var sign_label := Label.new()
	sign_label.text = "OUT OF\nORDER"
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.add_theme_font_size_override("font_size", 55)
	sign_label.add_theme_constant_override("outline_size", 10)
	sign_label.add_theme_color_override("font_outline_color", Color.BLACK)
	sign_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	sign_label.size = Vector2(300, 120)
	sign_label.position = grid_anchor.position - sign_label.size / 2.0
	sign_label.rotation_degrees = -8.0
	sign_label.pivot_offset = sign_label.size / 2.0
	add_child(sign_label)

# Rotten Batch day: some tiles start blocked
func _add_rotten_cells(count: int) -> void:
	var tiles := grid_visuals.get_children().filter(func(t): return t.has_meta("is_occupied"))
	tiles.shuffle()
	for i in mini(count, tiles.size()):
		var tile: Node2D = tiles[i]
		tile.set_meta("is_occupied", true)
		tile.set_meta("rotten", true)
		var mold := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.52, 0.44, 0.24)
		style.set_corner_radius_all(14)
		style.set_border_width_all(3)
		style.border_color = Color(0.25, 0.2, 0.1)
		mold.add_theme_stylebox_override("panel", style)
		mold.size = tile_size - Vector2(8, 8)
		mold.position = -mold.size / 2.0
		mold.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(mold)
		var mark := Label.new()
		mark.text = "X"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 50)
		mark.add_theme_color_override("font_color", Color(0.3, 0.45, 0.18))
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size = tile_size
		mark.position = -tile_size / 2.0
		tile.add_child(mark)

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

	if blender_texture:
		var bg = Sprite2D.new()
		bg.name = "BlenderBackground"
		bg.texture = blender_texture
		bg.centered = true
		bg.position = grid_anchor.position + blender_offset
		var total_h = grid_rows * tile_size.y * blender_scale
		var uniform_scale = total_h / blender_texture.get_height()
		bg.scale = Vector2(uniform_scale, uniform_scale)
		bg.z_index = -1
		Cosmetics.apply_blender(bg)
		grid_visuals.add_child(bg)

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
	var blender_half_height = (total_grid_height * blender_scale) / 2.0

	var target_local_center_x = grid_anchor.position.x
	var target_local_bottom_y = grid_anchor.position.y + blender_half_height - button_spacing_y

	# Size the button to the sprite's rendered dimensions so the full sprite is clickable
	var btn_size = blend_button.size
	if blend_button_normal_texture:
		btn_size = blend_button_normal_texture.get_size() * blend_button_sprite_scale
		blend_button.custom_minimum_size = btn_size
		blend_button.size = btn_size

	blend_button.position = Vector2(
		target_local_center_x - btn_size.x / 2.0,
		target_local_bottom_y - btn_size.y / 2.0
	)

	_setup_blend_button_sprites(btn_size)

func _setup_blend_button_sprites(btn_size: Vector2) -> void:
	for child in blend_button.get_children():
		child.queue_free()

	if not blend_button_normal_texture and not blend_button_pressed_texture:
		return

	blend_button.text = ""
	var center = btn_size / 2.0

	if blend_button_normal_texture:
		var normal_spr = Sprite2D.new()
		normal_spr.name = "NormalSprite"
		normal_spr.texture = blend_button_normal_texture
		normal_spr.centered = true
		normal_spr.position = center
		normal_spr.scale = Vector2(blend_button_sprite_scale, blend_button_sprite_scale)
		blend_button.add_child(normal_spr)

	if blend_button_pressed_texture:
		var pressed_spr = Sprite2D.new()
		pressed_spr.name = "PressedSprite"
		pressed_spr.texture = blend_button_pressed_texture
		pressed_spr.centered = true
		pressed_spr.position = center
		pressed_spr.scale = Vector2(blend_button_sprite_scale, blend_button_sprite_scale)
		pressed_spr.visible = false
		blend_button.add_child(pressed_spr)

	if not blend_button.button_down.is_connected(_on_blend_button_down):
		blend_button.button_down.connect(_on_blend_button_down)
		blend_button.button_up.connect(_on_blend_button_up)

func _on_blend_button_down() -> void:
	AudioManager.play_button_click()
	blend_button.get_node_or_null("NormalSprite").visible = false if blend_button.get_node_or_null("NormalSprite") else null
	var p = blend_button.get_node_or_null("PressedSprite")
	if p: p.visible = true

func _on_blend_button_up() -> void:
	var n = blend_button.get_node_or_null("NormalSprite")
	if n: n.visible = true
	var p = blend_button.get_node_or_null("PressedSprite")
	if p: p.visible = false


func blend_grid_into_smoothie() -> void:
	if not grid_visuals or is_blending or GameManager.paused or out_of_order:
		return
	if GameManager.power_out:
		AudioManager.play_customer_angry()
		return

	var collected_fruits: Array[Node2D] = []
	var has_pieces: bool = false

	for tile in grid_visuals.get_children():
		if not tile.has_meta("is_occupied") or tile.has_meta("rotten"):
			continue
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
	AudioManager.play_blend_start()
	
	var ingredient_data: Array = []
	for fruit in collected_fruits:
		if "fruit_profile" in fruit and fruit.fruit_profile != null:
			ingredient_data.append(fruit.fruit_profile)
		fruit.queue_free()

	for tile in grid_visuals.get_children():
		if not tile.has_meta("is_occupied") or tile.has_meta("rotten"):
			continue
		tile.set_meta("is_occupied", false)
		if tile.has_meta("occupied_by_fruit"):
			tile.remove_meta("occupied_by_fruit")

	create_smoothie_overlay(ingredient_data)

# --- REFACTORED TO INSTANTIATE SCENE ---
func create_smoothie_overlay(ingredients: Array = []) -> void:
	if not smoothie_scene:
		print("[SMOOTHIE WARN] No smoothie scene assigned in the inspector!")
		is_blending = false
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
		var uniform_scale := minf(total_grid_width / tex_size.x, total_grid_height / tex_size.y)
		sprite.scale = Vector2(uniform_scale, uniform_scale)
		sprite.centered = true
		sprite.position = Vector2.ZERO
		if smoothie_instance.has_method("enforce_strict_centering"):
			smoothie_instance.enforce_strict_centering()

	# --- SMOOTHIE LIFECYCLE MANAGEMENT ---
	smoothie_instance.modulate.a = 1.0
	AudioManager.play_blend_complete()

	# Wait until the smoothie frees itself (quality hits 0) or is dropped on a target
	while is_instance_valid(smoothie_instance):
		await get_tree().create_timer(0.25).timeout

	is_blending = false
