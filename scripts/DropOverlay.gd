extends Control

@onready var board := get_parent().get_parent()  # Reference to PlayerBoard (adjust if needed)

var is_dragging_tile = false
@onready var zoom_container = board.get_node("SubViewportContainer/SubViewport/ZoomContainer")
@onready var grid_cells = board.get_node("SubViewportContainer/SubViewport/ZoomContainer/GridCells")
@onready var tile2d_scene = preload("res://scenes/NodeTile.tscn")
func _ready():
	set_mouse_filter(MOUSE_FILTER_PASS)


func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	print("🟢 drop target activated!")
	#return data.has("letter") and data.has("source")
	# allows dropoveraly to receive events during a drag operation.
	set_mouse_filter(MOUSE_FILTER_STOP)
	return data.has("letter") and data.has("source")

func _drop_data(_pos: Vector2, data: Variant) -> void:
	print("🔵 dropped tile:", data)

	if not board.is_multiplayer_authority():
		return

	var control_tile: Control = data["source"]
	
	var letter = control_tile.letter
	
	# creating a area2D tile
	var tile2d = tile2d_scene.instantiate()
	tile2d.letter = letter

	# get mouse pos in zoom container's local space
	#var local_zoomed_pos = zoom_container.get_global_transform().affine_inverse() * get_global_mouse_position()
	var local_zoomed_pos = zoom_container.get_local_mouse_position()
	# snap into zoomed local space
	var cell_size = board.cell_size
	var tile_snapped = (local_zoomed_pos / cell_size).floor() * cell_size
	var board_index = Vector2i(tile_snapped / cell_size)

	## Move tile to board
	#tile.reparent(board)
	#tile.global_position = board.to_global(tile_snapped)
	#tile.modulate = Color(1, 1, 1, 1)

	# set parent to teh grid cells node
	# gridcells
	#tile.reparent(grid_cells)	like ok unc

	grid_cells.add_child(tile2d)
	tile2d.position = tile_snapped
	
	# Update board state
	board.board_state[board_index] = tile2d.letter

	# Remove from TileRack
	board.tile_rack.remove_tile(control_tile)
	control_tile.queue_free()
	# Let mouse events pass through again
	set_mouse_filter(MOUSE_FILTER_PASS)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#func _gui_input(event):
	#if event is InputEventMouse:
		#board._input(event)
