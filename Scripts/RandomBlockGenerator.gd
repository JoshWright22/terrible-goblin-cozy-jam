extends Node

const long_boy = [Vector2i(0,0), Vector2i(-1,0), Vector2i(-2,0), Vector2i(1,0)]
const z_left = [Vector2i(0,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(1,1)]
const z_right = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,1)]
const quad = [Vector2i(0,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(-1,1)]
const l_left = [Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0), Vector2i(1,1)]
const l_right = [Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,1), Vector2i(1,0)]
const cross = [Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,1)]

func get_random_piece(called_by_piece) -> Array:
	var piece = []
	var rnd_number = randi() % 7
	match rnd_number:
		0: piece += long_boy
		1: piece += z_left
		2: piece += z_right
		3: piece += quad
		4: piece += l_left
		5: piece += l_right
		6: piece += cross
	return piece
