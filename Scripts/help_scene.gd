extends Node2D

var page : int = 1


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func changePage(pages):
	pass


func _on_button_2_button_down() -> void:
	page = page + 1 
	page = clamp(page, 1, 2)
	changePage(page)


func _on_button_button_down() -> void:
	print("left")
