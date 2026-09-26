extends Node2D

# Daily Slush board: today's date, the buffs and debuffs everyone gets, today's leaderboard
# and a play button. The same roll the run uses, so what's shown here is what you get

const EndlessDirector := preload("res://Scripts/endless_director.gd")
const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS := ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]
const BUFF_COLOR := Color(0.75, 0.95, 0.55)
const DEBUFF_COLOR := Color(1.0, 0.6, 0.5)
const TOP_COUNT := 5
# Stand-in leaderboard until the real Steam boards are live
const FAKE_NAMES := ["SlushQueen", "BrainFreeze99", "MangoTango", "BerryBlitz", "PeelDeal",
	"CoolRunnings", "BlendBoss", "Smoothielicious", "FrostyFingers", "ChillVibes", "PulpFiction", "IceIceBaby"]

@onready var _date_lbl: Label = $Board/DateLabel
@onready var _rules: VBoxContainer = $Board/Rules
@onready var _scores: VBoxContainer = $Board/Scores
@onready var _score_status: Label = $Board/Scores/Status
@onready var _you_lbl: Label = $Board/YouLabel
@onready var _play_btn: TextureButton = $Board/PlayButton
@onready var _back_btn: TextureButton = $BackButton

func _ready() -> void:
	AudioManager.start_menu_music()
	var date := Time.get_date_dict_from_unix_time(int(Time.get_unix_time_from_system()))
	_date_lbl.text = "%s, %s %d" % [WEEKDAYS[date.weekday], MONTHS[date.month - 1], date.day]

	var roll := EndlessDirector.daily_roll()
	_heading(_rules, "Buffs")
	for buff in roll["buffs"]:
		_rule(buff["name"], buff["text"].replace("\n", " "), BUFF_COLOR)
	_heading(_rules, "Debuffs")
	for twist in roll["debuffs"]:
		_rule(twist["name"], twist["text"], DEBUFF_COLOR)

	_you_lbl.text = "Best today %d    Streak %d" % [SaveManager.todays_daily_best(), _streak()]
	if SteamService.is_running():
		_score_status.text = "Loading..."
		SteamService.fetch_top(SteamService.daily_board(), TOP_COUNT, _show_scores)
	else:
		_show_scores(_fake_scores())

	ButtonFx.setup(_play_btn)
	_play_btn.pressed.connect(func(): AudioManager.stop_menu_music(GameManager.start_daily))
	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.daySelectScene)
	)
	BoardPaint.apply($Board, true, 0.15)

# The streak only counts if it reached yesterday or today
func _streak() -> int:
	var fresh := SaveManager.daily_date in [GameManager.daily_seed(), GameManager.daily_seed(1)]
	return SaveManager.daily_streak if fresh else 0

func _heading(box: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 52)
	box.add_child(lbl)
	BoardPaint.style(lbl, true, false)

# "Tip Jar  +40% score on every smoothie", name in the buff or debuff colour
func _rule(rule_name: String, text: String, color: Color) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("normal_font_size", 36)
	lbl.text = "[color=#%s]%s[/color]  %s" % [color.to_html(false), rule_name, text]
	_rules.add_child(lbl)
	BoardPaint.style(lbl, false, false)

# Same made-up board all day, with your best today slotted in
func _fake_scores() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameManager.daily_seed()
	var names: Array = FAKE_NAMES.duplicate()
	var entries: Array = []
	var score := rng.randi_range(18000, 30000)
	for i in TOP_COUNT:
		var index := rng.randi_range(0, names.size() - 1)
		entries.append({"name": names.pop_at(index), "score": score})
		score -= rng.randi_range(800, 4000)
	var mine := SaveManager.todays_daily_best()
	if mine > 0:
		entries.append({"name": "You", "score": mine})
		entries.sort_custom(func(a, b): return a["score"] > b["score"])
		entries = entries.slice(0, TOP_COUNT)
	for i in entries.size():
		entries[i]["rank"] = i + 1
	return entries

func _show_scores(rows: Array) -> void:
	if not is_instance_valid(_score_status):
		return
	_score_status.text = "No scores yet today, be the first!" if rows.is_empty() else ""
	_score_status.visible = rows.is_empty()
	for row in rows:
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var name_lbl := Label.new()
		name_lbl.text = "%d. %s" % [row["rank"], row["name"]]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var score_lbl := Label.new()
		score_lbl.text = str(row["score"])
		for lbl in [name_lbl, score_lbl]:
			lbl.add_theme_font_size_override("font_size", 42)
			line.add_child(lbl)
		_scores.add_child(line)
		for lbl in [name_lbl, score_lbl]:
			BoardPaint.style(lbl, false, false)
