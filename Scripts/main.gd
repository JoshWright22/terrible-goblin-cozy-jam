extends Node2D

var select = -1

var menus : Array = [ #simple list of menus FROM the main title card, honestly these are stand-ins
	"Main",
	"HighScore",
	"Help",
]

func _input(event: InputEvent) -> void: #Controls mouse click on button 
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pass

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass

func changeScene():
	pass


func _on_start_butt_focus_entered() -> void:
	pass # Replace with function body.


func _on_start_butt_focus_exited() -> void:
	pass # Replace with function body.


func _on_start_butt_pressed() -> void:
	pass # Replace with function body.
