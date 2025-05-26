extends Area2D

@export var board: Node  # set this to PlayerBoard

@export var box_size := Vector2(64, 64)
@export var fill_color := Color("#5c1712")
@export var border_color := Color("#444")
@export var border_width := 2.0


#func _can_drop_data(_pos, data):
	#print("wait what")
	#return data.has("letter")
#
#func _drop_data(_pos, data):
	#var cell_pos = Vector2i(position / board.cell_size)
	#var tile = data["source"]
	#tile.get_parent().remove_child(tile)
	#add_child(tile)
	#tile.position = Vector2.ZERO  # center inside cell
#
	#board.board_state[cell_pos] = tile.letter

func _draw():
	# Draw fill
	draw_rect(Rect2(Vector2.ZERO, box_size), fill_color)

	# Draw border
	draw_line(Vector2(0, 0), Vector2(box_size.x, 0), border_color, border_width)
	draw_line(Vector2(box_size.x, 0), Vector2(box_size.x, box_size.y), border_color, border_width)
	draw_line(Vector2(box_size.x, box_size.y), Vector2(0, box_size.y), border_color, border_width)
	draw_line(Vector2(0, box_size.y), Vector2(0, 0), border_color, border_width)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("🟢 Cell clicked at:", global_position)
