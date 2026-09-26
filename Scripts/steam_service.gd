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
const LEADERBOARD_GLOBAL := 0

var _steam: Object = null
var _boards: Dictionary = {}          # leaderboard name -> handle
var _finding: Array = []              # [board name, callback] waiting on a handle, oldest first
var _downloads: Dictionary = {}       # leaderboard handle -> callbacks waiting for its entries

func _ready() -> void:
	# Only the Steam export presets carry the "steam" tag, so the itch builds never touch Steam
	var steam_build := OS.has_feature("steam") or OS.has_feature("editor")
	if not steam_build or OS.has_feature("mobile") or OS.has_feature("web") or not Engine.has_singleton("Steam"):
		return
	var steam := Engine.get_singleton("Steam")
	var result: Dictionary = steam.call("steamInitEx", APP_ID, true)
	if result.get("status", -1) != 0:
		push_warning("Steam didn't start (%s), playing offline" % result.get("verbal", "unknown"))
		return
	_steam = steam
	_steam.connect("overlay_toggled", _on_overlay_toggled)
	_steam.connect("leaderboard_find_result", _on_leaderboard_found)
	_steam.connect("leaderboard_scores_downloaded", _on_scores_downloaded)

func is_running() -> bool:
	return _steam != null

func unlock(achievement: String) -> void:
	if _steam == null:
		return
	_steam.call("setAchievement", achievement)
	_steam.call("storeStats")

# Keeps the player's best. Daily Slush gets its own board per day, e.g. "daily_20260926"
func submit_score(board: String, score: int) -> void:
	_with_board(board, func(handle: int):
		_steam.call("uploadLeaderboardScore", score, true, PackedInt32Array(), handle)
	)

# The top of a board as [{name, score, rank}], best first. Never called back without Steam
func fetch_top(board: String, count: int, on_done: Callable) -> void:
	_with_board(board, func(handle: int):
		if not _downloads.has(handle):
			_downloads[handle] = []
			_steam.call("downloadLeaderboardEntries", 1, count, LEADERBOARD_GLOBAL, handle)
		_downloads[handle].append(on_done)
	)

func _with_board(board: String, then: Callable) -> void:
	if _steam == null:
		return
	if _boards.has(board):
		then.call(_boards[board])
		return
	_finding.append([board, then])
	_steam.call("findOrCreateLeaderboard", board, LEADERBOARD_SORT_DESCENDING, LEADERBOARD_DISPLAY_NUMERIC)

func daily_board() -> String:
	return "daily_%d" % GameManager.daily_seed()

# What friends see next to the player's name, e.g. "Summer, Day 7"
func set_status(text: String) -> void:
	if _steam != null:
		_steam.call("setRichPresence", "status", text)

func _on_leaderboard_found(handle: int, found: int) -> void:
	# Handles come back in request order, so they answer the oldest request
	if _finding.is_empty():
		return
	var request: Array = _finding.pop_front()
	if found == 0:
		return
	_boards[request[0]] = handle
	request[1].call(handle)

func _on_scores_downloaded(_message: String, handle: int, entries: Array) -> void:
	var rows: Array = []
	for entry in entries:
		rows.append({
			"name": _steam.call("getFriendPersonaName", entry["steam_id"]),
			"score": entry["score"],
			"rank": entry["global_rank"],
		})
	for on_done in _downloads.get(handle, []):
		on_done.call(rows)
	_downloads.erase(handle)

func _on_overlay_toggled(active: bool, _user_initiated: bool, _app_id: int) -> void:
	if active:
		overlay_opened.emit()
