extends Node2D

#check if theres a trgID 
#pass dict in same format as currectOrders through GameMaster.slushiData(yourDict)
#see debug scene example code

var smoothie : Dictionary = {}
var trgID = null

func _ready() -> void:
	pass 


func slushiData(output) -> void:
	smoothie = output
	get_tree().call_group("orderControl", "compareValues")
