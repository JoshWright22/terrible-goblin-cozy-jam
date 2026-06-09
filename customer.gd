extends Node2D
@onready var sprite = $Sprite2D
@onready var charSprite1 = load("res://assets/sprites/characterSprites/char1/char1Sprite.PNG")
@onready var charSprite2 = load("res://assets/sprites/characterSprites/char2/char2Sprite.PNG")


var characters : Array #initialized in _ready | sprite Node path list 
var characterSprites : Array  #initialized in _ready | add sprites here
var currentUsedSprites : Array #currently unused; put in genCustomer() after while()

var FADE_TIME = 1.5 

var patience = 0 #controls how long before changing emotion/order

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	characterSprites = [charSprite1, charSprite2]
	self.modulate = Color(1,1,1,0)
	genCustomer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func genCustomer(): #creates customer and order Wip___________________
	var fadeTween = create_tween() 
	sprite = characterSprites.pick_random() #selects random sprite for customer
	fadeTween.tween_property(self, "modulate",Color(1,1,1,1.0), FADE_TIME)#controls customers "fading in"
