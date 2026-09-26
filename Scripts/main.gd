extends Node2D

var currentScene

var _transition_rect: ColorRect = null
var _transition_mat: ShaderMaterial = null
var _transitioning: bool = false

# Strawberry, mango, blueberry, banana, apple
const SMOOTHIE_COLORS: Array[Color] = [
	Color(0.95, 0.52, 0.58),
	Color(0.99, 0.7, 0.35),
	Color(0.55, 0.5, 0.85),
	Color(0.99, 0.87, 0.45),
	Color(0.62, 0.82, 0.45),
]

func _ready() -> void:
	add_to_group("hostController")
	_setup_transition()
	changeScene(GameManager.mainMenu)

func _setup_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	_transition_rect = ColorRect.new()
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_mat = ShaderMaterial.new()
	_transition_mat.shader = load("res://Shaders/smoothie_transition.gdshader")
	_transition_rect.material = _transition_mat
	_transition_rect.visible = false
	_transition_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_transition_rect)

func changeScene(scene) -> void:
	SaveManager.save_game()
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
	if _transitioning:
		return
	_transitioning = true
	var view := get_viewport().get_visible_rect().size
	_transition_mat.set_shader_parameter("aspect", view.x / view.y)
	_transition_mat.set_shader_parameter("juice_color", SMOOTHIE_COLORS.pick_random())
	_transition_mat.set_shader_parameter("fill", 0.0)
	_transition_rect.visible = true
	AudioManager.play_transition()

	# Smoothie pours up and covers the screen
	var tw_in := _transition_rect.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_in.tween_method(_set_fill, 0.0, 1.0, 0.45)
	await tw_in.finished

	changeScene(scene)

	# ...and carries on off the top to reveal the new scene
	var tw_out := _transition_rect.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_out.tween_interval(0.08)
	tw_out.tween_method(_set_fill, 1.0, 2.0, 0.5)
	await tw_out.finished
	_transition_rect.visible = false
	_transitioning = false

func _set_fill(value: float) -> void:
	_transition_mat.set_shader_parameter("fill", value)
