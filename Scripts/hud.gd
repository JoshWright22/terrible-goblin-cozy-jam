extends CanvasLayer

var _pause_menu_ref: Node = null
var _game_over_ref:  Node = null
const _pause_scene     := preload("res://Scenes/pause_menu.tscn")
const _game_over_scene := preload("res://Scenes/game_over.tscn")

func _process(_delta: float) -> void:
	# HUD owns the game-over screen so it lives at the right canvas layer.
	if GameManager.game_over and not is_instance_valid(_game_over_ref):
		_game_over_ref = _game_over_scene.instantiate()
		add_child(_game_over_ref)

# _unhandled_input respects set_input_as_handled() from the help/tutorial scene,
# so closing the tutorial with ESC never also opens the pause menu.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_instance_valid(_pause_menu_ref):
		_pause_menu_ref.request_close()
		get_viewport().set_input_as_handled()
		return
	if not GameManager.game_over and not GameManager.paused:
		_do_pause()
		get_viewport().set_input_as_handled()

func _do_pause() -> void:
	GameManager.paused = true
	if not is_instance_valid(_pause_menu_ref):
		_pause_menu_ref = _pause_scene.instantiate()
		_pause_menu_ref.resume_requested.connect(_do_resume)
		add_child(_pause_menu_ref)
	get_tree().paused = true

func _do_resume() -> void:
	get_tree().paused = false
	GameManager.paused = false
	if is_instance_valid(_pause_menu_ref):
		_pause_menu_ref.queue_free()
	_pause_menu_ref = null
