extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var gm = root.get_node("GameManager")
	gm.current_campaign = gm.campaigns[1]
	gm.current_day = gm.current_campaign.days[2]
	var fixture := Node2D.new()
	root.add_child(fixture)
	current_scene = fixture
	var belt = load("res://Scenes/Fruit_Conveyor.tscn").instantiate()
	fixture.add_child(belt)
	belt.set_process(false)
	belt._spawn_at(0)
	belt._spawn_at(200)
	var small = belt.pieces[0].ctrl
	var large = belt.pieces[1].ctrl
	small.change_fruit_profile(load("res://Resource/banana_1x1.tres"))
	large.change_fruit_profile(load("res://Resource/banana_3x2_L.tres"))
	gm.paused = false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	for state in ["slow", "stopped", "resumed"]:
		gm.slow_belt_time = 10.0 if state == "slow" else 0.0
		belt._stalled = state == "stopped"
		belt._stall_timer = 10.0
		belt.spawn_timer = 10.0
		belt._process(0.016)
		var point: Vector2 = small.get_global_mouse_position()
		small.global_position = point
		var radius: float = large.main_click_area.get_child(0).shape.radius
		large.global_position = point + Vector2(radius + 20.0, 0)
		await physics_frame
		await physics_frame
		assert(not large._pickup_contains_point(point))
		assert(small._get_overlapping_pieces().is_empty())
		small._on_main_click_area_input(root, click, 0)
		assert(small.is_dragging and gm.fruit_held, state)
		small.is_dragging = false
		gm.fruit_held = false
	# Re-grabbing a returning piece must stop its return animation fighting the cursor.
	small.return_to_spawn()
	var returning: Tween = small._return_tween
	small._on_main_click_area_input(root, click, 0)
	assert(small.is_dragging and not returning.is_valid())
	small.is_dragging = false
	gm.fruit_held = false
	fixture.queue_free()
	await process_frame
	print("BELT_PICKUP_OK: slowed, stopped, resumed, and re-grab during return")
	quit()
