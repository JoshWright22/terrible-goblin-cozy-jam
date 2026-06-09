extends Node2D
var ID
@onready var timer = $emotionTimer
@onready var sprite = $Sprite2D
@onready var charSprite1 = load("res://assets/sprites/characterSprites/char1/char1HappySprite.PNG")
@onready var charSprite2 = load("res://assets/sprites/characterSprites/char2/char2HappySprite.PNG")
@onready var charSprite3 = load("res://assets/sprites/characterSprites/char3/char3HappySprite.PNG")
@onready var charSprite4 = load("res://assets/sprites/characterSprites/char4/char4HappySprite.PNG")
@onready var charSprite5 = load("res://assets/sprites/characterSprites/char5/char5NeutralSprite.PNG")
@onready var charAngSprite1 = load("res://assets/sprites/characterSprites/char1/char1AngrySprite.PNG")
@onready var charAngSprite2 = load("res://assets/sprites/characterSprites/char2/char2AngrySprite.PNG")
@onready var charAngSprite3 = load("res://assets/sprites/characterSprites/char3/char3AngrySprite.PNG")
@onready var charAngSprite4 = load("res://assets/sprites/characterSprites/char4/char4AngrySprite.PNG")
@onready var charAngSprite5 = load("res://assets/sprites/characterSprites/char5/char5AngrySprite.PNG")
@onready var charNeuSprite1 = load("res://assets/sprites/characterSprites/char1/char1NeutralSprite.PNG")
@onready var charNeuSprite2 = load("res://assets/sprites/characterSprites/char2/char2NeutralSprite.PNG")
@onready var charNeuSprite3 = load("res://assets/sprites/characterSprites/char3/char3NeutralSprite.PNG")
@onready var charNeuSprite4 = load("res://assets/sprites/characterSprites/char4/char4NeutralSprite.PNG")
@onready var charNeuSprite5= load("res://assets/sprites/characterSprites/char5/char5NeutralSprite.PNG")
@onready var bubble = load("res://assets/sprites/orderWindowSprites/speechBubble.png")
@onready var angryBubble = load("res://assets/sprites/orderWindowSprites/speechBubbleAngry.png")
@onready var orderBubble = load("res://Scenes/order_bubble.tscn")
@onready var control = find_parent("orderControl")

var b

var ingredients : Array = ["Banana", "Apple", "Blueberry", "Mango", "Strawberry"] 

var characters : Array #initialized in _ready | sprite Node path list 
var characterSprites : Array  #initialized in _ready | add sprites here
var neutralSprites : Array
var angrySprites : Array

var FADE_TIME = 1.5 


var patience = 0 #controls how long before changing emotion/order
var mood = 3 #3 happy 2 neutral 1 mad at 0 they leave

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.wait_time = genTimer()
	timer.start(timer.wait_time)
	get_tree().set_debug_collisions_hint(true)
	characterSprites = [charSprite1, charSprite2, charSprite3, charSprite4, charSprite5]
	neutralSprites = [charNeuSprite1, charNeuSprite2, charNeuSprite3, charNeuSprite4, charNeuSprite5]
	angrySprites = [charAngSprite1, charAngSprite2, charAngSprite3, charAngSprite4, charAngSprite5]
	self.modulate = Color(1,1,1,0)
	genCustomer()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func genCustomer(): #creates customer and order Wip___________________
	var fadeTween = create_tween() 
	sprite.texture = characterSprites.pick_random() #selects random sprite for customer
	fadeTween.tween_property(self, "modulate",Color(1,1,1,1.0), FADE_TIME)#controls customers "fading in"

func changeMood():
	var spriter = characterSprites.find(sprite.texture)
	if spriter == -1:
		spriter = neutralSprites.find(sprite.texture)
	if mood == 2:
		sprite.texture = neutralSprites[spriter]
	elif mood == 1:
		sprite.texture = angrySprites[spriter]
	
func genTimer():
	var setter
	if control.difficulty == "EASY":
		setter = randi_range(control.MIN_WAIT_TIME_EASY,control.MAX_WAIT_TIME_EASY)
	elif control.difficulty == "MED":
		setter = randi_range(control.MIN_WAIT_TIME_MED,control.MAX_WAIT_TIME_MED)
	else:
		setter = randi_range(control.MIN_WAIT_TIME_HARD,control.MAX_WAIT_TIME_HARD)
	return setter

func spriteCorrection():
	if sprite.texture == charSprite2:
		sprite.position = Vector2(-25,0)

func _on_area_2d_mouse_entered() -> void:
	b = orderBubble.instantiate()
	b.SPRITE = bubble
	control.add_child(b)
	b.position = control.currentCustomer[ID] + Vector2(125,200)

func _on_area_2d_mouse_exited() -> void:
	b.queue_free()


func _on_emotion_timer_timeout() -> void:
	if mood == 1:
		var fadeAway = create_tween()
		fadeAway.tween_property(self, "modulate",Color(1,1,1,0), FADE_TIME)
		fadeAway.finished.connect(queue_free)
	else:
		mood = mood - 1
		changeMood()
		timer.wait_time = genTimer()
		timer.start(timer.wait_time)
