# pause i don't think i need this
extends Node2D

@onready var board := get_parent()  # Reference to PlayerBoard
@onready var zoom_container := board.get_node("SubViewportContainer/SubViewport/ZoomContainer")
@onready var grid_cells := board.get_node("SubViewportContainer/SubViewport/ZoomContainer/GridCells")
@onready var tile2d_scene := preload("res://scenes/NodeTile.tscn")

var dragging_tile_data: Dictionary = {}  # Example: {"letter": "A", "source": tile_control}

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		## Left mouse down — try placing tile if we have one queued
		#if dragging_tile_data.has("letter"):
			#_place_tile(get_global_mouse_position())
			#dragging_tile_data = {}  # clear drag state
		# trying for dropping a tile (button released)
		_try_snap_hovered_tile()

func _try_snap_hovered_tile():
	if not board.is_multiplayer_authority():
		return

	# Find the tile currently hovered
	for tile in get_tree().get_nodes_in_group("draggable_tile"):
		if tile is Area2D and tile.has_method("is_mouse_hovering") and tile.is_mouse_hovering():
			_snap_tile_to_board(tile)
			break  # Only snap one tile at a time

func _snap_tile_to_board(tile: Area2D):
	var letter = tile.letter
	var cell_size = board.cell_size

	# Get mouse pos in board space
	var local_mouse_pos = zoom_container.get_local_mouse_position()
	var snapped_pos = (local_mouse_pos / cell_size).floor() * cell_size
	var board_index = Vector2i(snapped_pos / cell_size)

	# Remove old position from board_state
	if tile.has_meta("origin_pos"):	# because only board tiles have meta data
		var origin_pos = tile.get_meta("origin_pos")
		board.board_state.erase(origin_pos)

	# Remove from tile rack if it's there
	if tile.get_parent() == board.tile_rack.tile_layer:
		board.tile_rack.remove_tile(tile)
	## Snap and parent to board
	#if tile.get_parent().get_parent() != grid_cells:
		#grid_cells.add_child(tile)
	#tile.position = snapped_pos

	board.board_state[board_index] = board.make_node_tile(letter)
	board.draw_visible_grid()
	print("🟢 Dropped tile:", letter, "to", board_index)
