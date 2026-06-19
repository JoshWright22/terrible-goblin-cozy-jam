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

func _ready() -> void:
	pass 


func slushiData(output) -> void:
	get_tree().call_group("orderControl", "compareValues", output)
