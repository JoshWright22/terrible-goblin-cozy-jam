extends Node2D

const SMOOTHIE_TEXTURES: Dictionary = {
	0: "res://Assets/sprites/blender/bananaSmoothieSprite.PNG",
	1: "res://Assets/sprites/blender/strawberrySmoothieSprite.PNG",
	2: "res://Assets/sprites/blender/blueberrySmoothieSprite.PNG",
	3: "res://Assets/sprites/blender/mangoSmoothieSprite.PNG",
	4: "res://Assets/sprites/blender/appleSmoothieSprite.PNG",
}

const QUALITY_DRAIN_TIME := 30.0

var is_dragging: bool = false
var mouse_offset: Vector2
var spawn_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

var _drag_layer: CanvasLayer = null
var _original_parent: Node = null

var accumulated_ingredients: Array = []
var base_composition_matrix: Array[Vector2] = []

var quality: float = 1.0
var _spawn_tween: Tween = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	spawn_position = global_position
	z_as_relative = false
	z_index = 500

func initialize_smoothie_data(ingredients: Array, local_block_matrix: Array[Vector2]) -> void:
	self.accumulated_ingredients = ingredients.duplicate()
	self.base_composition_matrix = local_block_matrix.duplicate()
	_set_dominant_sprite()
	_play_spawn_animation()

func _play_spawn_animation() -> void:
	scale = Vector2.ZERO
	rotation = deg_to_rad(-360)
	modulate.a = 1.0
	_spawn_tween = create_tween()
	_spawn_tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_tween.parallel().tween_property(self, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_spawn_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_spawn_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_spawn_tween.finished.connect(func(): _spawn_tween = null)

func _set_dominant_sprite() -> void:
	var counts: Dictionary = {}
	for item in accumulated_ingredients:
		if item is FruitData:
			counts[item.fruit_name] = counts.get(item.fruit_name, 0) + 1
	if counts.is_empty():
		return
	var dominant: int = counts.keys()[0]
	for key in counts:
		if counts[key] > counts[dominant]:
			dominant = key
	if SMOOTHIE_TEXTURES.has(dominant):
		sprite.texture = load(SMOOTHIE_TEXTURES[dominant])

func _physics_process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()
	elif not GameManager.paused:
		quality = max(0.0, quality - delta / QUALITY_DRAIN_TIME)
		if quality <= 0.0:
			queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if GameManager.fruit_held:
					return
				if sprite.get_rect().has_point(sprite.to_local(get_global_mouse_position())):
					# Skip spawn animation if still playing
					if _spawn_tween != null:
						_spawn_tween.kill()
						_spawn_tween = null
						scale = Vector2(1.0, 1.0)
						rotation = 0.0
					is_dragging = true
					GameManager.hold = true
					AudioManager.play_smoothie_pickup()
					_begin_drag_layer()
			else:
				var was_dragging := is_dragging
				is_dragging = false
				_end_drag_layer()
				if GameManager.trgID != null and GameManager.hold:
					GameManager.hold = false
					GameManager.smoothie_quality = quality
					GameManager.slushiData(ingredients_to_dict())
					queue_free()
				else:
					GameManager.hold = false
					if was_dragging:
						AudioManager.play_smoothie_return()
					global_position = spawn_position
					target_rotation = 0.0
					var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property(self, "rotation", 0.0, 0.2)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and is_dragging:
			_rotate_90()

func _rotate_90() -> void:
	AudioManager.play_smoothie_rotate()
	target_rotation += deg_to_rad(90)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", target_rotation, 0.15)

func _begin_drag_layer() -> void:
	_original_parent = get_parent()
	_drag_layer = CanvasLayer.new()
	_drag_layer.layer = 100
	get_tree().root.add_child(_drag_layer)
	reparent(_drag_layer, false)

func _end_drag_layer() -> void:
	if _drag_layer != null:
		if is_instance_valid(_original_parent):
			reparent(_original_parent, false)
		_drag_layer.queue_free()
		_drag_layer = null
		_original_parent = null

func ingredients_to_dict() -> Dictionary:
	var result: Dictionary = {}
	for item in accumulated_ingredients:
		if item is FruitData:
			result[item.fruit_name] = result.get(item.fruit_name, 0) + 1
	return result
