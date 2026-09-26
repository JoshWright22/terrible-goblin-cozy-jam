extends Node

# Plays the game by itself for store screenshots and trailers. Does nothing unless the game
# is launched with user args, for example:
#   "Slush Rush.exe" --write-movie take.avi -- --autoplay=summer:6,carnival:1,endless --autoplay-seconds=40
# tools/record_footage.ps1 wraps this. It moves pieces with the same pickup, rotate, place,
# blend and serve code a player triggers, and draws its own cursor so the footage reads like play.

const MOVE_SPEED := 2600.0       # cursor pixels per second
const MIN_MOVE_TIME := 0.18
const GIVE_UP_TRIES := 40         # failed placement checks (about 10 seconds) before blending what's there

var _segments: PackedStringArray = []
var _segment_seconds := 40.0
var _clock := 0.0
var _cursor: Node2D
var _carry: Node2D = null
var _carry_offset := Vector2.ZERO
var _assigned: Dictionary = {}    # grid -> customer ID it's filling for
var _stuck: Dictionary = {}       # grid -> failed placement checks in a row
var _grid_script := preload("res://Scripts/Grid/grid.gd")

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		args[pair[0]] = pair[1] if pair.size() > 1 else ""
	if not args.has("autoplay"):
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_segments = String(args["autoplay"]).split(",", false)
	_segment_seconds = float(args.get("autoplay-seconds", "40"))
	_make_cursor()
	_run.call_deferred()

func _process(delta: float) -> void:
	_clock += delta
	if is_instance_valid(_carry):
		_carry.global_position = _to_world(_cursor.position) + _carry_offset

func _make_cursor() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_cursor = Node2D.new()
	_cursor.position = Vector2(960, 540)
	layer.add_child(_cursor)
	var points := PackedVector2Array([Vector2(0, 0), Vector2(0, 38), Vector2(10, 29), Vector2(17, 45),
		Vector2(24, 42), Vector2(17, 27), Vector2(29, 27)])
	var arrow := Polygon2D.new()
	arrow.polygon = points
	arrow.color = Color.WHITE
	_cursor.add_child(arrow)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color(0.12, 0.1, 0.14)
	_cursor.add_child(outline)

func _run() -> void:
	await _wait(1.0)
	for segment in _segments:
		await _play_segment(segment)
	get_tree().quit()

func _play_segment(segment: String) -> void:
	_assigned.clear()
	_stuck.clear()
	_carry = null
	get_tree().paused = false
	var parts := segment.split(":")
	if parts[0] == "endless":
		GameManager.start_endless()
	else:
		GameManager.current_campaign = GameManager.campaigns[0 if parts[0] == "summer" else 1]
		GameManager.start_day(int(parts[1]))
	await _wait(1.6)
	var end_at := _clock + _segment_seconds
	while _clock < end_at:
		if GameManager.day_complete:
			await _wait(4.0)   # hold on the day end screen for a moment
			break
		if await _handle_overlays():
			continue
		if GameManager.paused or get_tree().paused:
			await _wait(0.2)
			continue
		await _work()
	print("[autoplay] %s done, score %d" % [segment, GameManager.score])

# Day intro cards and Endless upgrade choices, answered the way a player would
func _handle_overlays() -> bool:
	var intro := _find_by_script("res://Scripts/day_intro.gd")
	if intro and not intro.get("_closing"):
		await _wait(3.0)   # let the card be read
		var button: Control = intro.get("_start_btn")
		await _move_cursor(button.get_global_rect().get_center())
		await _wait(0.25)
		intro.call("_close")
		await _wait(0.6)
		return true
	var director: Node = get_tree().current_scene.find_child("EndlessDirector", true, false) if get_tree().current_scene else null
	if director and director.get("_choosing"):
		await _wait(1.5)
		var offers: Array = director.get("_offers")
		var pick := randi() % maxi(offers.size(), 1)
		var screen: Control = director.get("_choice_screen")
		var cards := screen.find_children("*", "Button", true, false)
		if pick < cards.size():
			await _move_cursor((cards[pick] as Control).get_global_rect().get_center())
			await _wait(0.4)
		director.call("_choose_upgrade", pick)
		await _wait(0.5)
		return true
	return false

