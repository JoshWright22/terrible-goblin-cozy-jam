extends Node2D

@onready var healthBar = $healthbar/ProgressBar
@onready var customerSpawnTimer = $customerSpawner
@onready var gameOverScene = load("res://Scenes/game_over.tscn")
@onready var customer = load("res://Scenes/customer.tscn")
@onready var score_label: Label = $Label

var gameOver = false
var spritesUsed: Dictionary = {}
var difficulty = "EASY"

@export var customer_spawn_delay: float = 22.0
var game_music: AudioStream = preload("res://Assets/sfx/Smothie vibes.wav")

var _belt_time: float = 0.0
var _customers_started: bool = false
var _music_player: AudioStreamPlayer = null

# Health
var MAX_TIME: float = 60.0
var REMAIN_TIME: float
var ADD_TIME: float = 6.0   # health per star — generous since typeMatch is the gate
var handBreak = false

# Scoring (label node added in scene)

# Customer spawn timing
var positions: Dictionary = {
	1: Vector2(147.4, 340.8),
	2: Vector2(358,   340.8),
	3: Vector2(575,   340.8),
	4: Vector2(778,   340.8)
}

var MED_CUSTOMER_MIN = 8
var MED_CUSTOMER_MAX = 16

var LEAVE_PENALTY_EASY: float = 10.0
var LEAVE_PENALTY_MED:  float = 16.0
var LEAVE_PENALTY_HARD: float = 22.0
var leave_penalty: float = 10.0

var charTimeMin: float
var charTimeMax: float

var MIN_CHAR_TIME_EASY = 11
var MIN_CHAR_TIME_MED  = 7
var MIN_CHAR_TIME_HARD = 4

var MAX_CHAR_TIME_EASY = 18
var MAX_CHAR_TIME_MED  = 11
var MAX_CHAR_TIME_HARD = 6

# Time before customer gets angry
var minWaitTime
var maxWaitTime

var MAX_WAIT_TIME_EASY = 30
var MIN_WAIT_TIME_EASY = 22

var MAX_WAIT_TIME_MED = 18
var MIN_WAIT_TIME_MED = 12

var MAX_WAIT_TIME_HARD = 10
var MIN_WAIT_TIME_HARD = 6

var ITEM_EASY_MIN: int = 2
var ITEM_EASY_MAX: int = 2

var ITEM_MED_MIN: int = 3
var ITEM_MED_MAX: int = 3

var ITEM_HARD_MIN: int = 3
var ITEM_HARD_MAX: int = 3

var itemMin: int
var itemMax: int

# Scoring thresholds
var bestScore = 75   # % match for top score bonus
var medScore  = 50

var customerNo: int = 0
var currentCustomer: Dictionary = {}
var currentOrders: Dictionary = {}
var bannedFruit: Dictionary = {}   # custID -> fruit the customer is allergic to
var mysteryFruit: Dictionary = {}  # custID -> fruit shown as "?" in the bubble

# Campaign day (null in endless)
var day: DayConfig = null
var day_time_left: float = 0.0
var _vip_spawned: bool = false
var _day_finished: bool = false

# Combo twist: good smoothies in a row multiply the score
const COMBO_ACCURACY := 80.0
const COMBO_STEP := 0.25
const COMBO_MAX_MULT := 2.0
var combo: int = 0
var ingredients: Array[FruitData.FruitType] = [
	FruitData.FruitType.BANANA,
	FruitData.FruitType.STRAWBERRY,
	FruitData.FruitType.BLUEBERRY,
	FruitData.FruitType.MANGO,
	FruitData.FruitType.APPLE,
]

func _enter_tree() -> void:
	# Fresh endless rules before the belt and blenders read them in _ready
	GameManager.endless_twists = DayConfig.new()
	GameManager.reset_run_upgrades()

