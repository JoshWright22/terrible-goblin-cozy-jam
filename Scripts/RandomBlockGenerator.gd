extends Node

const fruitpiece = [Vector2i(0,0), Vector2i(-1,0), Vector2i(-2,0), Vector2i(1,0)]

var pieces_node = load("res://Scenes/FruitPiece.tscn.tscn").instantiate();

func get_random_piece(called_by_piece) -> Array:
	var piece = []
	var rnd_number = randi() % 1
	match rnd_number:
		0: piece += fruitpiece
	return piece

func spawn_piece(piece_name):
	var piece = pieces_node.get_node(piece_name).duplicate();
	add_child(piece);
