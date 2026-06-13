extends Node2D

var is_dragging: bool = false
var mouse_offset: Vector2
var spawn_position: Vector2 = Vector2.ZERO

var accumulated_ingredients: Array = []
var base_composition_matrix: Array[Vector2] = []

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	spawn_position = global_position

func initialize_smoothie_data(ingredients: Array, local_block_matrix: Array[Vector2]) -> void:
	self.accumulated_ingredients = ingredients.duplicate()
	self.base_composition_matrix = local_block_matrix.duplicate()

func _physics_process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - mouse_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if sprite.get_rect().has_point(to_local(event.position)):
				is_dragging = true
				GameManager.hold = true
				mouse_offset = get_global_mouse_position() - global_position
				z_as_relative = false
				z_index = 200
		else:
			is_dragging = false
			z_as_relative = true
			z_index = 0
			if GameManager.trgID != null and GameManager.hold:
				GameManager.slushiData(ingredients_to_dict())
				queue_free()
			else:
				GameManager.hold = false
				global_position = spawn_position

func ingredients_to_dict() -> Dictionary:
	var result: Dictionary = {}
	for item in accumulated_ingredients:
		if item is FruitData:
			result[item.fruit_name] = result.get(item.fruit_name, 0) + 1
	return result
