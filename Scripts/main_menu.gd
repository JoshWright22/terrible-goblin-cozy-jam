extends Node2D



func _ready() -> void:
	pass 



func _on_texture_button_button_down() -> void: #gameloop
	get_tree().call_group("hostController", "changeScene", GameManager.gameLoop)


func _on_texture_button_2_button_down() -> void: #settings
	pass # Replace with function body.


func _on_texture_button_3_button_down() -> void: #credits
	get_tree().call_group("hostController", "changeScene", GameManager.creditsScene)
