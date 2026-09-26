extends Node

const SAVE_PATH := "user://save.cfg"

# Settings
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false

# Progress
var unlocked_day: int = 1
var day_stars: Dictionary = {}  # day number -> best stars (0-3)
var endless_best: int = 0

# Style unlocks: category -> chosen option index (see Cosmetics)
var cosmetics: Dictionary = {}

func _ready() -> void:
	load_game()
	apply_audio()
	apply_window()

func can_toggle_fullscreen() -> bool:
	return not OS.has_feature("mobile") and not OS.has_feature("web")

# Only touches the window when fullscreen is on (or being turned off), so the project's default window stays as set
func apply_window(was_fullscreen: bool = false) -> void:
	if not can_toggle_fullscreen():
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif was_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _notification(what: int) -> void:
	# Android can kill the app while it's in the background, so save on the way out
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func save_game() -> void:
	# The settings sliders write straight to the buses, so read the volumes back from there
	music_volume = _get_bus_volume("Music", music_volume)
	sfx_volume = _get_bus_volume("SFX", sfx_volume)
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "auto_show_orders", GameManager.auto_show_orders)
	cfg.set_value("settings", "change_order_on_anger", GameManager.change_order_on_anger)
	cfg.set_value("progress", "unlocked_day", unlocked_day)
	cfg.set_value("progress", "day_stars", day_stars)
	cfg.set_value("progress", "endless_best", endless_best)
	cfg.set_value("style", "cosmetics", cosmetics)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: couldn't save (error %d)" % err)

func load_game() -> void:
	_load_file()
	# No hover on touch screens, so orders always show
	if OS.has_feature("mobile"):
		GameManager.auto_show_orders = true

func _load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # first launch, keep defaults
	music_volume = cfg.get_value("settings", "music_volume", music_volume)
	sfx_volume = cfg.get_value("settings", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	GameManager.auto_show_orders = cfg.get_value("settings", "auto_show_orders", GameManager.auto_show_orders)
	GameManager.change_order_on_anger = cfg.get_value("settings", "change_order_on_anger", GameManager.change_order_on_anger)
	unlocked_day = cfg.get_value("progress", "unlocked_day", unlocked_day)
	day_stars = cfg.get_value("progress", "day_stars", day_stars)
	endless_best = cfg.get_value("progress", "endless_best", endless_best)
	cosmetics = cfg.get_value("style", "cosmetics", cosmetics)

func apply_audio() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

func _get_bus_volume(bus_name: String, fallback: float) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return fallback
	var db := AudioServer.get_bus_volume_db(idx)
	return db_to_linear(db) if db > -60.0 else 0.0

func _set_bus_volume(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value) if value > 0.0 else -80.0)

# Called when a campaign day ends. Keeps the best stars and unlocks the next day.
func record_day(day: int, stars: int) -> void:
	day_stars[day] = maxi(day_stars.get(day, 0), stars)
	if stars > 0:
		unlocked_day = maxi(unlocked_day, day + 1)
	save_game()

# Returns true if this is a new best.
func record_endless_score(score: int) -> bool:
	if score <= endless_best:
		return false
	endless_best = score
	save_game()
	return true

func total_stars() -> int:
	var total := 0
	for s in day_stars.values():
		total += s
	return total
