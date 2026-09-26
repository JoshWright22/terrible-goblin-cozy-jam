extends Node

# Steam achievements, leaderboards, rich presence and overlay pause through GodotSteam.
# Steam is looked up at runtime, so the game runs exactly the same without the GodotSteam
# extension, on Android, on the web, or when Steam isn't running. Every call is then a no-op.

signal overlay_opened

# 480 is Valve's test app (Spacewar). Swap in the real app ID once the Steam page exists.
const APP_ID := 480

const ACH_FIRST_SMOOTHIE := "FIRST_SMOOTHIE"
const ACH_SUMMER_DONE := "SUMMER_DONE"
const ACH_SUMMER_PERFECT := "SUMMER_PERFECT"       # 3 stars on every Summer day
const ACH_BOARDWALK_DONE := "BOARDWALK_DONE"
const ACH_ROGUE_10K := "ROGUE_10K"
const ACH_ROGUE_25K := "ROGUE_25K"
const ACH_DAILY_WEEK := "DAILY_WEEK"               # Daily Slush 7 days in a row

const BOARD_ROGUELIKE := "roguelike_best"
const LEADERBOARD_SORT_DESCENDING := 2
const LEADERBOARD_DISPLAY_NUMERIC := 1

var _steam: Object = null
var _boards: Dictionary = {}          # leaderboard name -> handle
var _pending_scores: Dictionary = {}  # leaderboard name -> score waiting for its handle

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web") or not Engine.has_singleton("Steam"):
		return
	var steam := Engine.get_singleton("Steam")
	var result: Dictionary = steam.call("steamInitEx", APP_ID, true)
	if result.get("status", -1) != 0:
		push_warning("Steam didn't start (%s), playing offline" % result.get("verbal", "unknown"))
		return
	_steam = steam
	_steam.connect("overlay_toggled", _on_overlay_toggled)
	_steam.connect("leaderboard_find_result", _on_leaderboard_found)

func is_running() -> bool:
	return _steam != null

func unlock(achievement: String) -> void:
	if _steam == null:
		return
	_steam.call("setAchievement", achievement)
	_steam.call("storeStats")

# Keeps the player's best. Daily Slush gets its own board per day, e.g. "daily_20260926"
func submit_score(board: String, score: int) -> void:
	if _steam == null:
		return
	if _boards.has(board):
		_steam.call("uploadLeaderboardScore", score, true, PackedInt32Array(), _boards[board])
		return
	_pending_scores[board] = maxi(score, _pending_scores.get(board, 0))
	_steam.call("findOrCreateLeaderboard", board, LEADERBOARD_SORT_DESCENDING, LEADERBOARD_DISPLAY_NUMERIC)

func daily_board() -> String:
	return "daily_%d" % GameManager.daily_seed()

# What friends see next to the player's name, e.g. "Summer, Day 7"
func set_status(text: String) -> void:
	if _steam != null:
		_steam.call("setRichPresence", "status", text)

func _on_leaderboard_found(handle: int, found: int) -> void:
	if found == 0:
		return
	# Handles come back in request order, so match the oldest pending board
	for board in _pending_scores.keys():
		if not _boards.has(board):
			_boards[board] = handle
			var score: int = _pending_scores[board]
			_pending_scores.erase(board)
			_steam.call("uploadLeaderboardScore", score, true, PackedInt32Array(), handle)
			return

func _on_overlay_toggled(active: bool, _user_initiated: bool, _app_id: int) -> void:
	if active:
		overlay_opened.emit()
