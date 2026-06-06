extends Node2D
@onready var health = $healthbar/ProgressBar
@onready var timer = $healthbar/Timer
@onready var satis = load("res://assets/sprites/orderWindowSprites/satisfiedSprite.png")
@onready var medSatisSprite = load("res://assets/sprites/orderWindowSprites/medSasSprite.png")
@onready var unsatisSprite = load("res://assets/sprites/orderWindowSprites/unsasSprite.png")

var customerNo #tracks how many customers you've served for difficulty scaling

var ingredients : Array = [ #list of things a customer may want
]

var currentOrder : Dictionary = { #what customer wants in what proportions
	
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func genCustomer(): #creates customer and order
	pass
