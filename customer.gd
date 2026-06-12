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
@onready var orderAmount = load("res://Scenes/ordered_percentages_bubble.tscn")
@onready var control = find_parent("orderControl")

var b
var c

var yFIx = 329

var characters : Array #initialized in _ready | sprite Node path list 
var characterSprites : Array  #initialized in _ready | add sprites here
var neutralSprites : Array
var angrySprites : Array

var FADE_TIME = 1.5 


var patience = 0 #controls how long before changing emotion/order
var mood = 3 #3 happy 2 neutral 1 mad at 0 they leave

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.wait_time = randi_range(control.minWaitTime,control.maxWaitTime)
	timer.start(timer.wait_time)
	characterSprites = [charSprite1, charSprite2, charSprite3, charSprite4, charSprite5]
	neutralSprites = [charNeuSprite1, charNeuSprite2, charNeuSprite3, charNeuSprite4, charNeuSprite5]
	angrySprites = [charAngSprite1, charAngSprite2, charAngSprite3, charAngSprite4, charAngSprite5]
	self.modulate = Color(1,1,1,0)
	genCustomer()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func genCustomer(): #creates customer and order Wip___________________
	var fadeTween = create_tween() 
	var text = characterSprites.pick_random() #selects random sprite for customer
	while text in control.spritesUsed.values():
		text = characterSprites.pick_random()
	sprite.texture = text
	control.spritesUsed[ID] = text
	spriteCorrection()
	fadeTween.tween_property(self, "modulate",Color(1,1,1,1.0), FADE_TIME)#controls customers "fading in"

func changeMood():
	var spriter = characterSprites.find(sprite.texture)
	if spriter == -1:
		spriter = neutralSprites.find(sprite.texture)
	if mood == 2:
		sprite.texture = neutralSprites[spriter]
	elif mood == 1:
		sprite.texture = angrySprites[spriter]


func spriteCorrection():
	if sprite.texture == charSprite1:
		sprite.position = sprite.position + Vector2(25,0)
	elif sprite.texture == charSprite3:
		sprite.position = sprite.position + Vector2(-25,0)
	elif sprite.texture == charSprite4:
		sprite.position = sprite.position + Vector2(-25,60)

func _on_area_2d_mouse_entered() -> void:
	if control.currentCustomer.has(ID):
		var openTween = create_tween()
		b = orderBubble.instantiate()
		if mood == 1:
			b.SPRITE = angryBubble
		else:
			b.SPRITE = bubble
		c = orderAmount.instantiate()
		c.offset = control.currentCustomer[ID] + Vector2(0,yFIx)
		c.cusID = ID
		b.scale = Vector2(0,0)
		control.add_child(b)
		openTween.tween_property(b, "scale", Vector2(1,1), .1)
		openTween.finished.connect(func(): 
			if is_instance_valid(c):
					control.add_child(c)
		)
		b.position = control.currentCustomer[ID] + Vector2(125,200)
		

func _on_area_2d_mouse_exited() -> void:
	if b != null && c != null:
		var closeTween = create_tween()
		closeTween.tween_property(b, "scale", Vector2(0,0), .1)
		c.queue_free()
		closeTween.finished.connect(b.queue_free)
	else:
		pass


func serve() -> void:
	timer.stop()
	control.currentCustomer.erase(ID)
	control.spritesUsed.erase(ID)
	control.currentOrders.erase(ID)
	control.remove_delivery_zone(ID)
	if b != null:
		b.queue_free()
	var fadeAway = create_tween()
	fadeAway.tween_property(self, "modulate", Color(1, 1, 1, 0), FADE_TIME)
	fadeAway.finished.connect(queue_free)

func _on_emotion_timer_timeout() -> void:
	if mood == 1:
		var fadeAway = create_tween()
		fadeAway.tween_property(self, "modulate",Color(1,1,1,0), FADE_TIME)
		fadeAway.finished.connect(queue_free)
		control.currentCustomer.erase(ID)
		control.spritesUsed.erase(ID)
		control.currentOrders.erase(ID)
		control.remove_delivery_zone(ID)
		if b != null:
			b.queue_free()
		if c != null:
			c.queue_free()
	else:
		mood = mood - 1
		changeMood()
		timer.wait_time = randi_range(control.minWaitTime,control.maxWaitTime)
		timer.start(timer.wait_time)
