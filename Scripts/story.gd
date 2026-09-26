class_name Story

# Reads Story/story.txt, the editable day titles, intro cards and tutorial steps.
# See the notes at the top of that file for the format.

const PATH := "res://Story/story.txt"
const CAMPAIGN_IDS := {"summer": "summer", "carnival": "boardwalk"}   # header name -> campaign id

static var _days: Dictionary = {}      # "summer:1" -> {"title": ..., "intro": ...}
static var _tutorial: Array = []
static var _loaded := false

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_warning("Story: couldn't open %s, using built-in text" % PATH)
		return
	var section := ""
	var lines: Array = []
	for raw in file.get_as_text().split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("#"):
			continue
		if line.begins_with("["):
			_store(section, lines)
			section = line
			lines = []
		elif line != "":
			lines.append(line)
	_store(section, lines)

static func _store(header: String, lines: Array) -> void:
	if header == "" or lines.is_empty():
		return
	if header.begins_with("[tutorial]"):
		_tutorial = lines
		return
	# "[summer 3] Odd Shapes"
	var close := header.find("]")
	var parts := header.substr(1, close - 1).split(" ", false)
	if parts.size() != 2 or not CAMPAIGN_IDS.has(parts[0]):
		push_warning("Story: skipped unknown header %s" % header)
		return
	var key := "%s:%d" % [CAMPAIGN_IDS[parts[0]], int(parts[1])]
	_days[key] = {"title": header.substr(close + 1).strip_edges(), "intro": " ".join(lines)}

# Overwrites each day's title and intro with the file's version where it has one
static func apply(campaign: Campaign) -> void:
	_load()
	for day in campaign.days:
		var entry: Dictionary = _days.get("%s:%d" % [campaign.id, day.day_number], {})
		if entry.get("title", "") != "":
			day.title = entry["title"]
		if entry.get("intro", "") != "":
			day.intro_text = entry["intro"]

# Tutorial step text, falling back to the built-in line if the file doesn't have that step
static func tutorial_step(index: int, fallback: String, touch: bool = false) -> String:
	_load()
	if index >= _tutorial.size():
		return fallback
	var options: PackedStringArray = str(_tutorial[index]).split("||")
	if touch and options.size() > 1:
		return options[1].strip_edges()
	return options[0].strip_edges()
