extends Node2D
var SPRITE
@onready var sprite2D = $Sprite2D

func _ready() -> void:
	sprite2D.texture = SPRITE
