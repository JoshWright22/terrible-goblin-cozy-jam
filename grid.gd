extends Node2D

@export var grid_rows: int = 9
@export var grid_columns: int = 9
@export var cell_pixel_size: float = 64.0  # The piece automatically stretches to match this value!
@export var tile_texture: Texture2D  

var tile_size: Vector2 = Vector2.ZERO
var grid_start_pos: Vector2 = Vector2.ZERO

@onready var grid_anchor: Area2D = $GridAnchor
@onready var grid_visuals: Node2D = $GridVisuals

func _ready() -> void:
	tile_size = Vector2(cell_pixel_size, cell_pixel_size)
	calculate_grid_dimensions()
	generate_physical_grid()

func calculate_grid_dimensions() -> void:
	var total_grid_width: float = grid_columns * tile_size.x
	var total_grid_height: float = grid_rows * tile_size.y
	grid_start_pos = grid_anchor.global_position - Vector2(total_grid_width / 2.0, total_grid_height / 2.0)

func generate_physical_grid() -> void:
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
			
			var local_pos = Vector2((x * tile_size.x) + (tile_size.x / 2.0), (y * tile_size.y) + (tile_size.y / 2.0))
			tile_node.global_position = grid_start_pos + local_pos
			grid_visuals.add_child(tile_node)
