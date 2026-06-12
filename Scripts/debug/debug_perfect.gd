extends Node2D
var is_dragging = false #state management
var mouse_offset #center Mouse 

var completed : Dictionary


func _physics_process(delta):
	if is_dragging == true:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", get_global_mouse_position()-mouse_offset, delta)
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if $Sprite2D.get_rect().has_point(to_local(event.position)):
				is_dragging = true
				mouse_offset = get_global_mouse_position()-global_position
		else:
			is_dragging = false
			position = Vector2(814,755) #return smoothie
			if GameManager.trgID != null: #since theres a trgID; pass this Dict 
				var slushi = find_parent("orderControl").currentOrders[GameManager.trgID] #cheats to find order
				GameManager.slushiData(slushi)
				position = Vector2(814,755) #return smoothie
 	
