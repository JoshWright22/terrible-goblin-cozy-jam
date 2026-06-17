extends Node

func _ready() -> void:
	await(spawn_piece(fruitpiece))
	pass

const fruitpiece = [Vector2i(10,10), Vector2i(10,10), Vector2i(10,10), Vector2i(10,10)]

var move_amount := Vector2(-2000,0)
var seconds := 20

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
	piece.position = Vector2(1800, 125)
	add_child(piece)
	var moveTween = create_tween()
	moveTween.tween_property(piece, "position", piece.position + move_amount, seconds)
	moveTween.finished.connect(piece.queue_free)
