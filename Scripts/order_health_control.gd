extends Node2D
@onready var healthBar = $healthbar/ProgressBar
@onready var timer = $healthbar/Timer
@onready var char1Sprite = $custWindow/characterSprites/Char1Sprite
@onready var char2Sprite = $custWindow/characterSprites/Char2Sprite
@onready var char3Sprite = $custWindow/characterSprites/Char3Sprite
@onready var char4Sprite = $custWindow/characterSprites/Char4Sprite
@onready var charSpawnTImer = $customerSPawner

#Timer/health variables
var MAX_TIME = 30
var MAX_ADD_TIME = 15

#Customer variables
var MIN_CHAR_TIME = 10
var MAX_CHAR_TIME = 15

var EASY_MIN = 2 #NO OF ITEMS USED PER ORDER PER DIFFICULTY
var EASY_MAX = 3
var MED_MIN = 3
var MED_MAX = 4
var HARD_MIN = 3
var HARD_MAX = 5

var customerNo #tracks how many customers you've served for difficulty scaling
var currentCustomerCount 

var ingredients : Array = [ #list of things a customer may want
"Banana", "Apple", "Cherry", "Mango", "Strawberry"
]

var currentOrders : Array = []
#assigned to positions left to right, not necessarily the order the customers show up
var order1 : Dictionary = {}
var order2 : Dictionary = {}
var order3 : Dictionary = {}
var order4 : Dictionary = {}

func _ready() -> void:
	pass 
func _process(delta: float) -> void:
	pass

func genCustomer(): #creates customer and order
	if currentOrders.size() <= 4:
		pass
	customerNo = customerNo + 1

func genOrder(): #creates the order and proportions of each needed; controls order difficulty
	if customerNo <= 4: #Easy
		pass
	elif customerNo >= 5 && customerNo <= 8: #Med (More items, stranger proportions)
		pass
	else: #Hard (Most items, wacky proportions
		pass


func _on_customer_s_pawner_timeout() -> void: #next customer walks up
	charSpawnTImer.wait_time = randi_range(MIN_CHAR_TIME, MAX_CHAR_TIME)
	genCustomer()
