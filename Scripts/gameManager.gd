extends Node2D

@onready var mainMenu = load("res://Scenes/Primary/main_menu.tscn")
@onready var gameLoop = load("res://Scenes/Primary/game_loop.tscn")
@onready var pauseScene = load("res://Scenes/pause_menu.tscn")
@onready var creditsScene = load("res://Scenes/Primary/credits.tscn")
@onready var settingsScene = load("res://Scenes/Primary/settings.tscn")
var paused : bool = false #tells system if game paused


#check if theres a trgID 
#pass dict in same format as currectOrders through GameMaster.slushiData(yourDict)
#see debug scene example code
var hold = false

var smoothie : Dictionary = {}
var trgID = null

# Settings
var auto_show_orders: bool = true       # show order bubbles without hovering
var change_order_on_anger: bool = true # customers reroll order when they turn angry

var score: int = 0
var fruit_held: bool = false  # prevents picking up two pieces at once
var smoothie_quality: float = 1.0  # set by smoothie before delivery, applied to score
var seen_fruit_types: Array[int] = []  # FruitType ints that have appeared on the belt
var game_over: bool = false

# Campaign
const DAY_COUNT := 18
@onready var daySelectScene = load("res://Scenes/Primary/day_select.tscn")
var current_day: DayConfig = null   # null = endless mode
var day_complete: bool = false
var power_out: bool = false          # Power Outage twist: blenders can't blend while true
var stars_before_day: int = 0
# Tutorial: while true, customers are patient and the timers stop
var tutorial_active: bool = false
var rotations: int = 0          # pieces rotated this run
var smoothies_served: int = 0   # smoothies delivered this run        # total stars when the day started, for unlock announcements
@onready var styleScene = load("res://Scenes/Primary/style_shop.tscn")

func _ready() -> void:
	pass

func load_day(day_number: int) -> DayConfig:
	return load("res://Resource/Days/day_%02d.tres" % day_number) as DayConfig

func start_day(day_number: int) -> void:
	current_day = load_day(day_number)
	get_tree().call_group("hostController", "transition_to_scene", gameLoop)

func start_endless() -> void:
	current_day = null
	get_tree().call_group("hostController", "transition_to_scene", gameLoop)

func endless_unlocked() -> bool:
	# Mobile gets endless from the start, Steam unlocks it by finishing the campaign
	return OS.has_feature("mobile") or SaveManager.unlocked_day > DAY_COUNT

func has_next_day() -> bool:
	return current_day != null and current_day.day_number < DAY_COUNT


func slushiData(output) -> void:
	get_tree().call_group("orderControl", "compareValues", output)
