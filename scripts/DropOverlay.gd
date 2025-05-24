extends Control

@onready var board := get_parent().get_parent()  # Reference to PlayerBoard (adjust if needed)

var is_dragging_tile = false

func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS)
	print("DropOverlay mouse filter:", mouse_filter)  # Should say "PASS"


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	print("🟢 drop target activated!")
	#return data.has("letter") and data.has("source")
	# allows dropoveraly to receive events during a drag operation.
	set_mouse_filter(MOUSE_FILTER_STOP)
	if data.has("letter") and data.has("source"):
		print("you can drop!")
		return true
	return false

func _drop_data(_pos: Vector2, data: Variant) -> void:
	print("🔵 dropped tile:", data)

	if not board.is_multiplayer_authority():
		return

	var tile: Control = data["source"]
	var local_pos = board.to_local(get_global_mouse_position())
	var tile_snapped = (local_pos / board.cell_size).floor() * board.cell_size
	var board_index = Vector2i(tile_snapped / board.cell_size)

	# Move tile to board
	tile.reparent(board)
	tile.global_position = board.to_global(tile_snapped)
	tile.modulate = Color(1, 1, 1, 1)

	# Update board state
	board.board_state[board_index] = tile.letter

	# Remove from TileRack
	board.tile_rack.remove_tile(tile)

	# Let mouse events pass through again
	set_mouse_filter(MOUSE_FILTER_PASS)
#func _gui_input(event):
	#if event is InputEventMouse:
		#board._input(event)
