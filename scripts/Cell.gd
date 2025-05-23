extends Control

@export var board: Node  # set this to PlayerBoard

func _can_drop_data(_pos, data):
	return data.has("letter")

func _drop_data(_pos, data):
	var cell_pos = Vector2i(position / board.cell_size)
	var tile = data["source"]
	tile.get_parent().remove_child(tile)
	add_child(tile)
	tile.position = Vector2.ZERO  # center inside cell

	board.board_state[cell_pos] = tile.letter
