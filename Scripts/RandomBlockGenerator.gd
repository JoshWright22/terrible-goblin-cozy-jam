extends Node

func _ready() -> void:
	await(spawn_piece(fruitpiece))
	pass

const fruitpiece = [Vector2i(10,10), Vector2i(10,10), Vector2i(10,10), Vector2i(10,10)]

var fruit_piece_packed: PackedScene = load("res://Scenes/FruitPiece.tscn")
var fruit_piece = fruit_piece_packed.instantiate()

func get_random_piece(called_by_piece) -> Array:
	var piece = []
	var rnd_number = randi() % 1
	match rnd_number:
		0: piece += fruitpiece
	return piece



func spawn_piece(fruitpiece):
	var piece = fruit_piece
	add_child(piece);
	fruit_piece.position.x += 1000
	await get_tree().create_timer(4.0).timeout
	fruit_piece.queue_free()
