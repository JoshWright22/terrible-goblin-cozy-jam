extends Node2D
#Node paths and loads________________________________________________________
@onready var healthBar = $healthbar/ProgressBar
@onready var customerSpawnTimer = $customerSpawner
#____________________#loaded character sprites_________________________________
@onready var gameOverScene = load("res://Scenes/game_over.tscn")
@onready var customer = load("res://Scenes/customer.tscn")

var gameOver = false
var spritesUsed : Dictionary = {}
var difficulty = "EASY" # "MED" "HARD" general setter for code

#Timer/health variables______________________________________________________
var MAX_TIME : float = 45.0 #Time till health runs out
var REMAIN_TIME : float #Time remaining, timer paused if no customers
var ADD_TIME : float = 3.0 #Max amount of time per score a player can win back with satisfaction
var handBreak = false #helps with smooth animation
#Customer spawn time variables_______________________________________________
var positions : Dictionary = {1 : Vector2(147.4, 340.8), 2 : Vector2(358, 340.8), 3 : Vector2(575, 340.8), 4 : Vector2(778, 340.8)}

var MED_CUSTOMER_MIN = 6 #When it turns med
var MED_CUSTOMER_MAX = 10 #when it turns hard

var charTimeMin : float #setter variables for below
var charTimeMax : float

var MIN_CHAR_TIME_EASY = 8 #time for character spawn
var MIN_CHAR_TIME_MED = 7
var MIN_CHAR_TIME_HARD = 5

var MAX_CHAR_TIME_EASY = 14
var MAX_CHAR_TIME_MED = 13
var MAX_CHAR_TIME_HARD = 8

#TIME UNTIL CUSTOMER CHANGES EMOTION + LOSE POINTS______________________________
var minWaitTime
var maxWaitTime

var MAX_WAIT_TIME_EASY = 15
var MIN_WAIT_TIME_EASY = 10

var MAX_WAIT_TIME_MED = 13
var MIN_WAIT_TIME_MED = 9

var MAX_WAIT_TIME_HARD = 12
var MIN_WAIT_TIME_HARD = 8
#NO OF ITEMS USED PER ORDER PER DIFFICULTY__________________________________
var itemMin : int #setter variables for below
var itemMax : int

var ITEM_EASY_MIN : int = 2 
var ITEM_EASY_MAX : int = 3

var ITEM_MED_MIN : int = 3
var ITEM_MED_MAX : int = 4

var ITEM_HARD_MIN : int = 4
var ITEM_HARD_MAX : int = 5

var bestScore = 75 #whole number percentage of matching to get perfect (i.e <= 75% is perfect score) 
var medScore = 50 #stopping point at half
#___________________Customer/Order Variables________________________________
var customerNo : int = 0 #tracks how many customers you've served for difficulty scaling
var currentCustomer : Dictionary = {} #tracks current customer + loc
var currentOrders : Dictionary = {} #tracks customer ID & order Array
#var delivery_zones: Dictionary = {} #tracks customer ID 
# Canonical ingredient list — uses the same FruitType enum as FruitData resources
var ingredients: Array[FruitData.FruitType] = [
	FruitData.FruitType.BANANA,
	FruitData.FruitType.STRAWBERRY,
	FruitData.FruitType.BLUEBERRY,
	FruitData.FruitType.MANGO,
	FruitData.FruitType.APPLE,
]


func _ready() -> void:
	#get_tree().set_debug_collisions_hint(true) #Shows area 2Ds
	if GameManager.firstRun:
		GameManager.paused = true
		GameManager.firstRun = false
		var helper = load("res://Scenes/help_scene.tscn").instantiate()
		add_child(helper)
	REMAIN_TIME = MAX_TIME
	customerSpawnTimer.start(customerSpawnTimer.wait_time)
	healthBar.max_value = MAX_TIME
	healthBar.value = MAX_TIME

func _process(delta: float) -> void: 
	if currentCustomer.size() != 0 && !handBreak && !GameManager.paused:
		REMAIN_TIME = REMAIN_TIME - delta
		healthBar.ratio = REMAIN_TIME / MAX_TIME
	if REMAIN_TIME <= 0 && !gameOver:
		gameOver = true
		customerSpawnTimer.stop()
		currentCustomer.clear()
		var GM = gameOverScene.instantiate()
		add_child(GM)
	if GameManager.paused:
		customerSpawnTimer.paused = true
	elif !GameManager.paused:
		if customerSpawnTimer.is_paused():
			customerSpawnTimer.paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if !GameManager.paused:
			GameManager.paused = true
			get_tree().call_group("hostController", "changeScene", GameManager.pauseScene)
		else:
			GameManager.paused = false

	

