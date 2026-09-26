extends CanvasLayer

# Campaign-only HUD: shop timer, live star progress, and the day's screen effects

const NIGHT_TINT := Color(0.72, 0.74, 0.95)
const POWER_ON_TIME := Vector2(9.0, 15.0)   # random range between outages
const POWER_OFF_TIME := 3.0
const FLASHLIGHT_MASK := preload("res://Shaders/flashlight_mask.gdshader")

@onready var _night: ColorRect = $NightOverlay
@onready var _outage: ColorRect = $OutageOverlay
@onready var _day_lbl: Label = $Panel/Row/DayLabel
@onready var _time_lbl: Label = $Panel/Row/TimeLabel
@onready var _stars: Array[StarIcon] = [$Panel/Row/Star1, $Panel/Row/Star2, $Panel/Row/Star3]

var _day: DayConfig
var _control: Node = null
var _tint: CanvasModulate = null
var _power_timer: float = 0.0
var _order_mask: ShaderMaterial = null

func _ready() -> void:
	_day = GameManager.current_day
	if _day == null:
		queue_free()
		return
	_day_lbl.text = "Day %d" % _day.day_number
	var hints := _day.star_hints()
	for i in _stars.size():
		_stars[i].filled = false
		_stars[i].tooltip_text = hints[i]
		_stars[i].mouse_filter = Control.MOUSE_FILTER_PASS
		_stars[i].draw_offset.y = _time_lbl.get_theme_font_size("font_size") * BoardPaint.STAR_DROP
	_night.visible = _day.night_shift
	_outage.visible = false
	_power_timer = randf_range(POWER_ON_TIME.x, POWER_ON_TIME.y)

	# Tints the shop itself (not the UI layers) as the day goes on
	_tint = CanvasModulate.new()
	get_parent().add_child.call_deferred(_tint)

func _process(delta: float) -> void:
	if _control == null:
		_control = get_tree().get_first_node_in_group("orderControl")
		if _control == null:
			return
	var left: float = maxf(0.0, _control.day_time_left)
	_time_lbl.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
	_time_lbl.modulate = Color(1.0, 0.55, 0.45) if left < 15.0 else Color.WHITE

	var earned := _day.stars_for_score(GameManager.score)
	for i in _stars.size():
		if i < earned and not _stars[i].filled:
			_stars[i].filled = true
			_pop(_stars[i])

	var progress := 1.0 - left / _day.duration
	if is_instance_valid(_tint):
		var target := NIGHT_TINT if _day.night_shift else GameManager.current_campaign.end_tint
		_tint.color = Color.WHITE.lerp(target, clampf(progress, 0.0, 1.0))

	if _day.night_shift:
		_update_flashlight()

	if _day.power_outage and not GameManager.paused:
		_update_power(delta)

# Moves the light to the cursor and keeps every order bubble hidden outside it.
# Fruit pieces already read the same light in their own shader
func _update_flashlight() -> void:
	var view := get_viewport().get_visible_rect().size
	var light := get_viewport().get_mouse_position() / view
	RenderingServer.global_shader_parameter_set("flashlight", Vector4(light.x, light.y, view.x / view.y, 1.0))
	if _order_mask == null:
		_order_mask = ShaderMaterial.new()
		_order_mask.shader = FLASHLIGHT_MASK
	for node in get_tree().get_nodes_in_group("order_ui"):
		_mask_tree(node)

func _mask_tree(node: Node) -> void:
	if node is CanvasItem and node.material == null:
		node.material = _order_mask
	for child in node.get_children():
		_mask_tree(child)

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("flashlight", Vector4(0.5, 0.5, 1.0, 0.0))

func _update_power(delta: float) -> void:
	_power_timer -= delta
	if _power_timer > 0.0:
		if GameManager.power_out:
			# Flicker while the power is out
			_outage.color.a = 0.35 + 0.12 * sin(Time.get_ticks_msec() * 0.03)
		return
	GameManager.power_out = not GameManager.power_out
	_outage.visible = GameManager.power_out
	if GameManager.power_out:
		AudioManager.play_pause_close()
		_power_timer = POWER_OFF_TIME
	else:
		AudioManager.play_pause_open()
		_power_timer = randf_range(POWER_ON_TIME.x, POWER_ON_TIME.y)

func _pop(star: Control) -> void:
	AudioManager.play_health_gain()
	star.scale = Vector2(1.7, 1.7)
	star.create_tween().tween_property(star, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
