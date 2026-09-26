class_name Cosmetics

# Every unlockable style option. Stars come from campaign days, "endless" from the endless best score.
# On mobile the star requirements are higher (rewarded ads will speed that up later).

const MOBILE_STAR_SCALE := 1.5

const BLENDER := "blender"
const WALL := "wall"
const BELT := "belt"
const TRANSITION := "transition"
const POUR := "pour"
const PAINT := "paint"

const CATEGORY_NAMES := {
	BLENDER: "Blenders",
	WALL: "Walls",
	BELT: "Conveyor",
	TRANSITION: "Transitions",
	POUR: "Pour style",
	PAINT: "Board paint",
}

# Blender "hue" is the target hue for the blue parts of the blender art (-1 = keep the original blue)
const OPTIONS := {
	BLENDER: [
		{"name": "Classic", "color": Color(0.57, 0.71, 0.87), "hue": -1.0, "stars": 0},
		{"name": "Strawberry", "color": Color(0.95, 0.55, 0.62), "hue": 0.96, "stars": 3},
		{"name": "Mint", "color": Color(0.55, 0.86, 0.7), "hue": 0.42, "stars": 8},
		{"name": "Mango", "color": Color(0.99, 0.72, 0.38), "hue": 0.08, "saturation": 1.1, "value": 1.25, "stars": 14},
		{"name": "Lilac", "color": Color(0.75, 0.62, 0.92), "hue": 0.76, "stars": 20},
		{"name": "Lemon", "color": Color(0.98, 0.9, 0.45), "hue": 0.15, "stars": 28},
		{"name": "Midnight", "color": Color(0.3, 0.32, 0.5), "hue": 0.66, "value": 0.55, "stars": 40},
		{"name": "Gold", "color": Color(0.95, 0.78, 0.3), "hue": 0.12, "saturation": 1.3, "endless": 20000},
	],
	WALL: [
		{"name": "Cream", "color": Color(1, 1, 1), "stars": 0},
		{"name": "Peach", "color": Color(1.0, 0.86, 0.8), "stars": 5},
		{"name": "Mint", "color": Color(0.84, 1.0, 0.9), "stars": 11},
		{"name": "Lilac", "color": Color(0.9, 0.86, 1.0), "stars": 17},
		{"name": "Sky", "color": Color(0.82, 0.93, 1.0), "stars": 24},
		{"name": "Rose", "color": Color(1.0, 0.82, 0.88), "stars": 32},
	],
	BELT: [
		{"name": "Classic", "color": Color(1, 1, 1), "stars": 0},
		{"name": "Candy", "color": Color(1.0, 0.75, 0.85), "stars": 6},
		{"name": "Lime", "color": Color(0.8, 1.0, 0.7), "stars": 13},
		{"name": "Sunset", "color": Color(1.0, 0.8, 0.6), "stars": 22},
		{"name": "Grape", "color": Color(0.8, 0.72, 1.0), "stars": 30},
	],
	TRANSITION: [
		{"name": "Fruit Mix", "color": Color(0.95, 0.52, 0.58), "random": true, "stars": 0},
		{"name": "Tropical", "color": Color(0.99, 0.7, 0.35), "stars": 9},
		{"name": "Berry Blast", "color": Color(0.55, 0.5, 0.85), "stars": 16},
		# Hidden until the game has a green fruit
		{"name": "Green Machine", "color": Color(0.62, 0.82, 0.45), "stars": 26, "hidden": true},
		{"name": "Midnight", "color": Color(0.25, 0.25, 0.45), "stars": 36},
	],
	# How the transition juice moves. "label" is shown on the swatch since these aren't colors
	POUR: [
		{"name": "Pour", "label": "Pour", "style": 0, "color": Color(0.93, 0.6, 0.35), "stars": 0},
		{"name": "Bubbles", "label": "Pop", "style": 1, "color": Color(0.93, 0.6, 0.35), "stars": 6},
		{"name": "Swirl", "label": "Spin", "style": 2, "color": Color(0.93, 0.6, 0.35), "stars": 12},
		{"name": "Splash", "label": "Wave", "style": 3, "color": Color(0.93, 0.6, 0.35), "stars": 19},
	],
	PAINT: [
		{"name": "Cream", "color": Color(1.0, 0.97, 0.9), "stars": 0},
		{"name": "Gold", "color": Color(1.0, 0.84, 0.45), "stars": 7},
		{"name": "Pink", "color": Color(1.0, 0.75, 0.82), "stars": 15},
		{"name": "Mint", "color": Color(0.75, 1.0, 0.85), "stars": 23},
		{"name": "Sky", "color": Color(0.75, 0.9, 1.0), "stars": 34},
	],
}

