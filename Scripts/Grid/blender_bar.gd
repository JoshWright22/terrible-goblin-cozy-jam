extends Node2D
class_name BlenderBar

const FRUIT_COLORS: Dictionary = {
	0: Color("f5e642"),  # BANANA
	1: Color("e8234a"),  # STRAWBERRY
	2: Color("4a4ae8"),  # BLUEBERRY
	3: Color("f5820d"),  # MANGO
	4: Color("c23b22"),  # APPLE
}

@onready var fill_area: Control = $FillArea

var _grid: Node = null
var _last_dict: Dictionary = {}
var _segments: Array = []

func _ready() -> void:
	_grid = get_node_or_null("../Blender/Grid")
	fill_area.z_index = -1

func _process(_delta: float) -> void:
	if not _grid:
		return
	var current := _read_grid()
	if current != _last_dict:
		_last_dict = current
		_rebuild_segments(current)
	queue_redraw()

func _read_grid() -> Dictionary:
	var result: Dictionary = {}
	var grid_visuals: Node = _grid.get_node_or_null("GridVisuals")
	if not grid_visuals:
		return result

	var smoothie: Node = grid_visuals.get_node_or_null("SmoothieOverlay")
	if smoothie:
		var ingredients = smoothie.get("accumulated_ingredients")
		if ingredients:
			for item in ingredients:
				if item is FruitData:
					result[item.fruit_name] = result.get(item.fruit_name, 0) + 1
		return result

	for tile in grid_visuals.get_children():
		if not tile.has_meta("occupied_by_fruit"):
			continue
		var fruit: Node2D = tile.get_meta("occupied_by_fruit")
		if not is_instance_valid(fruit):
			continue
		var profile = fruit.get("fruit_profile")
		if profile == null:
			continue
		var key: int = profile.fruit_name
		result[key] = result.get(key, 0) + 1
	return result

func _rebuild_segments(ingredient_dict: Dictionary) -> void:
	_segments.clear()

	var total: int = 0
	for count in ingredient_dict.values():
		total += count
	if total == 0:
		return
	for fruit_type in ingredient_dict:
		_segments.append({
			"color": FRUIT_COLORS.get(fruit_type, Color.WHITE),
			"fraction": float(ingredient_dict[fruit_type]) / float(total)
		})

func _draw() -> void:
	var r := Rect2(fill_area.position, fill_area.size)
	var y: float = r.position.y + r.size.y
	for seg in _segments:
		var h: float = seg.fraction * r.size.y
		y -= h
		draw_rect(Rect2(r.position.x, y, r.size.x, h), seg.color)
