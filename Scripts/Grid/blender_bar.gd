extends Node2D
class_name BlenderBar

const FRUIT_COLORS: Dictionary = {
	0: Color("f5e642"), # BANANA
	1: Color("e8234a"), # STRAWBERRY
	2: Color("4a4ae8"), # BLUEBERRY
	3: Color("f5820d"), # MANGO
	4: Color("f2e8c8"), # APPLE
}

@export var bar_scale: float = 0.2

const ORIG_LEFT  := -56.0
const ORIG_TOP   := -804.0
const ORIG_RIGHT := 52.39
const ORIG_BOTTOM := 803.765

@onready var fill_area: Control = $FillArea

var _grid: Node = null
var _last_dict: Dictionary = {}
var _segments: Array = []
var _was_showing_smoothie: bool = false

func _ready() -> void:
	_grid = get_node_or_null("../Blender/Grid")
	fill_area.z_index = -1
	scale = Vector2(bar_scale, bar_scale)

func _process(_delta: float) -> void:
	if not _grid:
		return

	var grid_visuals: Node = _grid.get_node_or_null("GridVisuals")
	if grid_visuals:
		var smoothie: Node = grid_visuals.get_node_or_null("SmoothieOverlay")
		if smoothie:
			_segments = _smoothie_to_segments(smoothie)
			_was_showing_smoothie = true
			queue_redraw()
			return

	# Smoothie is being dragged — keep bar frozen at last known state
	if GameManager.hold:
		queue_redraw()
		return

	var current := _read_grid()
	if current != _last_dict or _was_showing_smoothie:
		_last_dict = current
		_was_showing_smoothie = false
		_rebuild_segments(current)
	queue_redraw()

func _smoothie_to_segments(smoothie: Node) -> Array:
	var q: float = smoothie.get("quality") if smoothie.get("quality") != null else 1.0
	var ingredients = smoothie.get("accumulated_ingredients")
	if ingredients == null or ingredients.is_empty():
		return [_quality_to_segment(q)]
	var counts: Dictionary = {}
	for item in ingredients:
		var name_val = item.get("fruit_name") if item.get("fruit_name") != null else -1
		if name_val != -1:
			counts[name_val] = counts.get(name_val, 0) + 1
	if counts.is_empty():
		return [_quality_to_segment(q)]
	var total: int = 0
	for c in counts.values():
		total += c
	var result: Array = []
	for fruit_type in counts:
		result.append({
			"color": FRUIT_COLORS.get(fruit_type, Color.WHITE),
			"fraction": (float(counts[fruit_type]) / float(total)) * q
		})
	return result

func _quality_to_segment(q: float) -> Dictionary:
	var col: Color
	if q > 0.6:
		col = Color(0.2, 0.85, 0.2)
	elif q > 0.3:
		col = Color(0.9, 0.75, 0.1)
	else:
		col = Color(0.9, 0.2, 0.15)
	return {"color": col, "fraction": q}

func _read_grid() -> Dictionary:
	var result: Dictionary = {}
	var grid_visuals: Node = _grid.get_node_or_null("GridVisuals")
	if not grid_visuals:
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
		queue_redraw()
		return
	for fruit_type in ingredient_dict:
		_segments.append({
			"color": FRUIT_COLORS.get(fruit_type, Color.WHITE),
			"fraction": float(ingredient_dict[fruit_type]) / float(total)
		})

func _draw() -> void:
	var h_total := ORIG_BOTTOM - ORIG_TOP
	var y := ORIG_BOTTOM
	for seg in _segments:
		var h: float = seg.fraction * h_total
		y -= h
		draw_rect(Rect2(ORIG_LEFT, y, ORIG_RIGHT - ORIG_LEFT, h), seg.color)
