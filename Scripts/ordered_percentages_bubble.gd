extends CanvasLayer

@onready var vbox = $Control/VBoxContainer
@onready var item = load("res://Scenes/item_perc.tscn")

@onready var parent = find_parent("orderControl")


var itemNo
var cusID


func _ready() -> void:
	itemNo = parent.currentOrders[cusID].size() 
	for i in range(itemNo):
		var c = item.instantiate()
		var key = parent.currentOrders[cusID].keys()[i]
		var peri = parent.currentOrders[cusID][key]
		c.spriter = getSPrite(key)
		c.texter = str(peri)
		vbox.add_child(c)
		

func getSPrite(skin):
	match skin:
		0:
			skin = load("res://assets/sprites/fruitSprites/bananaSprite.PNG")
		1:
			skin = load("res://assets/sprites/fruitSprites/strawberrySprite.PNG")
		2:
			skin = load("res://assets/sprites/fruitSprites/blueberrySprite.PNG")
		3:
			skin = load("res://assets/sprites/fruitSprites/mangoSprite.PNG")
		4:
			skin = load("res://assets/sprites/fruitSprites/appleSprite.PNG")
	return skin

func sizeFlags():
	match itemNo:
		2:
			vbox.add_theme_constant_override("separation", -100)
		3:
			vbox.add_theme_constant_override("separation", -60)
		4:
			vbox.add_theme_constant_override("separation", -25)
		5:
			vbox.add_theme_constant_override("separation", -20)
