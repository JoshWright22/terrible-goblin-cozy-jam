extends Node2D

# --- Button scales ---
const BASE_SCALE  := Vector2(0.5,   0.5)
const HOVER_SCALE := Vector2(0.545, 0.545)
const PRESS_SCALE := Vector2(0.45,  0.45)

@export var bpm: float = 120.0
const MUSIC_FADE_IN_TIME  := 1.5
const MUSIC_FADE_OUT_TIME := 0.18

@onready var _buttons: Array[TextureButton] = [
	$uiControl/TextureButton,
	$uiControl/TextureButton2,
	$uiControl/TextureButton3,
]
@onready var _bg:         Sprite2D         = $BgSprite
@onready var _title:      Sprite2D         = $TitleSprite
@onready var _blender:    Sprite2D         = $BlenderSprite
@onready var _lid:        Sprite2D         = $LidSprite
@onready var _fruits: Array[Sprite2D] = [
	$Fruit1, $Fruit2, $Fruit3, $Fruit4, $Fruit5, $Fruit6, $Fruit7,
]
@onready var _ui_control: Control          = $uiControl
@onready var _music:      AudioStreamPlayer = $MusicPlayer
@onready var _beat_timer: Timer             = $BeatTimer

var _float_time: float  = 0.0
var _float_blend: float = 0.0          # 0→1 ramp after intro, prevents phase-jump snap
var _float_origins: Dictionary = {}
var _float_params: Array = []
var _intro_done: bool = false

var _title_base_scale: Vector2

func _ready() -> void:
	for btn in _buttons:
		btn.mouse_entered.connect(_hover_in.bind(btn))
		btn.mouse_exited.connect(_hover_out.bind(btn))
		btn.button_down.connect(_press.bind(btn))
	$uiControl/TextureButton.button_up.connect(_on_start_released)
	$uiControl/TextureButton2.button_up.connect(_on_settings_released)
	$uiControl/TextureButton3.button_up.connect(_on_credits_released)

	_register_float(_title,   7.0,  3.2, 0.0,  false)
	_register_float(_blender, 5.0,  4.1, 0.3,  false)
	_register_float(_lid,     6.0,  3.6, 0.15, true)
	var phases  := [0.10, 0.40, 0.62, 0.22, 0.75, 0.50, 0.85]
	var amps    := [8.0,  10.0, 6.0,  9.0,  5.0,  11.0, 7.0]
	var periods := [3.5,  2.8,  4.3,  3.1,  3.9,  2.6,  4.5]
	for i in range(_fruits.size()):
		_register_float(_fruits[i], amps[i], periods[i], phases[i], false)

	_title_base_scale = _title.scale
	_play_intro()

func _register_float(spr: Sprite2D, amp: float, period: float, phase: float, clamp_below: bool) -> void:
	_float_origins[spr] = spr.position
	_float_params.append({
		"node": spr, "amp": amp, "period": period,
		"phase": phase, "clamp_below": clamp_below
	})

