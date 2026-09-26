extends Resource
class_name DayConfig

# One campaign day. Most twists are just different values here.

@export_group("Info")
@export var day_number: int = 1
@export var title: String = "Opening Day"
@export_multiline var intro_text: String = ""

@export_group("Goal")
@export var duration: float = 150.0             # seconds until the shop closes
@export var star_scores: Array[int] = [800, 2000, 3500]

@export_group("Belt")
@export var fruits: Array[FruitData.FruitType] = []  # empty = all fruits
@export var shapes: PackedStringArray = []           # e.g. "1x1", "3x2_T". empty = all shapes
@export var belt_speed_scale: float = 1.0
@export var spawn_rate_scale: float = 1.0            # >1 spawns fruit faster

@export_group("Customers")
@export_enum("EASY", "MEDIUM", "HARD") var max_difficulty: String = "HARD"
@export var patience_scale: float = 1.0              # >1 = customers wait longer
@export var min_accuracy: float = 0.0                # below this % the customer isn't happy (food critic)

@export_group("Blenders")
@export_range(1, 4) var blender_count: int = 4
@export_range(2, 4) var grid_size: int = 4

@export_group("Twists")
@export var rush_orders: bool = false       # some customers have a short fuse and tip big
@export var allergy_orders: bool = false    # some orders ban a fruit
@export var rotten_cells: int = 0           # blocked cells per blender
@export var heatwave: bool = false          # fruit melts if it sits on the belt too long
@export var frozen_chance: float = 0.0      # chance a piece can't be rotated
@export var mystery_orders: bool = false    # one fruit in each order shows as "?"
@export var night_shift: bool = false       # dark screen, light around the cursor
@export var power_outage: bool = false      # blend buttons flicker off now and then
@export var double_orders: bool = false     # some customers want two smoothies
@export var vip_customer: bool = false      # one VIP per day, big score, short patience

func stars_for_score(score: int) -> int:
	var stars := 0
	for target in star_scores:
		if score >= target:
			stars += 1
	return stars

func allows_shape(fruit_data: FruitData) -> bool:
	if shapes.is_empty():
		return true
	var file := fruit_data.resource_path.get_file().get_basename()  # "apple_3x2_T"
	var shape := file.substr(file.find("_") + 1)                    # "3x2_T"
	return shape in shapes

func allows_fruit(fruit_type: int) -> bool:
	return fruits.is_empty() or fruit_type in fruits