func _ready() -> void:
	GameManager.paused = true
	GameManager.game_over = false
	GameManager.score = 0
	GameManager.fruit_held = false
	GameManager.hold = false
	GameManager.smoothie_quality = 1.0
	GameManager.seen_fruit_types.clear()
	GameManager.day_complete = false
	GameManager.power_out = false
	GameManager.rotations = 0
	GameManager.smoothies_served = 0
	day = GameManager.current_day
	if day:
		day_time_left = day.duration
		customer_spawn_delay = 5.0
		ingredients = ingredients.filter(func(t): return day.allows_fruit(t))
	var _help_layer := CanvasLayer.new()
	_help_layer.layer = 12
	add_child(_help_layer)
	# Each day opens with its intro card, day 1 then runs the hands-on tutorial.
	# Endless jumps straight in.
	if day:
		_help_layer.add_child(load("res://Scenes/day_intro.tscn").instantiate())
		if day.day_number == 1:
			GameManager.tutorial_active = true
			add_child(load("res://Scenes/tutorial_guide.tscn").instantiate())
	else:
		GameManager.tutorial_active = false
		GameManager.paused = false
		_help_layer.queue_free()
		var director: Node = load("res://Scripts/endless_director.gd").new()
		director.name = "EndlessDirector"
		add_child(director)
	_help_layer.tree_exited.connect(_start_game_music, CONNECT_DEFERRED)
	REMAIN_TIME = MAX_TIME
	healthBar.max_value = MAX_TIME
	healthBar.value = MAX_TIME
	var font = load("res://Assets/fonts/slush_font.tres")
	score_label.add_theme_font_override("font", font)
	ButtonFx.outline_label(score_label, 72)
	score_label.text = "Score: 0"

func _update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d" % GameManager.score

func _process(delta: float) -> void:
	if not _customers_started and not GameManager.paused:
		_belt_time += delta
		if _belt_time >= customer_spawn_delay:
			_customers_started = true
			customerSpawnTimer.start(customerSpawnTimer.wait_time)

	if currentCustomer.size() != 0 and not handBreak and not GameManager.paused and not GameManager.hold and not GameManager.tutorial_active:
		REMAIN_TIME -= delta * (GameManager.rogue_pressure if day == null else 1.0)
		healthBar.ratio = REMAIN_TIME / MAX_TIME

	if day and not _day_finished and not GameManager.paused and not gameOver and not GameManager.tutorial_active:
		day_time_left -= delta
		if day_time_left <= 0.0:
			_finish_day()

	if REMAIN_TIME <= 0 and not gameOver and not _day_finished:
		gameOver = true
		GameManager.game_over = true
		GameManager.paused = true
		AudioManager.play_game_over()
		_stop_game_music()
		customerSpawnTimer.stop()
		currentCustomer.clear()
		get_tree().paused = true

	if GameManager.paused:
		customerSpawnTimer.paused = true
	else:
		if customerSpawnTimer.is_paused():
			customerSpawnTimer.paused = false

func _finish_day() -> void:
	_day_finished = true
	day_time_left = 0.0
	GameManager.day_complete = true
	GameManager.paused = true
	customerSpawnTimer.stop()
	_stop_game_music()
	GameManager.stars_before_day = SaveManager.total_stars()
	SaveManager.record_day(GameManager.current_campaign.id, day.day_number, day.stars_for_score(GameManager.score))
	get_tree().paused = true

# Returns the score multiplier for this serve and shows the combo popup
func _update_combo(good: bool) -> float:
	if not good:
		if combo >= 2:
			_combo_popup("Combo lost", Color(1.0, 0.55, 0.5))
		combo = 0
		return 1.0
	combo += 1
	var mult := minf(1.0 + COMBO_STEP * (combo - 1), COMBO_MAX_MULT)
	if combo >= 2:
		_combo_popup("Combo x%.2f" % mult, Color(1.0, 0.84, 0.35))
	return mult

func _combo_popup(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_constant_override("outline_size", 12)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = score_label.position + Vector2(250, 0)
	lbl.z_index = 20
	add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 70.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.1).set_delay(0.5)
	tw.finished.connect(lbl.queue_free)

# Usable cells per blender, so a packed small blender scores like a packed big one
func blender_cells() -> int:
	if day == null:
		return 16
	return maxi(1, day.grid_size * day.grid_size - day.rotten_cells)

func _arc_pos(start: Vector2, end: Vector2, arc_h: float, t: float) -> Vector2:
	return Vector2(
		lerp(start.x, end.x, t),
		lerp(start.y, end.y, t) - arc_h * sin(t * PI)
	)

