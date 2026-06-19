extends CanvasLayer

signal resume_requested

@onready var _resume_btn:   TextureButton = $ButtonBox/ResumeButton
@onready var _exit_btn:     TextureButton = $ButtonBox/ExitButton
@onready var _dimmer:       ColorRect     = $Dimmer
@onready var _bg:           Sprite2D      = $BgSprite
@onready var _label:        Label         = $PausedLabel
@onready var _btn_box:      VBoxContainer = $ButtonBox

const BG_SCALE := Vector2(0.45, 0.45)

var _closing := false

func _ready() -> void:
	_setup_btn(_resume_btn)
	_setup_btn(_exit_btn)
	_play_in()

func _setup_btn(btn: TextureButton) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.mouse_entered.connect(func(): _hover_in(btn))
	btn.mouse_exited.connect(func(): _hover_out(btn))
	btn.button_down.connect(func(): _press(btn))
	btn.button_up.connect(func(): _release(btn))

# ---------- Animations ----------

func _play_in() -> void:
	AudioManager.play_pause_open()
	_dimmer.modulate.a    = 0.0
	_bg.scale             = Vector2.ZERO
	_btn_box.modulate.a   = 0.0
	_label.modulate.a     = 0.0

	# Background pops in
	var tw := create_tween()
	tw.tween_property(_dimmer, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_bg, "scale", BG_SCALE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Label and buttons fade in after background
	var tw2 := create_tween()
	tw2.tween_interval(0.16)
	tw2.tween_property(_label, "modulate:a", 1.0, 0.14)
	tw2.parallel().tween_property(_btn_box, "modulate:a", 1.0, 0.14)

func _play_out(callback: Callable) -> void:
	AudioManager.play_pause_close()
	var tw := create_tween()
	tw.tween_property(_btn_box, "modulate:a", 0.0, 0.1)
	tw.parallel().tween_property(_label, "modulate:a", 0.0, 0.1)
	tw.tween_property(_bg, "scale", Vector2.ZERO, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_dimmer, "modulate:a", 0.0, 0.15)
	tw.finished.connect(callback)

# Called by HUD when ESC is pressed while paused
func request_close() -> void:
	if _closing:
		return
	_closing = true
	_play_out(func(): resume_requested.emit())

# ---------- Hover / press ----------

func _hover_in(btn: TextureButton) -> void:
	AudioManager.play_button_hover()
	btn.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", Vector2(1.18, 1.18), 0.45)

func _hover_out(btn: TextureButton) -> void:
	btn.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.35)

func _press(btn: TextureButton) -> void:
	AudioManager.play_button_click()
	btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", Vector2(1.07, 0.84), 0.07)

func _release(btn: TextureButton) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.9, 1.18), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.38) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# ---------- Button handlers ----------

func _on_resume_button_pressed() -> void:
	if _closing:
		return
	_closing = true
	_play_out(func(): resume_requested.emit())

func _on_exit_button_pressed() -> void:
	if _closing:
		return
	_closing = true
	_play_out(func():
		get_tree().paused = false
		GameManager.paused = false
		get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
	)
