extends Node2D

@onready var mainMenu = load("res://Scenes/Primary/main_menu.tscn")
@onready var gameLoop = load("res://Scenes/Primary/game_loop.tscn")
@onready var pauseScene = load("res://Scenes/pause_menu.tscn")
@onready var creditsScene = load("res://Scenes/Primary/credits.tscn")
#@onready var settingsScene = load()
var paused : bool = false #tells system if game paused

var firstRun : bool = true #controls if this is the players first run

#check if theres a trgID 
#pass dict in same format as currectOrders through GameMaster.slushiData(yourDict)
#see debug scene example code
var hold = false

var smoothie : Dictionary = {}
var trgID = null

func _ready() -> void:
	pass 


func slushiData(output) -> void:
	get_tree().call_group("orderControl", "compareValues", output)
