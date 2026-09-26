extends Resource
class_name Campaign

# A set of days played in order on the calendar

@export var id: String = "summer"
@export var title: String = "Summer Campaign"
@export var days: Array[DayConfig] = []
@export var stars_to_unlock: int = 0      # total stars from earlier campaigns
@export var unlock_hint: String = ""
@export var end_tint: Color = Color(1.0, 0.86, 0.74)  # shop lighting at closing time

func day_count() -> int:
	return days.size()
