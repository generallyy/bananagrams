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
		#if tile is Area2D and tile.has_method("is_mouse_hovering") and tile.is_mouse_hovering():
		# don't need all that
		if tile.is_mouse_hovering() and tile.dragging:
				_snap_tile_to_board(tile)
				break  # Only snap one tile at a time 

func _snap_tile_to_board(tile: Area2D):
	var letter = tile.letter
	var cell_size = board.cell_size

	# Get mouse pos in board space
	var local_mouse_pos = zoom_container.get_local_mouse_position()
	var snapped_pos = (local_mouse_pos / cell_size).floor() * cell_size
	var board_index = Vector2i(snapped_pos / cell_size)
	
	# if there's a tile beneath that tile
	for other_tile in get_tree().get_nodes_in_group("draggable_tile"):
		if other_tile.is_mouse_hovering() and not other_tile.dragging:
			# board tile dropped onto rack tile → move board tile to rack, no duplication
			if tile.has_meta("origin_pos") and other_tile.get_parent() == board.tile_rack.tile_layer:
				board.board_state.erase(tile.get_meta("origin_pos"))
				board.tile_rack.add_tile(letter)
				board.draw_visible_grid()
				return
			# case 1: tile is on board.
			#			so, swap the positions on the board.
			if tile.has_meta("origin_pos"):	# because only board tiles have meta data
				var origin_pos = tile.get_meta("origin_pos")
				board.board_state[origin_pos] = board.make_node_tile(other_tile.letter)
						# this may not have to be that complicated..?
			# case 2: tile is in rack.
			#			so, remove other_tile from board and add it to rack.
			if tile.get_parent() == board.tile_rack.tile_layer:
				# case 3: other_tile is ALSO in the tile rack.
				if other_tile.get_parent() == board.tile_rack.tile_layer:
					board.tile_rack.remove_tile(tile)
					board.tile_rack.add_tile(tile.letter)
					return # ?
				board.tile_rack.remove_tile(tile)
				board.board_state.erase(other_tile.get_meta("origin_pos"))
				board.tile_rack.add_tile(other_tile.letter)

			board.board_state[board_index] = board.make_node_tile(letter)
			board.draw_visible_grid()
			print("🟢 Two Tiles:    ", letter, " to ", board_index)
			return  # should only be one


	# Remove old position from board_state
	if tile.has_meta("origin_pos"):	# because only board tiles have meta data
		var origin_pos = tile.get_meta("origin_pos")
		board.board_state.erase(origin_pos)

	# Remove from tile rack if it's there
	if tile.get_parent() == board.tile_rack.tile_layer:
		board.tile_rack.remove_tile(tile)

	# If mouse is in the rack area, send tile to rack instead of placing on board
	var vm = board.viewport.get_mouse_position()
	if vm.y >= board.tile_rack.position.y - 32:
		board.tile_rack.add_tile(letter)
		board.draw_visible_grid()
		return

	board.board_state[board_index] = board.make_node_tile(letter)
	board.draw_visible_grid()
	print("🟢 Dropped tile: ", letter, " to ", board_index)
