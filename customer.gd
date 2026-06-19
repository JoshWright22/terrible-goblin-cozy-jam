extends Node2D
var ID
@onready var area = $Area2D
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
@onready var charNeuSprite5 = load("res://assets/sprites/characterSprites/char5/char5NeutralSprite.PNG")
@onready var bubble = load("res://assets/sprites/orderWindowSprites/bubble1Sprite.PNG")
@onready var angryBubble = load("res://assets/sprites/orderWindowSprites/bubble2Sprite.PNG")
@onready var orderBubble = load("res://Scenes/order_bubble.tscn")
@onready var orderAmount = load("res://Scenes/ordered_percentages_bubble.tscn")
@onready var control = find_parent("orderControl")

var b
var c

var _base_sprite_scale: Vector2
var _is_highlighted: bool = false

var yFIx = 329
var changeMaxChance = 3

var characters: Array
var characterSprites: Array
var neutralSprites: Array
var angrySprites: Array

var FADE_TIME = 1.5
var patience = 0
var mood = 3  # 3=happy 2=neutral 1=angry 0=leave

func _ready() -> void:
	timer.wait_time = randi_range(control.minWaitTime, control.maxWaitTime)
	timer.start(timer.wait_time)
	characterSprites = [charSprite1, charSprite2, charSprite3, charSprite4, charSprite5]
	neutralSprites   = [charNeuSprite1, charNeuSprite2, charNeuSprite3, charNeuSprite4, charNeuSprite5]
	angrySprites     = [charAngSprite1, charAngSprite2, charAngSprite3, charAngSprite4, charAngSprite5]
	self.modulate = Color(1, 1, 1, 0)
	genCustomer()
	_base_sprite_scale = sprite.scale

func _process(_delta: float) -> void:
	timer.paused = GameManager.paused
	var should_highlight: bool = GameManager.hold and GameManager.trgID == ID
	if should_highlight and not _is_highlighted:
		_is_highlighted = true
		_pop_highlight()
	elif not should_highlight and _is_highlighted:
		_is_highlighted = false
		_pop_unhighlight()

func genCustomer() -> void:
	var fadeTween = create_tween()
	var text = characterSprites.pick_random()
	while text in control.spritesUsed.values():
		text = characterSprites.pick_random()
	sprite.texture = text
	control.spritesUsed[ID] = text
	spriteCorrection()
	fadeTween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), FADE_TIME)
	fadeTween.finished.connect(func(): AudioManager.play_customer_arrive())
	if GameManager.auto_show_orders:
		fadeTween.finished.connect(_show_bubble)

func changeMood() -> void:
	var spriter = characterSprites.find(sprite.texture)
	if spriter == -1:
		spriter = neutralSprites.find(sprite.texture)
	if mood == 2:
		sprite.texture = neutralSprites[spriter]
	elif mood == 1:
		sprite.texture = angrySprites[spriter]
	# Update the bubble background to angry sprite if visible
	if is_instance_valid(b) and b.has_node("Sprite2D"):
		b.get_node("Sprite2D").texture = angryBubble if mood == 1 else bubble

func spriteCorrection() -> void:
	if sprite.texture == charSprite1:
		sprite.position += Vector2(25, 0)
	elif sprite.texture == charSprite3:
		sprite.position += Vector2(-25, 0)
	elif sprite.texture == charSprite4:
		sprite.position += Vector2(-25, 60)

# --- Bubble management ---

func _show_bubble() -> void:
	if b != null or not control.currentCustomer.has(ID):
		return
	b = orderBubble.instantiate()
	b.SPRITE = angryBubble if mood == 1 else bubble
	b.scale = Vector2(0, 0)
	b.z_as_relative = false
	b.z_index = 10
	b.position = control.currentCustomer[ID] + Vector2(125, 200)
	control.add_child(b)
	var openTween = create_tween()
	openTween.tween_property(b, "scale", Vector2(0.65, 0.65), 0.1)
	openTween.finished.connect(func():
		if not control.currentCustomer.has(ID):
			return
		c = orderAmount.instantiate()
		c.offset = control.currentCustomer[ID] + Vector2(25, yFIx)
		c.cusID = ID
		if is_instance_valid(c) and not c.is_inside_tree():
			control.add_child(c)
	)

func _hide_bubble() -> void:
	if b == null:
		return
	if is_instance_valid(c):
		c.queue_free()
	c = null
	var closeTween = create_tween()
	closeTween.tween_property(b, "scale", Vector2(0, 0), 0.1)
	var ref = b
	b = null
	closeTween.finished.connect(func():
		if is_instance_valid(ref):
			ref.queue_free()
	)

func _refresh_bubble() -> void:
	if b == null:
		return
	# Update bubble sprite for angry state
	if is_instance_valid(b) and b.has_node("Sprite2D"):
		b.get_node("Sprite2D").texture = angryBubble if mood == 1 else bubble
	# Rebuild order contents with new order
	if is_instance_valid(c):
		c.queue_free()
	c = null
	if not control.currentCustomer.has(ID):
		return
	c = orderAmount.instantiate()
	c.offset = control.currentCustomer[ID] + Vector2(0, yFIx)
	c.cusID = ID
	if not c.is_inside_tree():
		control.add_child(c)

# --- Mouse hover (used in either mode for trgID, and for bubble in hover-only mode) ---

func _on_area_2d_mouse_entered() -> void:
	GameManager.trgID = ID
	if not GameManager.auto_show_orders:
		_show_bubble()

func _on_area_2d_mouse_exited() -> void:
	if GameManager.trgID == ID:
		GameManager.trgID = null
	if not GameManager.auto_show_orders:
		_hide_bubble()

# --- Delivery / removal ---

func serve() -> void:
	var jump = create_tween()
	jump.tween_property(self, "position", self.position + Vector2(0, -25), 0.25)
	jump.tween_property(self, "position", self.position + Vector2(0, 25), 0.25)
	jump.finished.connect(func(): removeCustomer())

func removeCustomer() -> void:
	var fadeAway = create_tween()
	fadeAway.tween_property(self, "modulate", Color(1, 1, 1, 0), FADE_TIME)
	fadeAway.finished.connect(queue_free)
	control.currentCustomer.erase(ID)
	control.spritesUsed.erase(ID)
	control.currentOrders.erase(ID)
	if is_instance_valid(b):
		b.queue_free()
	b = null
	if is_instance_valid(c):
		c.queue_free()
	c = null

func _pop_highlight() -> void:
	sprite.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(sprite, "scale", _base_sprite_scale * 1.3, 0.18)

func _pop_unhighlight() -> void:
	sprite.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
		.tween_property(sprite, "scale", _base_sprite_scale, 0.15)

func _on_emotion_timer_timeout() -> void:
	if mood == 1:
		if is_instance_valid(area):
			area.queue_free()
		if GameManager.trgID == ID:
			GameManager.trgID = null
		AudioManager.play_customer_leave()
		control.customer_left()
		removeCustomer()
	else:
		if GameManager.change_order_on_anger and randi_range(1, changeMaxChance) == 1:
			control.currentOrders.erase(ID)
			control.genOrder(ID)
			_refresh_bubble()
		mood -= 1
		changeMood()
		timer.wait_time = randi_range(control.minWaitTime, control.maxWaitTime)
		timer.start(timer.wait_time)