func compareValues(inputer): 
	var texturez = load("res://assets/sprites/orderWindowSprites/face1Sprite.PNG")
	var cake = load("res://Scenes/percent_score.tscn")
	var cc = cake.instantiate()
	var score = 4 
	var percent = 0
	var trger = GameManager.trgID
	GameManager.trgID = null
	var star = load("res://Scenes/control_add_time.tscn")
	var custom = find_child("Customer_" + str(trger), true, false)
	if custom.area != null:
		custom.area.queue_free()
	if custom.c != null && custom.b != null:
		custom.c.queue_free()
		custom.b.queue_free()
	var moodScore = 3 - custom.mood
	score = score - moodScore
	for key in inputer:
		if key not in currentOrders[trger]:
			pass
		else:
			var orde = currentOrders[trger][key]
			var inp = inputer[key]
			var tot
			if orde >= inp:
				tot = inp
			else:
				tot = currentOrders[trger][key]
			percent = percent + tot
	if percent >= bestScore:
		cc.modulate = Color(0,1,.25)
	elif percent >= medScore:
		score = score - 1
		cc.modulate = Color(1, 1, 0)
	else:
		score = score - 3
		cc.modulate = Color(1, 0.0, 0.0)
	if score == 3:
		texturez = load("res://assets/sprites/orderWindowSprites/face2Sprite.PNG")
	elif score == 2:
		texturez = load("res://assets/sprites/orderWindowSprites/face3Sprite.PNG")
	elif score == 1:
		texturez = load("res://assets/sprites/orderWindowSprites/face4Sprite.PNG")
	if score < 1:
		pass
	else:
		handBreak = true
		for i in range(score):
			var move = create_tween()
			var c = star.instantiate()
			c.textures = texturez
			c.position = currentCustomer[trger] + Vector2(100, 0)
			add_child(c)
			move.tween_property(c, "position", c.position + Vector2(0, -250), .25)
			move.tween_property(c, "position", Vector2(102, 80), .2)
			move.finished.connect(func():
				REMAIN_TIME = clamp(REMAIN_TIME + ADD_TIME, 0, MAX_TIME)
				healthBar.ratio = REMAIN_TIME / MAX_TIME
				c.queue_free()
			)
			await move.finished
		handBreak = false
	cc.sets = percent
	cc.position = currentCustomer[trger]
	add_child(cc)
	custom.serve()

func scaleDiff(): #simply checks and sets diffculty variables | add cust completed check
	var setterMin
	var setterMax
	var itemSetterMin
	var itemSetterMax
	var waitSetterMin
	var waitSetterMax
	if customerNo >= MED_CUSTOMER_MIN && customerNo <= MED_CUSTOMER_MAX:
		difficulty = "MEDIUM"
	elif customerNo >= MED_CUSTOMER_MAX + 1:
		difficulty = "HARD"
	
	if difficulty == "EASY":
		setterMin = MIN_CHAR_TIME_EASY
		setterMax = MAX_CHAR_TIME_EASY
		itemSetterMin = ITEM_EASY_MIN
		itemSetterMax = ITEM_EASY_MAX
		waitSetterMin = MIN_WAIT_TIME_EASY
		waitSetterMax = MAX_WAIT_TIME_EASY
	elif difficulty == "MEDIUM":
		setterMin = MIN_CHAR_TIME_MED
		setterMax = MAX_CHAR_TIME_MED
		itemSetterMin = ITEM_MED_MIN
		itemSetterMax = ITEM_MED_MAX
		waitSetterMin = MIN_WAIT_TIME_MED
		waitSetterMax = MAX_WAIT_TIME_MED
	elif difficulty == "HARD":
		setterMin = MIN_CHAR_TIME_HARD
		setterMax = MAX_CHAR_TIME_HARD
		itemSetterMin = ITEM_HARD_MIN
		itemSetterMax = ITEM_HARD_MAX
		waitSetterMin = MIN_WAIT_TIME_HARD
		waitSetterMax = MAX_WAIT_TIME_HARD
	charTimeMin = setterMin
	charTimeMax = setterMax
	itemMin = itemSetterMin
	itemMax = itemSetterMax
	minWaitTime = waitSetterMin
	maxWaitTime = waitSetterMax

func genOrder(custID): #generates dict of order and percentages saved in orders dict
	var order = {}
	var selectedFruit = []
	var fruitPerc = []
	var fruitNo = randi_range(itemMin,itemMax)
	var select
	var total : float = 0 
	var remainer = 100
	for i in range(fruitNo):
		select = ingredients.pick_random()
		while select in selectedFruit:
			select = ingredients.pick_random()
		var adder = randi_range(1,5)
		total = total + float(adder)
		fruitPerc.append(adder)
		selectedFruit.append(select)
		
	for i in range(selectedFruit.size()-1): 
		var fFloat = float(fruitPerc[i])/total
		var fPerc = int(fFloat * 100)
		remainer = remainer - fPerc
		order[selectedFruit[i]] = fPerc
	var GETTER = selectedFruit.size()-1
	order[selectedFruit[GETTER]] = remainer
	currentOrders[custID] = order

func _on_customer_s_pawner_timeout() -> void: #next customer walks up/resets timer/sets diff/sets order
	if currentCustomer.size() != 4:
		customerNo = customerNo + 1
		customerSpawnTimer.stop()
		scaleDiff()
		var c = customer.instantiate()
		c.name = "Customer_" + str(customerNo)
		var trgPos = positions[randi_range(1,4)]
		while trgPos in currentCustomer.values():
			trgPos = positions[randi_range(1,4)]
		c.position = trgPos
		c.ID = customerNo
		currentCustomer[customerNo] = trgPos
		$custWindow/characterSprites/SubViewport.add_child(c)
		genOrder(customerNo)
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)
	else:
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)
