extends Node2D
var ID
@onready var sprite = $Sprite2D
@onready var charSprite1 = load("res://assets/sprites/characterSprites/char1/char1Sprite.PNG")
@onready var charSprite2 = load("res://assets/sprites/characterSprites/char2/char2Sprite.PNG")
@onready var bubble = load("res://assets/sprites/orderWindowSprites/speechBubble.png")
@onready var angryBubble = load("res://assets/sprites/orderWindowSprites/speechBubbleAngry.png")
@onready var orderBubble = load("res://Scenes/order_bubble.tscn")
var b

var ingredients : Array = ["Banana", "Apple", "Blueberry", "Mango", "Strawberry"] 

var characters : Array #initialized in _ready | sprite Node path list 
var characterSprites : Array  #initialized in _ready | add sprites here

var FADE_TIME = 1.5 

var patience = 0 #controls how long before changing emotion/order
var mood = 3 #3 happy 2 neutral 1 mad at 0 they leave

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().set_debug_collisions_hint(true)
	characterSprites = [charSprite1, charSprite2]
	self.modulate = Color(1,1,1,0)
	genCustomer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func genCustomer(): #creates customer and order Wip___________________
	var fadeTween = create_tween() 
	sprite.texture = characterSprites.pick_random() #selects random sprite for customer
	fadeTween.tween_property(self, "modulate",Color(1,1,1,1.0), FADE_TIME)#controls customers "fading in"


func _on_area_2d_mouse_entered() -> void:
	b = orderBubble.instantiate()
	b.SPRITE = bubble
	find_parent("orderControl").add_child(b)
	b.position = find_parent("orderControl").currentCustomer[ID] + Vector2(200,200)
	
