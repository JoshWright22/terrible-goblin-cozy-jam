extends CanvasLayer

# Shown by the HUD when a campaign day's timer runs out

@onready var _dimmer: ColorRect = $Dimmer
@onready var _bg: Sprite2D = $BgSprite
@onready var _title_lbl: Label = $TitleLabel
@onready var _score_lbl: Label = $ScoreLabel
@onready var _note_lbl: Label = $NoteLabel
@onready var _stars: Array[StarIcon] = [$Stars/Star1, $Stars/Star2, $Stars/Star3]
@onready var _next_btn: TextureButton = $ButtonBox/NextButton
@onready var _retry_btn: TextureButton = $ButtonBox/RetryButton
@onready var _menu_btn: TextureButton = $ButtonBox/MenuButton

func _ready() -> void:
	var day: DayConfig = GameManager.current_day
	var stars := day.stars_for_score(GameManager.score)
	_title_lbl.text = "Day %d done!" % day.day_number if stars > 0 else "Day %d: try again!" % day.day_number
	_score_lbl.text = "Score: %d" % GameManager.score
	_note_lbl.text = _note_for(day, stars)
	$TipLabel.text = Tips.random() if stars < 3 else ""
	var unlocked := Cosmetics.newly_unlocked(GameManager.stars_before_day, SaveManager.total_stars())
	if not unlocked.is_empty():
		# A long list wouldn't fit on the board, so name one and count the rest
		var names: String = " and ".join(unlocked)
		if unlocked.size() > 2:
			names = "%s and %d more" % [unlocked[0], unlocked.size() - 1]
		_note_lbl.text = "New style ready: %s!" % names
	var hints := day.star_hints()
	for i in _stars.size():
		_stars[i].filled = false
		_stars[i].tooltip_text = hints[i]
		_stars[i].mouse_filter = Control.MOUSE_FILTER_PASS

	_next_btn.visible = stars > 0 and GameManager.has_next_day()
	for btn in [_next_btn, _retry_btn, _menu_btn]:
		ButtonFx.setup(btn)
	_next_btn.pressed.connect(_on_next)
	_retry_btn.pressed.connect(_on_retry)
	_menu_btn.pressed.connect(_on_menu)

	BoardPaint.apply(self, true, 0.4)
	BoardPaint.paint_tree($Stars, 0.5, false)
	BoardPaint.paint_tree($ButtonBox, 0.8, false)
	_play_in(stars)

func _note_for(day: DayConfig, stars: int) -> String:
	if stars == 0:
		return "Reach %d points to open the next day" % day.star_scores[0]
	if not GameManager.has_next_day():
		return "%s complete!" % GameManager.current_campaign.title
	if stars < 3:
		return "Next goal: %d points" % day.star_scores[stars]
	return "Perfect day!"

func _play_in(stars: int) -> void:
	var bg_scale := _bg.scale
	_bg.scale = Vector2.ZERO
	_dimmer.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_dimmer, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_bg, "scale", bg_scale, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	# Stars stamp in one at a time
	for i in stars:
		var star := _stars[i]
		tw.tween_callback(func():
			star.filled = true
			star.scale = Vector2(1.6, 1.6)
			AudioManager.play_health_gain()
		)
		tw.tween_property(star, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _leave(scene) -> void:
	get_tree().paused = false
	GameManager.paused = false
	GameManager.day_complete = false
	get_tree().call_group("hostController", "transition_to_scene", scene)

func _on_next() -> void:
	GameManager.current_day = GameManager.load_day(GameManager.current_day.day_number + 1)
	_leave(GameManager.gameLoop)

func _on_retry() -> void:
	_leave(GameManager.gameLoop)

func _on_menu() -> void:
	_leave(GameManager.daySelectScene)
