extends Node

const SAVE_PATH := "user://save.cfg"

# Settings
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var screen_shake: bool = true
var mute_unfocused: bool = false   # desktop only: go quiet when the window loses focus

# Progress
var unlocked_days: Dictionary = {}  # campaign id -> highest playable day
var day_stars: Dictionary = {}      # "campaign:day" -> best stars (0-3)
var endless_best: int = 0
var daily_best: int = 0      # best score on daily_date
var daily_date: int = 0      # YYYYMMDD of the last daily played
var daily_streak: int = 0    # days in a row with a daily played

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
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mute_unfocused:
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)

func save_game() -> void:
	# The settings sliders write straight to the buses, so read the volumes back from there
	music_volume = _get_bus_volume("Music", music_volume)
	sfx_volume = _get_bus_volume("SFX", sfx_volume)
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "screen_shake", screen_shake)
	cfg.set_value("settings", "mute_unfocused", mute_unfocused)
	cfg.set_value("progress", "unlocked_days", unlocked_days)
	cfg.set_value("progress", "day_stars", day_stars)
	cfg.set_value("progress", "endless_best", endless_best)
	cfg.set_value("daily", "best", daily_best)
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "streak", daily_streak)
	cfg.set_value("style", "cosmetics", cosmetics)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: couldn't save (error %d)" % err)

func load_game() -> void:
	_load_file()

func _load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # first launch, keep defaults
	music_volume = cfg.get_value("settings", "music_volume", music_volume)
	sfx_volume = cfg.get_value("settings", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	screen_shake = cfg.get_value("settings", "screen_shake", screen_shake)
	mute_unfocused = cfg.get_value("settings", "mute_unfocused", mute_unfocused)
	unlocked_days = cfg.get_value("progress", "unlocked_days", unlocked_days)
	day_stars = cfg.get_value("progress", "day_stars", day_stars)
	# Saves from before campaigns only had Summer, keyed by day number
	if cfg.has_section_key("progress", "unlocked_day"):
		unlocked_days["summer"] = maxi(unlocked_days.get("summer", 1), cfg.get_value("progress", "unlocked_day"))
	for key in day_stars.keys():
		if key is int:
			day_stars["summer:%d" % key] = day_stars[key]
			day_stars.erase(key)
	endless_best = cfg.get_value("progress", "endless_best", endless_best)
	daily_best = cfg.get_value("daily", "best", daily_best)
	daily_date = cfg.get_value("daily", "date", daily_date)
	daily_streak = cfg.get_value("daily", "streak", daily_streak)
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
func record_day(campaign_id: String, day: int, stars: int) -> void:
	var key := "%s:%d" % [campaign_id, day]
	day_stars[key] = maxi(day_stars.get(key, 0), stars)
	if stars > 0:
		unlocked_days[campaign_id] = maxi(unlocked_day(campaign_id), day + 1)
	save_game()

func unlocked_day(campaign_id: String) -> int:
	return unlocked_days.get(campaign_id, 1)

func stars_for(campaign_id: String, day: int) -> int:
	return day_stars.get("%s:%d" % [campaign_id, day], 0)

func campaign_stars(campaign_id: String) -> int:
	var total := 0
	for key in day_stars:
		if String(key).begins_with(campaign_id + ":"):
			total += day_stars[key]
	return total

# Returns true if this is a new best.
func record_endless_score(score: int) -> bool:
	if score <= endless_best:
		return false
	endless_best = score
	save_game()
	return true

# Returns true if this is a new best for today. The streak grows once per day played.
func record_daily_score(score: int) -> bool:
	var today := GameManager.daily_seed()
	if daily_date != today:
		daily_streak = daily_streak + 1 if daily_date == GameManager.daily_seed(1) else 1
		daily_date = today
		daily_best = 0
	var best := score > daily_best
	daily_best = maxi(daily_best, score)
	save_game()
	return best

func todays_daily_best() -> int:
	return daily_best if daily_date == GameManager.daily_seed() else 0

func total_stars() -> int:
	var total := 0
	for s in day_stars.values():
		total += s
	return total
