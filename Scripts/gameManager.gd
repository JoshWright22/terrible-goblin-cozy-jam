extends Node2D

@onready var mainMenu = load("res://Scenes/Primary/main_menu.tscn")
@onready var gameLoop = load("res://Scenes/Primary/game_loop.tscn")
@onready var pauseScene = load("res://Scenes/pause_menu.tscn")
@onready var creditsScene = load("res://Scenes/Primary/credits.tscn")
@onready var settingsScene = load("res://Scenes/Primary/settings.tscn")
var paused : bool = false #tells system if game paused


#check if theres a trgID 
#pass dict in same format as currectOrders through GameMaster.slushiData(yourDict)
#see debug scene example code
var hold = false

var smoothie : Dictionary = {}
var trgID = null

var score: int = 0
var fruit_held: bool = false  # prevents picking up two pieces at once
var smoothie_quality: float = 1.0  # set by smoothie before delivery, applied to score
var seen_fruit_types: Array[int] = []  # FruitType ints that have appeared on the belt
var game_over: bool = false

# Campaigns
const CAMPAIGN_PATHS := [
	"res://Resource/Campaigns/summer.tres",
	"res://Resource/Campaigns/boardwalk.tres",
]
@onready var daySelectScene = load("res://Scenes/Primary/day_select.tscn")
@onready var styleScene = load("res://Scenes/Primary/style_shop.tscn")
var campaigns: Array[Campaign] = []
var current_campaign: Campaign = null
var current_day: DayConfig = null   # null = endless mode
var endless_twists: DayConfig = null # endless starts plain and picks up twists as it goes
var daily_run: bool = false          # roguelike run seeded by the date, with set buffs and debuffs
var day_complete: bool = false
var power_out: bool = false          # Power Outage twist: blenders can't blend while true
var stars_before_day: int = 0        # total stars when the day started, for unlock announcements

# Roguelike upgrades last for one run. The old endless save key keeps existing best scores.
var rogue_level: int = 1
var rogue_score_mult: float = 1.0
var rogue_patience_mult: float = 1.0
var rogue_belt_mult: float = 1.0
var rogue_pressure: float = 1.0
var rogue_leave_mult: float = 1.0     # Thick Skin halves walkout damage
var rogue_perfect_mult: float = 1.0   # Perfectionist: extra score on 95%+ smoothies
var rogue_revives: int = 0            # Second Wind

func reset_run_upgrades() -> void:
	rogue_level = 1
	rogue_score_mult = 1.0
	rogue_patience_mult = 1.0
	rogue_belt_mult = 1.0
	rogue_pressure = 1.0
	rogue_leave_mult = 1.0
	rogue_perfect_mult = 1.0
	rogue_revives = 0

# Tutorial: while true, customers are patient and the timers stop
var tutorial_active: bool = false
var rotations: int = 0          # pieces rotated this run
var smoothies_served: int = 0   # smoothies delivered this run

func _ready() -> void:
	for path in CAMPAIGN_PATHS:
		campaigns.append(load(path) as Campaign)
	current_campaign = campaigns[0]

func campaign_unlocked(campaign: Campaign) -> bool:
	return SaveManager.total_stars() >= campaign.stars_to_unlock

func load_day(day_number: int) -> DayConfig:
	return current_campaign.days[day_number - 1]

func start_day(day_number: int) -> void:
	current_day = load_day(day_number)
	daily_run = false
	get_tree().call_group("hostController", "transition_to_scene", gameLoop)

func start_endless() -> void:
	current_day = null
	daily_run = false
	get_tree().call_group("hostController", "transition_to_scene", gameLoop)

func start_daily() -> void:
	current_day = null
	daily_run = true
	get_tree().call_group("hostController", "transition_to_scene", gameLoop)

# Today's UTC date as YYYYMMDD, so everyone gets the same Daily Slush
func daily_seed(days_ago: int = 0) -> int:
	var date := Time.get_date_dict_from_unix_time(int(Time.get_unix_time_from_system()) - days_ago * 86400)
	return date.year * 10000 + date.month * 100 + date.day

func endless_unlocked() -> bool:
	# Steam has every mode open from the start, mobile unlocks them by finishing the first campaign
	var first := campaigns[0]
	return not OS.has_feature("mobile") or SaveManager.unlocked_day(first.id) > first.day_count()

# The twist rules for the current run, campaign day or endless
func twists() -> DayConfig:
	return current_day if current_day else endless_twists

func has_next_day() -> bool:
	return current_day != null and current_day.day_number < current_campaign.day_count()


func slushiData(output) -> void:
	get_tree().call_group("orderControl", "compareValues", output)
