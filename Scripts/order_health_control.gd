extends Node2D
#Node paths and loads________________________________________________________
@onready var healthBar = $healthbar/ProgressBar
@onready var healthTimer = $healthbar/Timer
@onready var customer1Sprite = $custWindow/characterSprites/Char1Sprite
@onready var customer2Sprite = $custWindow/characterSprites/Char2Sprite
@onready var customer3Sprite = $custWindow/characterSprites/Char3Sprite
@onready var customer4Sprite = $custWindow/characterSprites/Char4Sprite
@onready var customerSpawnTimer = $customerSpawner
#____________________#loaded character sprites_________________________________
@onready var gameOverScene = load("res://Scenes/game_over.tscn")
@onready var customer = load("res://Scenes/customer.tscn")

var difficulty = "EASY" # "MED" "HARD" general setter for code

#Timer/health variables______________________________________________________
var MAX_TIME : float = 30 #Time till health runs out
var REMAIN_TIME : float #Time remaining, timer paused if no customers
var MAX_ADD_TIME : float = 15 #Max amount of time a player can win back with satisfaction

#Customer spawn time variables_______________________________________________
var positions : Dictionary = {1 : Vector2(147.4, 323.6), 2 : Vector2(308, 340.8), 3 : Vector2(505, 334.8), 4 : Vector2(728, 338.8)}

var charTimeMin : float #setter variables for below
var charTimeMax : float

var MIN_CHAR_TIME_EASY = 8
var MIN_CHAR_TIME_MED = 7
var MIN_CHAR_TIME_HARD = 5

var MAX_CHAR_TIME_EASY = 14
var MAX_CHAR_TIME_MED = 13
var MAX_CHAR_TIME_HARD = 8
#NO OF ITEMS USED PER ORDER PER DIFFICULTY__________________________________
var itemMin : int #setter variables for below
var itemMax : int

var ITEM_EASY_MIN : int = 2 
var ITEM_MED_MIN : int = 3
var ITEM_HARD_MIN : int = 3

var ITEM_EASY_MAX : int = 3
var ITEM_MED_MAX : int = 4
var ITEM_HARD_MAX : int = 5
#___________________________________________________________________________
#EXTREMELY WIP
var customerNo #tracks how many customers you've served for difficulty scaling
var currentCustomer : Dictionary = {} #tracks current customer + node path
#list of things a customer may want
var ingredients : Array = ["Banana", "Apple", "Cherry", "Mango", "Strawberry"] 
var currentOrders : Array = []
#assigned to positions left to right, not necessarily the order the customers show up

func _ready() -> void:
	customerSpawnTimer.start(customerSpawnTimer.wait_time)

func _process(delta: float) -> void: #WIP make linear
	pass#var percentage = healthTimer.time_left / healthTimer.wait_time
	#percentage = percentage * 30
	#healthBar.value = percentage



func genOrder(cust): #creates the order and proportions of each needed; controls order difficulty
	pass

func scaleDiff(): #simply checks and sets diffculty variables | add cust completed check
	var setterMin
	var setterMax
	var itemSetterMin
	var itemSetterMax
	if difficulty == "EASY":
		setterMin = MIN_CHAR_TIME_EASY
		setterMax = MAX_CHAR_TIME_EASY
		itemSetterMin = ITEM_EASY_MIN
		itemSetterMax = ITEM_HARD_MAX
	elif difficulty == "MED":
		pass
	elif difficulty == "HARD":
		pass
	charTimeMin = setterMin
	charTimeMax = setterMax
	itemMin = itemSetterMin
	itemMax = itemSetterMax

func _on_customer_s_pawner_timeout() -> void: #next customer walks up/resets timer/sets diff/sets order
	if currentCustomer.size() != 4:
		customerSpawnTimer.stop()
		scaleDiff()
		var c = customer.instantiate()
		$custWindow/characterSprites/SubViewport.add_child(c)
		c.name = "Customer_" + str(currentCustomer.size() + 1)
		var trgPos = positions[randi_range(1,4)]
		while trgPos in currentCustomer.values():
			trgPos = positions[randi_range(1,4)]
		c.position = trgPos
		currentCustomer.get_or_add(c,trgPos)
		genOrder(c)
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)



func _on_timer_timeout() -> void: #GAME OVER | Health ran out
	healthTimer.stop()
	customerSpawnTimer.stop()
	var c = gameOverScene.instantiate()
	add_child(c)
