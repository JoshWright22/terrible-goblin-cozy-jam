extends Node2D
#Node paths and loads________________________________________________________
@onready var healthBar = $healthbar/ProgressBar
@onready var healthTimer = $healthbar/Timer
@onready var customerSpawnTimer = $customerSpawner
#____________________#loaded character sprites_________________________________
@onready var gameOverScene = load("res://Scenes/game_over.tscn")
@onready var customer = load("res://Scenes/customer.tscn")

var spritesUsed : Dictionary = {}
var difficulty = "EASY" # "MED" "HARD" general setter for code

#Timer/health variables______________________________________________________
var MAX_TIME : float = 30 #Time till health runs out
var REMAIN_TIME : float #Time remaining, timer paused if no customers
var MAX_ADD_TIME : float = 15 #Max amount of time a player can win back with satisfaction

#Customer spawn time variables_______________________________________________
var positions : Dictionary = {1 : Vector2(147.4, 340.8), 2 : Vector2(358, 340.8), 3 : Vector2(575, 340.8), 4 : Vector2(778, 340.8)}

var charTimeMin : float #setter variables for below
var charTimeMax : float

var MIN_CHAR_TIME_EASY = 8
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
var ITEM_MED_MIN : int = 3
var ITEM_HARD_MIN : int = 4

var ITEM_EASY_MAX : int = 3
var ITEM_MED_MAX : int = 4
var ITEM_HARD_MAX : int = 5
#___________________Customer/Order Variables________________________________
var customerNo : int = 0 #tracks how many customers you've served for difficulty scaling
var currentCustomer : Dictionary = {} #tracks current customer + loc
var currentOrders : Dictionary = {} #tracks customer ID & order Array
var delivery_zones: Dictionary = {} #tracks customer ID -> Area2D in main scene
# Canonical ingredient list — uses the same FruitType enum as FruitData resources
var ingredients: Array[FruitData.FruitType] = [
	FruitData.FruitType.BANANA,
	FruitData.FruitType.STRAWBERRY,
	FruitData.FruitType.BLUEBERRY,
	FruitData.FruitType.MANGO,
	FruitData.FruitType.APPLE,
]

#assigned to positions left to right, not necessarily the order the customers show up

func _ready() -> void:
	add_to_group("order_manager")
	customerSpawnTimer.start(customerSpawnTimer.wait_time)

func _process(delta: float) -> void: #WIP make linear
	pass#var percentage = healthTimer.time_left / healthTimer.wait_time
	#percentage = percentage * 45
	#healthBar.value = percentage




func scaleDiff(): #simply checks and sets diffculty variables | add cust completed check
	var setterMin
	var setterMax
	var itemSetterMin
	var itemSetterMax
	var waitSetterMin
	var waitSetterMax
	if customerNo >= 6 && customerNo <= 9:
		difficulty = "MEDIUM"
	elif customerNo >= 10:
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

func genOrder(custID):
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

## Maps a SubViewport-local position to world space, accounting for the
## custWindow offset and the SubViewportContainer's stretch scaling.
func _subviewport_to_world(sv_pos: Vector2) -> Vector2:
	var container := $custWindow/characterSprites as SubViewportContainer
	var sv_size := Vector2($custWindow/characterSprites/SubViewport.size)
	var rect := container.get_rect()
	var scaled := Vector2(sv_pos.x * rect.size.x / sv_size.x, sv_pos.y * rect.size.y / sv_size.y)
	return $custWindow.to_global(rect.position + scaled)

func _create_delivery_zone(customer_id: int, sv_pos: Vector2) -> void:
	var zone := Area2D.new()
	zone.name = "CustomerDeliveryZone"
	zone.set_meta("customer_id", customer_id)
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 60.0
	shape.height = 120.0
	col.shape = shape
	zone.add_child(col)
	add_child(zone)
	zone.global_position = _subviewport_to_world(sv_pos)
	delivery_zones[customer_id] = zone
	print("[ORDER] Delivery zone created for customer ", customer_id, " at world pos ", zone.global_position)

func remove_delivery_zone(customer_id: int) -> void:
	if delivery_zones.has(customer_id):
		delivery_zones[customer_id].queue_free()
		delivery_zones.erase(customer_id)

func receive_smoothie_delivery(delivered: Array, customer_id: int) -> void:
	if not currentCustomer.has(customer_id):
		return

	# Convert delivered FruitData resources → FruitType enum values for comparison
	var delivered_types: Array[FruitData.FruitType] = []
	for item in delivered:
		if item is FruitData:
			delivered_types.append(item.fruit_name)

	var _order: Array = currentOrders.get(customer_id, [])
	# _order and delivered_types are both Array[FruitData.FruitType] — ready for match logic here

	var customer_node = $custWindow/characterSprites/SubViewport.get_node_or_null("Customer_" + str(customer_id))
	if customer_node and customer_node.has_method("serve"):
		customer_node.serve()

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
		_create_delivery_zone(customerNo, trgPos)
		genOrder(customerNo)
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)
	else:
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)

func _on_timer_timeout() -> void: #GAME OVER | Health ran out
	healthTimer.stop()
	customerSpawnTimer.stop()
	var GM = gameOverScene.instantiate()
	add_child(GM)
