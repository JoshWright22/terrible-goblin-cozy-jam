extends SceneTree

# Run with: godot --headless --path . --script res://Tests/carnival_mechanics.gd
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var gm = root.get_node("GameManager")
	var campaign = load("res://Resource/Campaigns/boardwalk.tres")
	# Each day must introduce something not already taught in this campaign.
	var introductions := ["prize_customers", "overheat", "belt_stops", "shifty_fruit", "fading_orders", "night_shift", "rush_orders", "allergy_orders", "power_outage", "min_accuracy", "double_orders", "mystery_orders", "frozen_chance", "varied_recipes", "critic_orders", "belt_speed_scale", "sticky_fruit"]
	var defaults = load("res://Scripts/day_config.gd").new()
	check(campaign.days.size() == 18, "18 carnival days")
	for index in introductions.size():
		var rule: String = introductions[index]
		check(campaign.days[index].get(rule) != defaults.get(rule), "Day %d introduces %s" % [index + 1, rule])
		for earlier in index:
			check(campaign.days[earlier].get(rule) == defaults.get(rule), "%s must be new on day %d" % [rule, index + 1])
	# Finale must include every setting-based mechanic, not just a selected remix.
	var mechanics := introductions + ["combo"]
	for day in campaign.days.slice(0, 17):
		for rule in mechanics:
			if day.get(rule) != defaults.get(rule):
				check(campaign.days[17].get(rule) == day.get(rule), "Finale includes %s" % rule)
	gm.current_campaign = campaign
	gm.current_day = campaign.days[13]
	var game = load("res://Scenes/Primary/game_loop.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var control = game.get_node("orderControl")
	check(not control.same_recipe({0: 1}, {}), "First cup cannot repeat")
	check(control.same_recipe({0: 1, 1: 1}, {1: 4, 0: 4}), "Proportions ignore size and dictionary order")
	check(not control.same_recipe({0: 1, 1: 1}, {0: 1, 1: 2}), "Changed proportions count as variety")
	check(not control.same_recipe({0: 1, 1: 1}, {0: 1, 2: 1}), "Changed fruit counts as variety")
	gm.smoothies_served = 10
	control.REMAIN_TIME = 10.0
	await serve(control, {0: 2, 1: 2})
	check(gm.score > 0 and control.REMAIN_TIME > 10.0, "First matching cup earns score and health")
	var before: int = gm.score
	control.REMAIN_TIME = 10.0
	await serve(control, {0: 4, 1: 4})
	check(gm.score == before and control.REMAIN_TIME == 10.0, "Repeat earns no score or health")
	check(control.combo == 0, "Repeat breaks combo")
	await serve(control, {0: 3, 1: 1})
	check(gm.score > before and control.REMAIN_TIME > 10.0, "Varied cup earns score and health again")
	await screenshot("mirrors")
	gm.current_day = campaign.days[0]
	before = gm.score
	control.customerNo = 5
	await serve(control, {0: 3, 1: 1})
	check(gm.score > before, "Ordinary days still reward repeated recipes")
	game.queue_free()
	await process_frame
	gm.current_day = campaign.days[16]
	game = load("res://Scenes/Primary/game_loop.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	control = game.get_node("orderControl")
	check(control.last_served_recipe.is_empty(), "Recipe history resets between days")
	var piece = load("res://Scenes/FruitPiece.tscn").instantiate()
	piece.get_node("FruitPiece").fruit_profile = load("res://Resource/banana_1x1.tres")
	game.add_child(piece)
	var fruit = piece.get_node("FruitPiece")
	fruit.is_locked = true
	gm.paused = false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	fruit._on_main_click_area_input(root, click, 0)
	check(fruit.is_locked and not fruit.is_dragging and not gm.fruit_held, "Sticky fruit refuses pickup")
	await create_timer(0.3).timeout
	var grid = game.get_node("GridScene/Blender/Grid")
	var tile = grid.grid_visuals.get_children().filter(func(node): return node.has_meta("is_occupied"))[0]
	tile.set_meta("is_occupied", true)
	tile.set_meta("occupied_by_fruit", fruit)
	grid.blend_grid_into_smoothie()
	check(not tile.get_meta("is_occupied") and grid.is_blending, "Sticky placement still blends and clears its cells")
	gm.paused = true
	await screenshot("sticky")
	game.queue_free()
	await process_frame
	# All finale scenes and effect controllers must load together.
	gm.current_day = campaign.days[17]
	game = load("res://Scenes/Primary/game_loop.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.get_node("orderControl").last_served_recipe.is_empty(), "Finale starts with fresh recipe history")
	await screenshot("finale")
	game.queue_free()
	await process_frame
	print("CARNIVAL_CHECKS: ", "PASS" if failures == 0 else "%d failures" % failures)
	quit(0 if failures == 0 else 1)

func serve(control: Node, ingredients: Dictionary) -> void:
	control._on_customer_s_pawner_timeout()
	var id: int = control.customerNo
	control.currentOrders[id] = {0: 50, 1: 50}
	root.get_node("GameManager").trgID = id
	control.compareValues(ingredients)
	await create_timer(1.2).timeout

func screenshot(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		# Dismiss the intro for a view of the playable HUD without advancing the shift.
		var intro = current_scene.find_child("DayIntro", true, false)
		if intro: intro.get_parent().queue_free()
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("slush_carnival_" + label + ".png"))
