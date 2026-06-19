extends CanvasLayer

@onready var _retry_btn:    TextureButton = $ButtonBox/RetryButton
@onready var _exit_btn:     TextureButton = $ButtonBox/ExitButton
@onready var _score_lbl:    Label         = $ScoreLabel
@onready var _title_lbl:    Label         = $GameOverLabel
@onready var _bg_sprite:    Sprite2D      = $BgSprite
@onready var _dimmer:       ColorRect     = $Dimmer
@onready var _btn_box:      VBoxContainer = $ButtonBox

func _ready() -> void:
	_score_lbl.text = "Score: %d" % GameManager.score
	_apply_label_style(_title_lbl, 7)
	_apply_label_style(_score_lbl, 5)
	_setup_btn(_retry_btn)
	_setup_btn(_exit_btn)
	_play_entrance()

func _apply_label_style(lbl: Label, outline: int) -> void:
	lbl.add_theme_constant_override("outline_size", outline)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("shadow_offset_x", 4)
	lbl.add_theme_constant_override("shadow_offset_y", 5)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))

func _play_entrance() -> void:
	var orig_bg := _bg_sprite.scale

	# Hide everything to start
	_dimmer.modulate.a = 0.0
	_bg_sprite.scale = Vector2.ZERO
	_title_lbl.modulate.a = 0.0
	_title_lbl.position.y -= 120.0
	_score_lbl.modulate.a = 0.0
	_btn_box.modulate.a = 0.0
	_btn_box.position.y += 80.0

	var tw := create_tween()

	# 1. Dim the background
	tw.tween_property(_dimmer, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Panel slams in with squash bounce
	tw.tween_callback(AudioManager.play_game_over_slam)
	tw.tween_property(_bg_sprite, "scale", orig_bg * Vector2(1.2, 0.8), 0.1) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bg_sprite, "scale", orig_bg * Vector2(0.85, 1.16), 0.08)
	tw.tween_property(_bg_sprite, "scale", orig_bg * Vector2(1.07, 0.94), 0.07)
	tw.tween_property(_bg_sprite, "scale", orig_bg, 0.06) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 3. "GAME OVER" crashes down
	tw.tween_property(_title_lbl, "modulate:a", 1.0, 0.01)
	tw.tween_property(_title_lbl, "position:y", _title_lbl.position.y + 120.0, 0.1) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	# Squash on impact
	tw.tween_property(_title_lbl, "scale", Vector2(1.3, 0.55), 0.06)
	tw.tween_property(_title_lbl, "scale", Vector2(0.75, 1.4), 0.07)
	tw.tween_property(_title_lbl, "scale", Vector2(1.1, 0.88), 0.06)
	tw.tween_property(_title_lbl, "scale", Vector2(1.0, 1.0), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Shake the whole screen briefly
	tw.tween_method(_screen_shake, 0.0, 1.0, 0.3)

	# 4. Score pops in
	tw.tween_property(_score_lbl, "modulate:a", 1.0, 0.01)
	tw.tween_property(_score_lbl, "scale", Vector2(1.5, 1.5), 0.0)
	tw.tween_property(_score_lbl, "scale", Vector2(1.0, 1.0), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_score_lbl, "modulate:a", 1.0, 0.15)

	tw.tween_interval(0.05)

	# 5. Buttons slide up and fade in
	tw.tween_property(_btn_box, "position:y", _btn_box.position.y - 80.0, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_btn_box, "modulate:a", 1.0, 0.2)

var _shake_origin: Vector2 = Vector2.ZERO
var _shake_started: bool = false

func _screen_shake(t: float) -> void:
	if not _shake_started:
		_shake_origin = _bg_sprite.position
		_shake_started = true
	var amp := 14.0 * (1.0 - t)
	_bg_sprite.position = _shake_origin + Vector2(sin(t * PI * 11.0) * amp, cos(t * PI * 7.0) * amp * 0.5)

func _setup_btn(btn: TextureButton) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	btn.mouse_entered.connect(func(): _hover_in(btn))
	btn.mouse_exited.connect(func(): _hover_out(btn))
	btn.button_down.connect(func(): _press(btn))
	btn.button_up.connect(func(): _release(btn))

func _hover_in(btn: TextureButton) -> void:
	AudioManager.play_button_hover()
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hover_out(btn: TextureButton) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _press(btn: TextureButton) -> void:
	AudioManager.play_button_click()
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _release(btn: TextureButton) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	GameManager.paused = false
	GameManager.game_over = false
	get_tree().call_group("hostController", "transition_to_scene", GameManager.gameLoop)

func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	GameManager.paused = false
	GameManager.game_over = false
	get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
