extends Node2D

var currentScene

var _transition_rect: ColorRect = null
var _screen_w: float = 1920.0

func _ready() -> void:
	add_to_group("hostController")
	_setup_transition()
	changeScene(GameManager.mainMenu)

func _setup_transition() -> void:
	_screen_w = get_viewport().get_visible_rect().size.x

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0.08, 0.05, 0.12)
	_transition_rect.size = get_viewport().get_visible_rect().size
	_transition_rect.position = Vector2(-_screen_w, 0)
	layer.add_child(_transition_rect)

func changeScene(scene) -> void:
	var instance = scene.instantiate()
	if get_child_count() >= 1 and scene != GameManager.pauseScene:
		# skip index 0 which is the CanvasLayer (transition overlay)
		for i in range(get_child_count()):
			var c = get_child(i)
			if c is CanvasLayer:
				continue
			c.queue_free()
	add_child(instance)

func transition_to_scene(scene) -> void:
	AudioManager.play_transition()
	# Swipe in from the right
	_transition_rect.position.x = _screen_w
	var tw_in := _transition_rect.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tw_in.tween_property(_transition_rect, "position:x", 0.0, 0.28)
	await tw_in.finished

	changeScene(scene)

	# Swipe out to the left
	AudioManager.play_transition()
	var tw_out := _transition_rect.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tw_out.tween_property(_transition_rect, "position:x", -_screen_w, 0.28)
	await tw_out.finished
