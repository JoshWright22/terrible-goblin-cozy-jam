extends Node2D

var currentScene #setter variable for changeScene()





func _ready() -> void:
	changeScene(GameManager.mainMenu) 






func changeScene(scene) -> void:  #changes scene with input 'scene' based off of #scenes
	var instance = scene.instantiate()
	print("pass")
	if get_child_count() >= 1 && scene != GameManager.pauseScene:
		get_child(0).queue_free()
	print(instance)
	add_child(instance)
