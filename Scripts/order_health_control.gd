extends Node2D
@onready var healthBar = $healthbar/ProgressBar
@onready var timer = $healthbar/Timer
@onready var satis = load("res://assets/sprites/orderWindowSprites/satisfiedSprite.png")
@onready var medSatisSprite = load("res://assets/sprites/orderWindowSprites/medSasSprite.png")
@onready var unsatisSprite = load("res://assets/sprites/orderWindowSprites/unsasSprite.png")

#Timer/health variables
var MAX_TIME = 30
var MAX_ADD_TIME = 15

#Customer variables
var EASY_MIN = 2 #NO OF ITEMS USED PER ORDER PER DIFFICULTY
var EASY_MAX = 3
var MED_MIN = 3
var MED_MAX = 4
var HARD_MIN = 3
var HARD_MAX = 5

var customerNo #tracks how many customers you've served for difficulty scaling

var ingredients : Array = [ #list of things a customer may want
"Banana", "Apple", "Cherry", "Mango", "Strawberry"
]

var currentOrder : Dictionary = { #what customer wants in what proportions
	
}


func _ready() -> void:
	pass 
func _process(delta: float) -> void:
	pass

func genCustomer(): #creates customer and order
	customerNo = customerNo + 1

func genOrder(): #creates the order and proportions of each needed; controls order difficulty
	if customerNo <= 4: #Easy
		pass
	elif customerNo >= 5 && customerNo <= 8: #Med (More items, stranger proportions)
		pass
	else: #Hard (Most items, wacky proportions
		pass
