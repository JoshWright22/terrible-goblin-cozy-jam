extends Node2D

#check if theres a trgID 
#pass dict in same format as currectOrders through GameMaster.slushiData(yourDict)
#see debug scene example code
var hold = false

var smoothie : Dictionary = {}
var trgID = null

func _ready() -> void:
	pass 


func slushiData(output) -> void:
	get_tree().call_group("orderControl", "compareValues", output)
