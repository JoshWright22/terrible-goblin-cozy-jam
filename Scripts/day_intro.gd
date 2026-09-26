extends Control

# Short card shown before days 2+ (day 1 uses the full tutorial)

@onready var _panel: Sprite2D = $BgSprite
@onready var _day_lbl: Label = $DayLabel
@onready var _title_lbl: Label = $TitleLabel
@onready var _intro_lbl: Label = $IntroLabel
@onready var _goal_box: HBoxContainer = $GoalBox
@onready var _start_btn: TextureButton = $StartButton

var _closing: bool = false

func _ready() -> void:
	GameManager.paused = true
	var day: DayConfig = GameManager.current_day
	_day_lbl.text = "DAY %d" % day.day_number
	_title_lbl.text = day.title
	_intro_lbl.text = day.intro_text
	if day.day_number > 1 and day.blender_count > GameManager.load_day(day.day_number - 1).blender_count:
		_intro_lbl.text += "\nA new blender is open!"
	_goal_box.add_child(BoardPaint.star_row([BoardPaint.STAR, "%d / %d / %d points" % [day.star_scores[0], day.star_scores[1], day.star_scores[2]]], 52, true))
	BoardPaint.apply(self, true, 0.25)
	BoardPaint.paint_tree(_goal_box, 0.7, false)
	BoardPaint.paint_tree(_start_btn, 0.85, false)
	ButtonFx.setup(_start_btn)
	_start_btn.pressed.connect(_close)
	_play_in()

func _play_in() -> void:
	var base := _panel.scale
	_panel.scale = Vector2.ZERO
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_panel, "scale", base, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	if _closing:
		return
	_closing = true
	GameManager.paused = false
	var tw := create_tween()
	tw.tween_property(self, "position:x", -get_viewport_rect().size.x - 50.0, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		var parent = get_parent()
		if parent is CanvasLayer:
			parent.queue_free()
		else:
			queue_free()
	)