# Two-phase fly-in: fast QUART arrival → short BACK settle.
# travel_dir is the normalised direction FROM start TOWARD target.
func _fly_in(node: Node2D, target: Vector2, delay: float, dur: float,
		overshoot_px: float, travel_dir: Vector2) -> void:
	var past := target + travel_dir * overshoot_px   # just past target
	var tw := create_tween()
	tw.tween_interval(delay)
	# Phase 1 – fast, smooth deceleration to just-past-target
	tw.tween_property(node, "position", past, dur * 0.80) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Phase 2 – short, clean settle back to exact target
	tw.tween_property(node, "position", target, dur * 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func _play_intro() -> void:
	const SW    := 1920.0
	const SH    := 1080.0
	const DUR   := 0.58
	const OVER  := 16.0   # overshoot pixels

	# Background fades in first
	_bg.modulate.a = 0.0
	_ui_control.modulate.a = 0.0
	create_tween().tween_property(_bg, "modulate:a", 1.0, 0.45)

	# Blender + lid from the right
	var bl_orig: Vector2 = _float_origins[_blender]
	var li_orig: Vector2 = _float_origins[_lid]
	_blender.position.x = bl_orig.x + SW
	_lid.position.x     = li_orig.x + SW
	_fly_in(_blender, bl_orig, 0.08, DUR, OVER, Vector2(-1, 0))
	_fly_in(_lid,     li_orig, 0.08, DUR, OVER, Vector2(-1, 0))

	# Fruits from scattered directions
	var offsets: Array[Vector2] = [
		Vector2(-SW,       0),
		Vector2( SW,       0),
		Vector2(  0,      SH),
		Vector2(-SW,  -SH * 0.45),
		Vector2( SW,   SH * 0.45),
		Vector2(  0,     -SH),
		Vector2(-SW * 0.55, SH),
	]
	for i in range(_fruits.size()):
		var orig: Vector2 = _float_origins[_fruits[i]]
		var off: Vector2  = offsets[i]
		_fruits[i].position = orig + off
		_fly_in(_fruits[i], orig, 0.04 + i * 0.07, DUR, OVER, -off.normalized())

	# Title drops from above — last, for drama
	var ti_orig: Vector2 = _float_origins[_title]
	_title.position.y = ti_orig.y - SH
	_fly_in(_title, ti_orig, 0.32, 0.68, 22.0, Vector2(0, 1))

	# Buttons fade in after everything lands
	var ui_tw := create_tween()
	ui_tw.tween_interval(0.88)
	ui_tw.tween_property(_ui_control, "modulate:a", 1.0, 0.3)

	# Wait for all tweens then start float + music
	await get_tree().create_timer(1.15).timeout
	_intro_done = true

	_beat_timer.wait_time = 60.0 / bpm
	_beat_timer.start()

	AudioManager.start_menu_music(MUSIC_FADE_IN_TIME)

func _process(_delta: float) -> void:
	if not _intro_done:
		return
	_float_time  += _delta
	# Ramp float amplitude 0→1 over 1.2 s to dissolve any phase-offset snap
	_float_blend = minf(1.0, _float_blend + _delta / 1.2)

	for p in _float_params:
		var spr: Sprite2D = p["node"]
		var orig: Vector2 = _float_origins[spr]
		var t: float = _float_time / float(p["period"]) + float(p["phase"])
		var y_off := sin(t * TAU) * float(p["amp"]) * _float_blend
		if p["clamp_below"]:
			y_off = minf(0.0, y_off)
		spr.position.y = orig.y + y_off
		if spr != _title:
			spr.position.x = orig.x + cos(t * TAU * 0.65) * p["amp"] * 0.22 * _float_blend

func _on_beat_timer_timeout() -> void:
	var tw := _title.create_tween()
	tw.tween_property(_title, "scale", _title_base_scale * Vector2(1.0, 0.88), 0.05)
	tw.tween_property(_title, "scale", _title_base_scale * Vector2(1.0, 1.06), 0.09)
	tw.tween_property(_title, "scale", _title_base_scale, 0.13) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fade_music_then(callback: Callable) -> void:
	AudioManager.stop_menu_music(callback, MUSIC_FADE_OUT_TIME)

func _hover_in(btn: TextureButton) -> void:
	AudioManager.play_button_hover()
	btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", HOVER_SCALE, 0.18)

func _hover_out(btn: TextureButton) -> void:
	btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", BASE_SCALE, 0.18)

func _press(btn: TextureButton) -> void:
	AudioManager.play_button_click()
	btn.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.tween_property(btn, "scale", PRESS_SCALE, 0.06)

func _quick_release_then(btn: TextureButton, callback: Callable, fade_music: bool = true) -> void:
	var tw := btn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", BASE_SCALE, 0.05)
	if fade_music:
		tw.finished.connect(func(): _fade_music_then(callback))
	else:
		tw.finished.connect(callback)

func _on_start_released() -> void:
	_quick_release_then($uiControl/TextureButton, func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.gameLoop)
	)

func _on_settings_released() -> void:
	_quick_release_then($uiControl/TextureButton2, func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.settingsScene)
	, false)

func _on_credits_released() -> void:
	_quick_release_then($uiControl/TextureButton3, func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.creditsScene)
	, false)

func _on_texture_button_button_down() -> void:
	pass

func _on_texture_button_2_button_down() -> void:
	pass

func _on_texture_button_3_button_down() -> void:
	pass
