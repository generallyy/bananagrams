extends Node2D



@export var cell_scene: PackedScene
var board_state := {}  # Dictionary with Vector2i -> Tile
var tile_pool = null

var grid_size := 15  # visible range
var cell_size := 64  # pixel size

var is_dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_offset := Vector2.ZERO

@onready var grid_root = $SubViewportContainer/SubViewport/ZoomContainer/GridCells
@onready var zoom_node = $SubViewportContainer/SubViewport/ZoomContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var sanity_dot = zoom_node.get_node("sanity")
@onready var tile_rack = viewport.get_node("TileRack")

func _process(_delta):
	var mouse_pos = viewport.get_mouse_position()
	var world_pos = zoom_node.get_global_transform().affine_inverse() * mouse_pos
	sanity_dot.global_position = zoom_node.to_global(world_pos)

# rpc test
@rpc("call_local")
func shout(msg):
	print("someone says: ", msg)

func _ready():
	if multiplayer.is_server():
		rpc("shout", "hello from the host!")
	print("unique id: ", multiplayer.get_unique_id())
	#print("player board owned by: %s | Am I authority? %s" % [get_multiplayer_authority(), is_multiplayer_authority()])
	board_state[Vector2i(5, 5)] = make_node_tile("C")
	draw_visible_grid(Vector2i(0, 0), grid_size)
	viewport.size = $SubViewportContainer.size
	#print("grid_root's parent is zoom_node? ", grid_root.get_parent() == zoom_node)

	if multiplayer.is_server():
		tile_pool = generate_tile_pool()
	# THIS IS VERY TEMPORARY OKAY
	tile_rack.add_tile("A")


func draw_visible_grid(center: Vector2i = Vector2i(0, 0), tile_range = grid_size):
	queue_free_children(grid_root)

	for x in tile_range * 2:
		for y in tile_range * 2:
			var pos = center + Vector2i(x - tile_range, y - tile_range)

			var cell = cell_scene.instantiate()
			cell.board = self
			cell.position = pos * cell_size
			grid_root.add_child(cell)

			# Add tile if one is present
			# i surmise this is quite cheeky
			if board_state.has(pos):
				var original_tile = board_state[pos]
				var visual_tile = original_tile.duplicate()
				visual_tile.set_meta("origin_tile", original_tile)
				cell.add_child(visual_tile)

func queue_free_children(node: Node):
	for child in node.get_children():
		child.queue_free()

func make_node_tile(letter: String) -> Node:
	var tile = preload("res://scenes/NodeTile.tscn").instantiate()
	tile.letter = letter
	return tile

func _input(event):
	# --- ZOOMING ---
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var mouse_pos = viewport.get_mouse_position()
			var zoom_change = 1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1
			zoom(zoom_change, mouse_pos)
			#return

		# --- START/STOP DRAGGING ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_clicking_tile():
					print("TILES HAVE BEEN CLICKED")
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
		if tile.is_mouse_hovering():
			return true
	return false

func zoom(zoom_change, mouse_position):
	# legoat https://forum.godotengine.org/t/camera2d-zoom-position-towards-the-mouse/28757/5
	zoom_node.scale *= zoom_change
	var delta_x = (mouse_position.x - zoom_node.global_position.x) * (zoom_change - 1)
	var delta_y = (mouse_position.y - zoom_node.global_position.y) * (zoom_change - 1)
	zoom_node.global_position.x -= delta_x
	zoom_node.global_position.y -= delta_y


func _on_peel_pressed():
	# one day we'll put a check in here
	if not multiplayer.is_server():
		rpc_id(1, "request_peel")
	else:
		request_peel()

@rpc("authority")
func request_peel():
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	# Host pulls one tile for each player
	for peer_id in multiplayer.get_peers():
		if tile_pool.size() == 0:
			break
		var tile = tile_pool.pop_back()
		rpc_id(peer_id, "give_tile", tile)
	
	# give host a tile, too :)
	if (tile_pool.size() != 0):
		give_tile(tile_pool.pop_back())

@rpc("any_peer")
func give_tile(tile):
	tile_rack.add_tile(tile)


func _on_swap_pressed():
	pass # Replace with function body.

## helper function
func add_letter(pool: Array, letter: String, count: int) -> void:
	for i in count:
		pool.append(letter)

func generate_tile_pool() -> Array:
	var pool = []

	for l in ["J", "K", "Q", "X", "Z"]:
		add_letter(pool, l, 2)

	for l in ["B", "C", "F", "H", "M", "P", "V", "W", "Y"]:
		add_letter(pool, l, 3)

	add_letter(pool, "G", 4)
	add_letter(pool, "L", 5)

	for l in ["D", "S", "U"]:
		add_letter(pool, l, 6)

	add_letter(pool, "N", 8)

	for l in ["T", "R"]:
		add_letter(pool, l, 9)

	add_letter(pool, "O", 11)
	add_letter(pool, "I", 12)
	add_letter(pool, "A", 13)
	add_letter(pool, "E", 18)

	pool.shuffle()
	return pool