func _work() -> void:
	var orders := _order_control()
	if orders == null:
		await _wait(0.3)
		return
	# Serve anything already blended
	for grid in _grids():
		var smoothie: Node2D = grid.grid_visuals.get_node_or_null("SmoothieOverlay")
		if smoothie == null or smoothie.is_queued_for_deletion():
			continue
		var customer_id = _assigned.get(grid)
		if customer_id == null or _customer(customer_id) == null:
			customer_id = _free_order([])
		if customer_id != null:
			await _serve(grid, smoothie, customer_id)
			return
	# Fill blenders for waiting orders
	for grid in _grids():
		if grid.out_of_order or grid.is_blending or grid.grid_visuals.get_node_or_null("SmoothieOverlay"):
			continue
		var customer_id = _assigned.get(grid)
		if customer_id == null or not orders.currentOrders.has(customer_id) or _customer(customer_id) == null:
			customer_id = _free_order(_assigned.values())
			if customer_id == null:
				continue
			_assigned[grid] = customer_id
		var order: Dictionary = orders.currentOrders[customer_id]
		var need := _need(grid, order)
		if await _place_piece(grid, need):
			_stuck[grid] = 0
			return
		_stuck[grid] = _stuck.get(grid, 0) + 1
		if _should_blend(grid, order, need):
			await _blend(grid)
			return
	await _wait(0.25)

# --- Reading the shop ---

func _order_control() -> Node:
	return get_tree().get_first_node_in_group("orderControl")

func _grids() -> Array:
	var scene := get_tree().current_scene
	if scene == null:
		return []
	return scene.find_children("*", "Node2D", true, false).filter(func(n): return n.get_script() == _grid_script)

func _conveyor() -> Node:
	var scene := get_tree().current_scene
	return scene.find_child("Conveyor", true, false) if scene else null

func _customer(customer_id) -> Node:
	var orders := _order_control()
	if orders == null:
		return null
	var node := orders.find_child("Customer_" + str(customer_id), true, false)
	if node == null or not is_instance_valid(node.get("area")):
		return null
	return node

func _free_order(taken: Array):
	var orders := _order_control()
	var ids: Array = orders.currentOrders.keys()
	ids.sort()
	for customer_id in ids:
		if customer_id in taken or _customer(customer_id) == null:
			continue
		return customer_id
	return null

func _tiles(grid) -> Array:
	return grid.grid_visuals.get_children().filter(func(t): return t.has_meta("is_occupied") and not t.has_meta("rotten"))

# The smoothie's mix counts pieces, not cells, so plan a handful of pieces in the order's ratio
func _pieces_by_fruit(grid) -> Dictionary:
	var have := {}
	var seen := {}
	for tile in _tiles(grid):
		var piece = tile.get_meta("occupied_by_fruit") if tile.has_meta("occupied_by_fruit") else null
		if is_instance_valid(piece) and not seen.has(piece):
			seen[piece] = true
			have[piece.fruit_profile.fruit_name] = have.get(piece.fruit_profile.fruit_name, 0) + 1
	return have

func _need(grid, order: Dictionary) -> Dictionary:
	var planned := clampi(_tiles(grid).size() / 3, 3, 6)
	var have := _pieces_by_fruit(grid)
	var need := {}
	for fruit in order:
		need[fruit] = maxi(roundi(float(order[fruit]) / 100.0 * planned), 1) - have.get(fruit, 0)
	return need

func _should_blend(grid, order: Dictionary, need: Dictionary) -> bool:
	var have := _pieces_by_fruit(grid)
	for fruit in order:
		if not have.has(fruit):
			return false   # every ordered fruit has to be in there
	var free := _tiles(grid).filter(func(t): return not t.get_meta("is_occupied"))
	var remaining := 0
	for fruit in order:
		remaining += maxi(need[fruit], 0)
	return free.is_empty() or remaining == 0 or _stuck.get(grid, 0) >= GIVE_UP_TRIES

# --- Acting on it ---

