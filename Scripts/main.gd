extends Node2D

var currentScene #setter variable for changeScene()

#scenes
@onready var mainMenu = load("res://Scenes/main_menu.tscn")


func _ready() -> void:
	changeScene(mainMenu) 
func _process(delta: float) -> void:
	pass


func changeScene(scene) -> void:  #changes scene with input 'scene' based off of #scenes
	currentScene = scene
	var instance
	if get_child_count() >= 1:
		get_child(0).queue_free()
	instance = currentScene.instantiate()
	add_child(instance)
