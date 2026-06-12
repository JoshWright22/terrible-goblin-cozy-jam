extends CanvasLayer

@onready var strawberrySprite = load("res://assets/sprites/fruitSprites/strawberrySprite.PNG")
@onready var mangoSprite = load("res://assets/sprites/fruitSprites/mangoSprite.PNG")
@onready var blueberrySprite = load("res://assets/sprites/fruitSprites/blueberrySprite.PNG")
@onready var bananaSpite = load("res://assets/sprites/fruitSprites/bananaSprite.PNG")
@onready var appleSprite = load("res://assets/sprites/fruitSprites/appleSprite.PNG")
@onready var parent = find_parent("orderControl")


var itemNo
var cusID


func _ready() -> void:
	#itemNo = parent.currentOrders[cusID].size() 
	pass
		


func sizeFlags():
	pass