# Fruit colors the "Fruit Mix" transition picks from: strawberry, mango, blueberry, banana, apple
const FRUIT_COLORS: Array[Color] = [
	Color(0.95, 0.52, 0.58),
	Color(0.99, 0.7, 0.35),
	Color(0.55, 0.5, 0.85),
	Color(0.99, 0.87, 0.45),
	Color(0.9, 0.38, 0.32),
]

# Options the player can see and pick, in order
static func options(category: String) -> Array:
	return OPTIONS[category].filter(func(o): return not o.get("hidden", false))

static func stars_needed(option: Dictionary) -> int:
	var stars: int = option.get("stars", 0)
	if OS.has_feature("mobile"):
		stars = int(ceil(stars * MOBILE_STAR_SCALE))
	return stars

static func is_unlocked(option: Dictionary, total_stars: int = -1, endless_best: int = -1) -> bool:
	if total_stars < 0:
		total_stars = SaveManager.total_stars()
	if endless_best < 0:
		endless_best = SaveManager.endless_best
	if option.has("endless"):
		return endless_best >= option["endless"]
	return total_stars >= stars_needed(option)

static func requirement_text(option: Dictionary) -> String:
	if option.has("endless"):
		return "%d in endless" % option["endless"]
	return "%d stars" % stars_needed(option)

static func selected(category: String) -> Dictionary:
	var index: int = SaveManager.cosmetics.get(category, 0)
	var visible := options(category)
	if index < 0 or index >= visible.size() or not is_unlocked(visible[index]):
		index = 0
	return visible[index]

# Names of options that became available between two star totals, for the day end screen
static func newly_unlocked(stars_before: int, stars_after: int) -> Array[String]:
	var names: Array[String] = []
	for category in OPTIONS:
		for option in options(category):
			if option.has("endless"):
				continue
			if not is_unlocked(option, stars_before, 0) and is_unlocked(option, stars_after, 0):
				names.append("%s %s" % [option["name"], CATEGORY_NAMES[category].to_lower().trim_suffix("s")])
	return names

# Recolors a blender sprite with the chosen blender style
static func apply_blender(sprite: CanvasItem) -> void:
	var option := selected(BLENDER)
	if option["hue"] < 0.0:
		sprite.material = null
		return
	var mat := ShaderMaterial.new()
	mat.shader = load("res://Shaders/recolor.gdshader")
	mat.set_shader_parameter("target_hue", option["hue"])
	mat.set_shader_parameter("saturation_scale", option.get("saturation", 1.0))
	mat.set_shader_parameter("value_scale", option.get("value", 1.0))
	sprite.material = mat

# Wall and conveyor tints for the shop scene
static func apply_shop(game_loop: Node) -> void:
	var wall := game_loop.get_node_or_null("Sprite2D") as CanvasItem
	if wall:
		wall.modulate = selected(WALL)["color"]
	var belt := game_loop.get_node_or_null("Conveyor/Sprite2D") as CanvasItem
	if belt:
		belt.modulate = selected(BELT)["color"]

# The juice color for a scene transition. Fruit Mix picks a random fruit each time
static func transition_color() -> Color:
	var option := selected(TRANSITION)
	if option.get("random", false):
		return FRUIT_COLORS.pick_random()
	return option["color"]
