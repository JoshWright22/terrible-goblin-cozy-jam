extends Node2D

signal smoothie_delivered(ingredients: Array)

# --- DRAG AND DROP CONFIGURATIONS ---
var is_dragging: bool = false
var spawn_position: Vector2 = Vector2.ZERO

# --- HISTORICAL INGREDIENT DATA STORAGE ---
var accumulated_ingredients: Array = []
var base_composition_matrix: Array[Vector2] = []

@onready var main_click_area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	spawn_position = global_position
	
	if main_click_area:
		main_click_area.input_event.connect(_on_main_click_area_input)
	
	enforce_strict_centering()

## Public initialization pipeline called by the Grid when blending.
func initialize_smoothie_data(ingredients: Array, local_block_matrix: Array[Vector2]) -> void:
	self.accumulated_ingredients = ingredients.duplicate()
	self.base_composition_matrix = local_block_matrix.duplicate()
	
	enforce_strict_centering()

## Forces both the sprite asset and collision box to align perfectly centered 
## around Vector2.ZERO (the root Node2D global origin).
func enforce_strict_centering() -> void:
	if not sprite or not sprite.texture or not collision_shape:
		return
		
	# FORCE overrides in case the Grid initialization script changed them
	sprite.centered = true
	sprite.position = Vector2.ZERO
	
	var tex_size: Vector2 = sprite.texture.get_size()
	var scaled_size: Vector2 = tex_size * sprite.scale
	
	# Create a clean rectangle shape matching the scaled footprint dimensions
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = scaled_size
	collision_shape.shape = rect_shape
	
	# Since sprite is strictly centered, collision sits exactly at the node origin
	collision_shape.position = Vector2.ZERO

func _process(_delta: float) -> void:
	if is_dragging:
		# Enforce centering continuously while dragging to prevent mid-loop offsets
		if sprite and not sprite.centered:
			enforce_strict_centering()
			
		# This guarantees the absolute center (Node2D origin) locks onto the mouse tip
		global_position = get_global_mouse_position()

func _on_main_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("[SMOOTHIE] Picked up. global_pos=", global_position, " collision_size=", collision_shape.shape.size if collision_shape.shape else "NO SHAPE")
			is_dragging = true
			z_index = 100
			global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
			print("[SMOOTHIE] Released at global_pos=", global_position)
			attempt_delivery_drop.call_deferred()

## Checks for intersection with tracking targets over the delivery counters
func attempt_delivery_drop() -> void:
	var overlapping_areas = main_click_area.get_overlapping_areas()
	print("[SMOOTHIE] attempt_delivery_drop — overlapping areas: ", overlapping_areas.size())
	for area in overlapping_areas:
		print("[SMOOTHIE]   area name='", area.name, "' parent='", area.get_parent().name, "'")

	for area in overlapping_areas:
		if area.has_meta("customer_id"):
			var customer_id: int = area.get_meta("customer_id", -1)
			print("[SMOOTHIE] Delivered to customer_id=", customer_id, " ingredients=", accumulated_ingredients.size())
			var order_control = get_tree().get_first_node_in_group("order_manager")
			print("[SMOOTHIE] order_control found: ", order_control)
			if order_control and order_control.has_method("receive_smoothie_delivery"):
				order_control.receive_smoothie_delivery(accumulated_ingredients, customer_id)
			smoothie_delivered.emit(accumulated_ingredients)
			queue_free()
			return

	print("[SMOOTHIE] No CustomerDeliveryZone overlap — returning to spawn")
	return_to_spawn()

func return_to_spawn() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", spawn_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	z_index = 0
