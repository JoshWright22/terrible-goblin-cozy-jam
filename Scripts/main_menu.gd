extends Node2D



func _ready() -> void:
	pass 



func _on_texture_button_button_down() -> void:
	get_tree().call_group("hostController", "changeScene", GameManager.gameLoop)
