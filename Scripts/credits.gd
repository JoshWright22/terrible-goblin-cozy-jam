extends Node2D

# Credits board: team, links and thanks, with fruit bobbing around the edges

const TEAM := [
	{"name": "Joshua Wright", "role": "Game design and code", "link": "https://joshwright22.github.io/", "link_text": "GitHub"},
	{"name": "Aurora (RoranArt)", "role": "Art", "link": "https://www.instagram.com/roranart/", "link_text": "Instagram"},
	{"name": "Robert Taquechel", "role": "Jam code", "link": "https://roberto-taquechel.itch.io/", "link_text": "itch.io"},
	{"name": "Jack (H4rb1nger)", "role": "Jam code"},
	{"name": "Nivadra", "role": "Music"},
]
const THANKS := "Sound effects by Kenney (kenney.nl)\nDelicious Handrawn font by the Delicious Handrawn Project Authors (OFL)\nMade for Comfy Jam: Summer 2026. Thanks for playing!"

@onready var _team_box: VBoxContainer = $Board/Team
@onready var _thanks_lbl: Label = $Board/Thanks
@onready var _back_btn: TextureButton = $BackButton
@onready var _fruits: Array[Node] = $Fruits.get_children()

var _time: float = 0.0
var _fruit_origins: Array[Vector2] = []

func _ready() -> void:
	AudioManager.start_menu_music()
	for member in TEAM:
		_team_box.add_child(_make_row(member))
	_thanks_lbl.text = THANKS
	for fruit in _fruits:
		_fruit_origins.append(fruit.position)

	ButtonFx.setup(_back_btn)
	_back_btn.pressed.connect(func():
		get_tree().call_group("hostController", "transition_to_scene", GameManager.mainMenu)
	)
	BoardPaint.apply($Board, true, 0.15)

func _process(delta: float) -> void:
	_time += delta
	for i in _fruits.size():
		var fruit: Node2D = _fruits[i]
		fruit.position = _fruit_origins[i] + Vector2(0, sin(_time * 1.6 + i * 1.3) * 12.0)
		fruit.rotation = sin(_time * 1.1 + i) * 0.12

func _make_row(member: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)

	var name_lbl := Label.new()
	name_lbl.text = member["name"]
	name_lbl.custom_minimum_size = Vector2(470, 0)
	name_lbl.add_theme_font_size_override("font_size", 60)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
	row.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = member["role"]
	role_lbl.custom_minimum_size = Vector2(420, 0)
	role_lbl.add_theme_font_size_override("font_size", 52)
	row.add_child(role_lbl)

	if member.has("link"):
		var link := Button.new()
		link.text = member["link_text"]
		link.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ButtonFx.style_text_button(link, Color(0.45, 0.62, 0.85), 38)
		ButtonFx.setup(link)
		link.pressed.connect(func(): OS.shell_open(member["link"]))
		row.add_child(link)
	return row