func _start_game_music() -> void:
	if game_music == null or not is_inside_tree() or is_queued_for_deletion() or get_parent().is_queued_for_deletion():
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = game_music
	_music_player.bus = "Music"
	_music_player.volume_db = -60.0
	add_child(_music_player)
	_music_player.finished.connect(_music_player.play)
	_music_player.play()
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", 0.0, 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _stop_game_music() -> void:
	if _music_player == null or not is_instance_valid(_music_player):
		return
	if _music_player.finished.is_connected(_music_player.play):
		_music_player.finished.disconnect(_music_player.play)
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", -60.0, 0.4)
	tw.finished.connect(_music_player.stop)

func _animate_score(from_val: int, to_val: int) -> void:
	var gain := to_val - from_val
	if gain <= 0:
		_update_score_display()
		return
	var dur := clampf(float(gain) / 250.0, 0.35, 1.6)
	var tw := create_tween()
	tw.tween_method(
		func(v: float): score_label.text = "Score: %d" % int(v),
		float(from_val), float(to_val), dur
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		var base_sz := 72
		var peak_sz := mini(base_sz + int(float(gain) / 10.0), 88)
		var punch := score_label.create_tween()
		punch.tween_method(
			func(s: int): score_label.add_theme_font_size_override("font_size", s),
			base_sz, peak_sz, 0.09
		)
		punch.tween_method(
			func(s: int): score_label.add_theme_font_size_override("font_size", s),
			peak_sz, base_sz, 0.22
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _flash_health_bar() -> void:
	var tw := healthBar.create_tween()
	tw.tween_property(healthBar, "modulate", Color(1.4, 2.2, 1.4), 0.07)
	tw.tween_property(healthBar, "modulate", Color(1.0, 1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD)

func compareValues(inputer) -> void:
	var trger = GameManager.trgID
	GameManager.trgID = null
	var custom = find_child("Customer_" + str(trger), true, false)
	var wants_another: bool = custom.orders_left > 1
	if wants_another:
		custom._hide_bubble()
	else:
		if custom.area != null:
			custom.area.queue_free()
		if custom.c != null and custom.b != null:
			custom.c.queue_free()
			custom.b.queue_free()

	# Did the player include all required fruit types?
	var typeMatch := true
	for key in currentOrders[trger]:
		if key not in inputer:
			typeMatch = false
			break
	# Allergy orders: the banned fruit ruins the drink
	if bannedFruit.get(trger, -1) in inputer:
		typeMatch = false

	# Convert inputer counts → percentages to compare against the order
	var total_count: int = 0
	for v in inputer.values():
		total_count += v
	var inputer_perc: Dictionary = {}
	for key in inputer:
		inputer_perc[key] = float(inputer[key]) / float(total_count) * 100.0

	# Accuracy: sum of min(given%, ordered%) — 100 = perfect match
	var percent: float = 0.0
	for key in currentOrders[trger]:
		if key in inputer_perc:
			percent += minf(inputer_perc[key], float(currentOrders[trger][key]))

	# Stars for health: mood determines max stars, typeMatch is the gate
	var moodStars: int = max(0, int(custom.mood))
	var stars: int = moodStars if typeMatch else 0
	# Food critic: close isn't good enough
	var twists := GameManager.twists()
	var too_sloppy: bool = percent < twists.min_accuracy
	if too_sloppy:
		stars = 0

	# Score — fill multiplier rewards packing the blender (7x when full)
	var cells := blender_cells()
	var fill_ratio: float = clamp(float(total_count) / float(cells), 0.0, 1.0)
	var fill_bonus: float = 1.0 + pow(fill_ratio, 2.0) * 6.0
	var scoreGain: int = 0
	if typeMatch:
		# Normalise to a 16 cell blender so small blenders aren't punished
		var cell_scale: float = 16.0 / float(cells)
		scoreGain = int(round(100.0 * (percent / 100.0) * float(total_count) * cell_scale * GameManager.smoothie_quality * fill_bonus * custom.score_mult))
		if too_sloppy:
			scoreGain /= 2
	if twists.combo:
		scoreGain = int(round(scoreGain * _update_combo(typeMatch and percent >= COMBO_ACCURACY)))
	if day == null:
		scoreGain = int(round(scoreGain * GameManager.rogue_score_mult))
	GameManager.smoothies_served += 1
	var old_score := GameManager.score
	GameManager.score += scoreGain
	GameManager.smoothie_quality = 1.0
	_animate_score(old_score, GameManager.score)

	# Score popup — size and float height scale with gain
	var gain_scale := clampf(0.8 + float(scoreGain) / 280.0, 0.8, 2.2)
	var cc = load("res://Scenes/percent_score.tscn").instantiate()
	if percent >= bestScore and typeMatch:
		cc.modulate = Color(0.2, 1.0, 0.4)
	elif typeMatch:
		cc.modulate = Color(1, 1, 0)
	else:
		cc.modulate = Color(1, 0.2, 0.2)
	cc.scale = Vector2(gain_scale, gain_scale)
	cc.score_gain = scoreGain

	# Face texture based on stars earned
	var texturez = load("res://Assets/sprites/orderWindowSprites/face1Sprite.PNG")
	if stars == 3:
		texturez = load("res://Assets/sprites/orderWindowSprites/face2Sprite.PNG")
	elif stars == 2:
		texturez = load("res://Assets/sprites/orderWindowSprites/face3Sprite.PNG")
	elif stars == 1:
		texturez = load("res://Assets/sprites/orderWindowSprites/face4Sprite.PNG")

	# Stars arc to health bar — staggered simultaneous launch
	if stars > 0:
		var star_scene: PackedScene = load("res://Scenes/control_add_time.tscn")
		handBreak = true
		var arc_h    := clampf(100.0 + float(scoreGain) * 0.35, 100.0, 280.0)
		var fly_dur  := clampf(0.62 - float(scoreGain) * 0.0007, 0.28, 0.62)
		var health_target := Vector2(102, 80)
		var last_tween: Tween = null

		for i in range(stars):
			var s := star_scene.instantiate()
			s.textures = texturez
			var start_pos: Vector2 = currentCustomer[trger] + Vector2(randf_range(0, 60), randf_range(-20, 20))
			s.position = start_pos
			s.scale    = Vector2.ONE * clampf(0.45 * gain_scale * 0.75, 0.3, 0.85)
			add_child(s)

			var stagger   := float(i) * 0.16
			var this_arc  := arc_h + randf_range(-30.0, 30.0)

			var arc_fn := func(t: float):
				if is_instance_valid(s):
					s.position = _arc_pos(start_pos, health_target, this_arc, t)
					s.rotation = t * TAU * 1.3

			var move := create_tween()
			move.tween_interval(stagger)
			move.tween_method(arc_fn, 0.0, 1.0, fly_dur)
			move.finished.connect(func():
				REMAIN_TIME = clamp(REMAIN_TIME + ADD_TIME, 0, MAX_TIME)
				healthBar.ratio = REMAIN_TIME / MAX_TIME
				AudioManager.play_health_gain()
				_flash_health_bar()
				if is_instance_valid(s):
					s.queue_free()
			)
			last_tween = move

		if last_tween:
			await last_tween.finished
		handBreak = false

	cc.sets = percent
	cc.position = currentCustomer[trger]
	add_child(cc)
	if stars > 0:
		AudioManager.play_customer_happy()
	else:
		AudioManager.play_customer_angry()
	if wants_another and is_instance_valid(custom):
		custom.orders_left -= 1
		genOrder(trger)
		custom.next_order()
	else:
		custom.serve()

func scaleDiff() -> void:
	if customerNo >= MED_CUSTOMER_MIN and customerNo <= MED_CUSTOMER_MAX:
		difficulty = "MEDIUM"
	elif customerNo > MED_CUSTOMER_MAX:
		difficulty = "HARD"
	if day:
		var order := ["EASY", "MEDIUM", "HARD"]
		if order.find(difficulty) > order.find(day.max_difficulty):
			difficulty = day.max_difficulty

	match difficulty:
		"EASY":
			charTimeMin = MIN_CHAR_TIME_EASY
			charTimeMax = MAX_CHAR_TIME_EASY
			itemMin = ITEM_EASY_MIN
			itemMax = ITEM_EASY_MAX
			minWaitTime = MIN_WAIT_TIME_EASY
			maxWaitTime = MAX_WAIT_TIME_EASY
			leave_penalty = LEAVE_PENALTY_EASY
		"MEDIUM":
			charTimeMin = MIN_CHAR_TIME_MED
			charTimeMax = MAX_CHAR_TIME_MED
			itemMin = ITEM_MED_MIN
			itemMax = ITEM_MED_MAX
			minWaitTime = MIN_WAIT_TIME_MED
			maxWaitTime = MAX_WAIT_TIME_MED
			leave_penalty = LEAVE_PENALTY_MED
		"HARD":
			charTimeMin = MIN_CHAR_TIME_HARD
			charTimeMax = MAX_CHAR_TIME_HARD
			itemMin = ITEM_HARD_MIN
			itemMax = ITEM_HARD_MAX
			minWaitTime = MIN_WAIT_TIME_HARD
			maxWaitTime = MAX_WAIT_TIME_HARD
			leave_penalty = LEAVE_PENALTY_HARD
	minWaitTime = minWaitTime * GameManager.twists().patience_scale
	maxWaitTime = maxWaitTime * GameManager.twists().patience_scale
	if day == null:
		minWaitTime *= GameManager.rogue_patience_mult
		maxWaitTime *= GameManager.rogue_patience_mult

func customer_left() -> void:
	AudioManager.play_health_lose()
	var penalty := leave_penalty * (GameManager.rogue_pressure if day == null else 1.0)
	REMAIN_TIME = max(REMAIN_TIME - penalty, 0.0)
	healthBar.ratio = REMAIN_TIME / MAX_TIME
	var tw := healthBar.create_tween()
	tw.tween_property(healthBar, "modulate", Color(2.2, 1.0, 1.0), 0.07)
	tw.tween_property(healthBar, "modulate", Color(1.0, 1.0, 1.0), 0.4).set_trans(Tween.TRANS_QUAD)

func genOrder(custID) -> void:
	var order = {}
	var selectedFruit = []
	var fruitPerc = []
	# Only order fruits the player has actually seen on the belt
	var available = ingredients.filter(func(t): return t in GameManager.seen_fruit_types)
	if available.is_empty():
		available = ingredients  # fallback before any fruit has spawned
	var fruitNo = min(randi_range(itemMin, itemMax), available.size())
	var total: float = 0
	var remainder = 100

	for i in range(fruitNo):
		var select = available.pick_random()
		while select in selectedFruit:
			select = available.pick_random()
		var adder = randi_range(1, 5)
		total += float(adder)
		fruitPerc.append(adder)
		selectedFruit.append(select)

	for i in range(selectedFruit.size() - 1):
		var fPerc = int(float(fruitPerc[i]) / total * 100)
		remainder -= fPerc
		order[selectedFruit[i]] = fPerc
	order[selectedFruit[selectedFruit.size() - 1]] = remainder
	currentOrders[custID] = order

	bannedFruit.erase(custID)
	mysteryFruit.erase(custID)
	var twists := GameManager.twists()
	if twists.allergy_orders and randf() < 0.45:
		var safe_to_ban = available.filter(func(t): return t not in order)
		if not safe_to_ban.is_empty():
			bannedFruit[custID] = safe_to_ban.pick_random()
	if twists.mystery_orders:
		mysteryFruit[custID] = order.keys().pick_random()

func forget_customer(custID) -> void:
	currentOrders.erase(custID)
	bannedFruit.erase(custID)
	mysteryFruit.erase(custID)

func _on_customer_s_pawner_timeout() -> void:
	if currentCustomer.size() != 4:
		customerNo += 1
		customerSpawnTimer.stop()
		scaleDiff()
		var c = customer.instantiate()
		c.name = "Customer_" + str(customerNo)
		var trgPos = positions[randi_range(1, 4)]
		while trgPos in currentCustomer.values():
			trgPos = positions[randi_range(1, 4)]
		c.position = trgPos
		c.ID = customerNo
		var twists := GameManager.twists()
		if day and day.vip_customer and not _vip_spawned and day_time_left < day.duration * 0.6:
			c.kind = "vip"
			_vip_spawned = true
		elif twists.rush_orders and randf() < 0.3:
			c.kind = "rush"
		if twists.double_orders and randf() < 0.4:
			c.orders_left = 2
		currentCustomer[customerNo] = trgPos
		$custWindow/characterSprites/SubViewport.add_child(c)
		genOrder(customerNo)
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)
	else:
		customerSpawnTimer.wait_time = randi_range(charTimeMin, charTimeMax)
		customerSpawnTimer.start(customerSpawnTimer.wait_time)
