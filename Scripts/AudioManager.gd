extends Node

const _SFX := "res://Assets/sfx/kenney_interface-sounds/Audio/"

var snd_button_hover:     AudioStream = preload(_SFX + "tick_001.ogg")
var snd_button_click:     AudioStream = preload(_SFX + "click_001.ogg")
var snd_transition:       AudioStream = preload(_SFX + "maximize_003.ogg")
var snd_slider:           AudioStream = preload(_SFX + "tick_002.ogg")

var snd_fruit_pickup:     AudioStream = preload(_SFX + "drop_001.ogg")
var snd_fruit_putdown:    AudioStream = preload(_SFX + "drop_002.ogg")
var snd_fruit_land:       AudioStream = preload(_SFX + "drop_002.ogg")
var snd_fruit_rotate:     AudioStream = preload(_SFX + "drop_001.ogg")
var snd_smoothie_rotate:  AudioStream = preload(_SFX + "minimize_001.ogg")

var snd_blend_start:      AudioStream = preload(_SFX + "maximize_001.ogg")
var snd_blend_complete:   AudioStream = preload(_SFX + "confirmation_001.ogg")
var snd_smoothie_pickup:  AudioStream = preload(_SFX + "select_001.ogg")
var snd_smoothie_deliver: AudioStream = preload(_SFX + "minimize_003.ogg")
var snd_smoothie_return:  AudioStream = preload(_SFX + "back_001.ogg")

var snd_customer_arrive:  AudioStream = preload(_SFX + "bong_001.ogg")
var snd_customer_happy:   AudioStream = preload(_SFX + "confirmation_003.ogg")
var snd_customer_angry:   AudioStream = preload(_SFX + "error_006.ogg")
var snd_customer_leave:   AudioStream = preload(_SFX + "close_001.ogg")

var snd_health_gain:      AudioStream = preload(_SFX + "toggle_001.ogg")
var snd_health_lose:      AudioStream = preload(_SFX + "error_002.ogg")
var snd_game_over:        AudioStream = preload(_SFX + "error_004.ogg")
var snd_game_over_slam:   AudioStream = preload(_SFX + "error_008.ogg")

var snd_pause_open:       AudioStream = preload(_SFX + "maximize_002.ogg")
var snd_pause_close:      AudioStream = preload(_SFX + "minimize_002.ogg")

const POOL_SIZE := 10

var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0

func _ready() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)

func _play(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = _pool[_pool_idx % POOL_SIZE]
	_pool_idx += 1
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

# --- UI ---
func play_button_hover() -> void:
	_play(snd_button_hover, randf_range(0.95, 1.05), -6.0)

func play_button_click() -> void:
	_play(snd_button_click)

func play_transition() -> void:
	_play(snd_transition)

func play_slider_tick(pitch: float = 1.0) -> void:
	_play(snd_slider, pitch, -10.0)

# --- Fruit ---
func play_fruit_pickup() -> void:
	_play(snd_fruit_pickup, randf_range(0.94, 1.06))

func play_fruit_putdown() -> void:
	_play(snd_fruit_putdown, randf_range(0.94, 1.06))

func play_fruit_land() -> void:
	_play(snd_fruit_land, randf_range(0.9, 1.1))

func play_fruit_rotate() -> void:
	_play(snd_fruit_rotate, randf_range(1.3, 1.5), -4.0)

func play_smoothie_rotate() -> void:
	_play(snd_smoothie_rotate, randf_range(0.88, 1.12), -3.0)

# --- Smoothie ---
func play_blend_start() -> void:
	_play(snd_blend_start)

func play_blend_complete() -> void:
	_play(snd_blend_complete)

func play_smoothie_pickup() -> void:
	_play(snd_smoothie_pickup, randf_range(0.94, 1.06))

func play_smoothie_deliver() -> void:
	_play(snd_smoothie_deliver)

func play_smoothie_return() -> void:
	_play(snd_smoothie_return, randf_range(0.92, 1.08))

# --- Customer ---
func play_customer_arrive() -> void:
	_play(snd_customer_arrive, 0.85)

func play_customer_happy() -> void:
	_play(snd_customer_happy)

func play_customer_angry() -> void:
	_play(snd_customer_angry)

func play_customer_leave() -> void:
	_play(snd_customer_leave)

# --- Game ---
func play_health_gain() -> void:
	_play(snd_health_gain)

func play_health_lose() -> void:
	_play(snd_health_lose)

func play_game_over() -> void:
	_play(snd_game_over)

func play_game_over_slam() -> void:
	_play(snd_game_over_slam, 0.55, 2.0)

func play_pause_open() -> void:
	_play(snd_pause_open)

func play_pause_close() -> void:
	_play(snd_pause_close)