func _place_piece(grid, need: Dictionary) -> bool:
	var conveyor := _conveyor()
	if conveyor == null:
		return false
	var candidates := []
	for entry in conveyor.pieces:
		var piece = entry.ctrl
		if not is_instance_valid(piece) or piece.is_locked or piece.detached_from_conveyor or piece.is_dragging:
			continue
		var x: float = piece.global_position.x
		if x < 80.0 or x > 1840.0:
			continue
		var fruit: int = piece.fruit_profile.fruit_name
		if need.get(fruit, 0) < 1:
			continue
		candidates.append(piece)
	candidates.sort_custom(func(a, b): return a.total_block_count > b.total_block_count)
	for piece in candidates:
		var spot := _find_spot(grid, piece)
		if spot.is_empty():
			continue
		await _move_cursor(_to_screen(piece.global_position))
		if not is_instance_valid(piece) or piece.detached_from_conveyor:
			return false
		_pick_up(piece)
		for i in spot.turns:
			piece.rotate_piece_90_degrees()
			await _wait(0.2)
		await _move_cursor(_to_screen(spot.position))
		_carry = null
		GameManager.fruit_held = false
		await get_tree().physics_frame
		await get_tree().physics_frame
		piece.attempt_physical_placement()
		await _wait(0.15)
		return true
	return false

# Where the piece fits, matching attempt_physical_placement's own anchor maths
func _find_spot(grid, piece) -> Dictionary:
	var free := {}
	for tile in _tiles(grid):
		if not tile.get_meta("is_occupied"):
			free[Vector2i(tile.get_meta("grid_x"), tile.get_meta("grid_y"))] = tile
	var keys := free.keys()
	keys.sort_custom(func(a, b): return a.y > b.y or (a.y == b.y and a.x < b.x))   # fill from the bottom
	var detectors: Array = piece.block_detectors.get_children()
	for turns in (1 if piece.frozen else 4):
		var angle: float = piece.target_rotation + turns * PI / 2.0
		var first: Vector2 = detectors[0].position.rotated(angle)
		var offsets := []
		for detector in detectors:
			var delta: Vector2 = (detector.position.rotated(angle) - first) / piece.dynamic_cell_size
			offsets.append(Vector2i(roundi(delta.x), roundi(delta.y)))
		for key in keys:
			var fits := true
			for offset in offsets:
				if not free.has(key + offset):
					fits = false
					break
			if fits:
				return {"turns": turns, "position": free[key].global_position - first}
	return {}

func _pick_up(piece) -> void:
	piece.detached_from_conveyor = true
	GameManager.fruit_held = true
	piece.z_as_relative = false
	piece.z_index = 600
	AudioManager.play_fruit_pickup()
	var pop: Tween = piece.create_tween()
	pop.tween_property(piece, "scale", Vector2(1.18, 1.18), 0.07)
	pop.tween_property(piece, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_carry = piece
	_carry_offset = Vector2.ZERO   # held pieces sit on the cursor, same as a real drag

func _blend(grid) -> void:
	var button: Control = grid.blend_button
	await _move_cursor(button.get_global_rect().get_center())
	grid._on_blend_button_down()
	await _wait(0.12)
	grid._on_blend_button_up()
	grid.blend_grid_into_smoothie()
	_stuck[grid] = 0
	await _wait(0.7)

func _serve(grid, smoothie: Node2D, customer_id) -> void:
	await _move_cursor(_to_screen(smoothie.global_position))
	if not is_instance_valid(smoothie):
		return
	var spin = smoothie.get("_spawn_tween")
	if spin is Tween and spin.is_valid():
		spin.kill()
		smoothie.scale = Vector2.ONE
		smoothie.rotation = 0.0
	GameManager.hold = true
	AudioManager.play_smoothie_pickup()
	_carry = smoothie
	_carry_offset = Vector2.ZERO
	var customer := _customer(customer_id)
	if customer:
		await _move_cursor(_to_screen(customer.area.global_position))
	_carry = null
	customer = _customer(customer_id)
	if customer == null or not is_instance_valid(smoothie):
		GameManager.hold = false
		if is_instance_valid(smoothie):
			smoothie.global_position = smoothie.spawn_position
		return
	GameManager.trgID = customer_id
	await _wait(0.12)
	GameManager.hold = false
	GameManager.smoothie_quality = smoothie.quality
	GameManager.slushiData(smoothie.ingredients_to_dict())
	smoothie.queue_free()
	_assigned.erase(grid)
	await _wait(0.4)

# --- Helpers ---

func _move_cursor(target: Vector2) -> void:
	var time := maxf(_cursor.position.distance_to(target) / MOVE_SPEED, MIN_MOVE_TIME)
	var tween := _cursor.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_cursor, "position", target, time)
	await tween.finished

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen

func _to_screen(world: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world

func _find_by_script(path: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for node in scene.find_children("*", "", true, false):
		var script: Script = node.get_script()
		if script and script.resource_path == path and not node.is_queued_for_deletion():
			return node
	return null
