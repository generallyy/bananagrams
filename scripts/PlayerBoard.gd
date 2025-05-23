extends Node2D

@export var cell_scene: PackedScene
var board_state := {}  # Dictionary with Vector2i -> letter

var zoom_level := 1.0
var grid_size := 15  # visible range
var cell_size := 64  # pixel size

var is_dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_offset := Vector2.ZERO

@onready var grid_root := $ZoomContainer/BoardLayer/GridCells
@onready var zoom_node := $ZoomContainer
@onready var tile_rack: Control = get_parent().get_node("TileRack")

func _ready():
	draw_visible_grid(Vector2i(0, 0), grid_size)
	
	# THIS IS VERY TEMPORARY OKAY
	tile_rack.add_tile("A")
	tile_rack.add_tile("D")
	tile_rack.add_tile("B")

func draw_visible_grid(center: Vector2i, range: int):
	queue_free_children(grid_root)

	for x in range * 2:
		for y in range * 2:
			var pos = center + Vector2i(x - range, y - range)

			var cell = cell_scene.instantiate()
			cell.board = self
			cell.position = pos * cell_size
			grid_root.add_child(cell)

			# Add tile if one is present
			if board_state.has(pos):
				var tile = make_tile(board_state[pos])
				cell.add_child(tile)

func queue_free_children(node: Node):
	for child in node.get_children():
		child.queue_free()



func make_tile(letter: String) -> Node:
	var tile = preload("res://scenes/Tile.tscn").instantiate()
	tile.letter = letter
	return tile

func _input(event):
	# --- ZOOMING ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level *= 1.1
			zoom_node.scale = Vector2(zoom_level, zoom_level)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level *= 0.9
			zoom_node.scale = Vector2(zoom_level, zoom_level)
			return

		# --- START/STOP DRAGGING ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_clicking_tile():
					return
				is_dragging = true
				drag_start_mouse = event.position
				drag_start_offset = zoom_node.position
			else:
				is_dragging = false

	# --- CONTINUE DRAGGING ---
	elif event is InputEventMouseMotion and is_dragging:
		#var grabby_texture = preload("res://assets/hand_grab.png")
		#Input.set_custom_mouse_cursor(grabby_texture, Input.CURSOR_ARROW, Vector2(16, 16))

		var delta = event.position - drag_start_mouse
		zoom_node.position = drag_start_offset + delta


func is_clicking_tile() -> bool:
	for tile in get_tree().get_nodes_in_group("draggable_tile"):
		if tile.is_hovered:
			return true
	return false

