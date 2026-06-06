extends Node2D
@onready var healthBar = $healthbar/ProgressBar
@onready var timer = $healthbar/Timer
@onready var satis = load("res://assets/sprites/orderWindowSprites/satisfiedSprite.png")
@onready var medSatisSprite = load("res://assets/sprites/orderWindowSprites/medSasSprite.png")
@onready var unsatisSprite = load("res://assets/sprites/orderWindowSprites/unsasSprite.png")

#Timer/health variables
var MAX_TIME = 30

var customerNo #tracks how many customers you've served for difficulty scaling

var ingredients : Array = [ #list of things a customer may want
]

var currentOrder : Dictionary = { #what customer wants in what proportions
	
}


func _ready() -> void:
	pass 
func _process(delta: float) -> void:
	pass

func genCustomer(): #creates customer and order
	customerNo = customerNo + 1

func genOrder():
	pass
