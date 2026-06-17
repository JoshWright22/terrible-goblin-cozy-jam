extends Node2D

@onready var menuText = $menuButt/RichTextLabel
@onready var retryText = $menuButt2/RichTextLabel

func _ready() -> void:
	GameManager.paused = true


func _on_button_button_down() -> void:
	get_tree().call_group("hostController", "changeScene", GameManager.mainMenu)
	queue_free()


func _on_button_mouse_entered() -> void:
	menuText.modulate = Color(0.557, 0.514, 0.0)


func _on_button_mouse_exited() -> void:
	menuText.modulate = Color()


func _on_retry_butt_button_down() -> void: #rety 
	get_tree().call_group("hostController", "changeScene", GameManager.gameLoop)
	queue_free()


func _on_retry_butt_mouse_entered() -> void:
	retryText.modulate = Color(0.557, 0.514, 0.0)


func _on_retry_butt_mouse_exited() -> void:
	retryText.modulate = Color()
