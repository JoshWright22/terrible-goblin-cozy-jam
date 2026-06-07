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
@onready var charSprite1 = load("res://assets/sprites/characterSprites/char1/char1Sprite.PNG")
@onready var charSprite2 = load("res://assets/sprites/characterSprites/char2/char2Sprite.PNG")

#used for randomizing and ensuring there arent two of the same sprite at once
var characters : Array #initialized in _ready | sprite Node path list 
var characterSprites : Array  #initialized in _ready | add sprites here
var currentUsedSprites : Array #currently unused; put in genCustomer() after while()

var FADE_TIME : float = 1.5 #customer fade in seconds
var difficulty = "EASY" # "MED" "HARD" general setter for code

#Timer/health variables______________________________________________________
var MAX_TIME : float = 30 #Time till health runs out
var REMAIN_TIME : float #Time remaining, timer paused if no customers
var MAX_ADD_TIME : float = 15 #Max amount of time a player can win back with satisfaction

#Customer spawn time variables_______________________________________________
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
var order1 : Dictionary = {}
var order2 : Dictionary = {}
var order3 : Dictionary = {}
var order4 : Dictionary = {}

func _ready() -> void:
	characters = [customer1Sprite, customer2Sprite,customer3Sprite,customer4Sprite]
	characterSprites = [charSprite1, charSprite2]
	customerSpawnTimer.start(customerSpawnTimer.wait_time)
	REMAIN_TIME = MAX_TIME
func _process(delta: float) -> void:
	var percentage = healthTimer.time_left / healthTimer.wait_time
	healthBar.value = percentage

func genCustomer(): #creates customer and order Wip___________________
	if currentCustomer.size() <= 4:
		var fadeTween = create_tween() 
		var select = randi_range(0,3) #for selecting which place they will take
		while currentCustomer.has(select):#prevents selection of already occupied spot
			select = randi_range(0,3) #respin, techincally inefficient but its miliseconds lol
		var charNode = characters[select]
		currentCustomer[select] = charNode #asign customer no to its node path
		var sprite = characterSprites.pick_random() #selects random sprite for customer
		while currentUsedSprites.has(sprite): #ensures no two sprites are used at once UNUSED
			sprite = characterSprites.pick_random()
		charNode.texture = sprite #sets trg node to correct trg sprite
		fadeTween.tween_property(charNode, "modulate",Color(1,1,1,1.0), FADE_TIME)#controls customers "fading in"


func genOrder(): #creates the order and proportions of each needed; controls order difficulty
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
	else:
		print("Error at scaleDiff()")
	charTimeMin = setterMin
	charTimeMax = setterMax
	itemMin = itemSetterMin
	itemMax = itemSetterMax

func _on_customer_s_pawner_timeout() -> void: #next customer walks up/resets timer/sets diff/sets order
	if currentCustomer.size() == 0:
		healthTimer.start(REMAIN_TIME)
	customerSpawnTimer.stop()
	print("Customer Time: " + str(customerSpawnTimer.wait_time) + " @_on_customer_s_pawner_timeout()")
	scaleDiff()
	customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
	customerSpawnTimer.start(customerSpawnTimer.wait_time)
	genCustomer()
