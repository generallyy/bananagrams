# playerboard
extends Node2D

@export var cell_scene: PackedScene
var board_state := {}  # Dictionary with Vector2i -> Tile
var tile_pool = null

var grid_size := 15  # visible range
var cell_size := 64  # pixel size

var is_dragging := false
var drag_start_mouse := Vector2.ZERO
var drag_start_offset := Vector2.ZERO

var tryna_swap = false
var tilect = 0

@onready var grid_root = $SubViewportContainer/SubViewport/ZoomContainer/GridCells
@onready var zoom_node = $SubViewportContainer/SubViewport/ZoomContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var peel_button = $VBoxContainer/Peel
@onready var swap_button = $VBoxContainer/Swap
@onready var msgbox = $MsgBox
@onready var tile_count = $TileCount
@onready var sanity_dot = zoom_node.get_node("sanity")
@onready var tile_rack = viewport.get_node("TileRack")

func _process(_delta):
	var mouse_pos = viewport.get_mouse_position()
	var world_pos = zoom_node.get_global_transform().affine_inverse() * mouse_pos
	sanity_dot.global_position = zoom_node.to_global(world_pos)

func _ready():
	#modulate.a = .5
	print("unique id: ", multiplayer.get_unique_id())
	#print("player board owned by: %s | Am I authority? %s" % [get_multiplayer_authority(), is_multiplayer_authority()])
	board_state[Vector2i(5, 5)] = make_node_tile("C")
	draw_visible_grid(Vector2i(0, 0), grid_size)
	viewport.size = $SubViewportContainer.size

	if multiplayer.is_server() and get_multiplayer_authority() == 1:
		print("generating tile pool")
		tile_pool = generate_tile_pool()
		host_update_tile_count()
	# THIS IS VERY TEMPORARY OKAY
	tile_rack.add_tile("A")

	if get_multiplayer_authority() != multiplayer.get_unique_id():
		visible = false
	#peel_button.name = "Peel_%s" % get_multiplayer_authority()
	peel_button.connect("pressed", _on_peel_pressed)
	msgbox.visible = false
	


func draw_visible_grid(center: Vector2i = Vector2i(0, 0), tile_range = grid_size):
	queue_free_children(grid_root)

	for x in tile_range * 2:
		for y in tile_range * 2:
			var pos = center + Vector2i(x - tile_range, y - tile_range)

			var cell = cell_scene.instantiate()
			cell.set_multiplayer_authority(get_multiplayer_authority())		# teehee
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
	tile.set_multiplayer_authority(get_multiplayer_authority())
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
				var tile = is_clicking_tile()
				if tile != null:
					print("TILES HAVE BEEN CLICKED")
					if tryna_swap:
						on_swap_tile_clicked(tile)
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


func is_clicking_tile():
	for tile in get_tree().get_nodes_in_group("draggable_tile"):
		if tile.is_mouse_hovering():
			return tile
	return null

func zoom(zoom_change, mouse_position):
	# legoat https://forum.godotengine.org/t/camera2d-zoom-position-towards-the-mouse/28757/5
	zoom_node.scale *= zoom_change
	var delta_x = (mouse_position.x - zoom_node.global_position.x) * (zoom_change - 1)
	var delta_y = (mouse_position.y - zoom_node.global_position.y) * (zoom_change - 1)
	zoom_node.global_position.x -= delta_x
	zoom_node.global_position.y -= delta_y


func _on_peel_pressed():
	# one day we'll put a check in here
	print("🟡 Attempting to request peel from host")
	request_peel.rpc_id(1)  # Tell the host who asked

#
func _on_swap_pressed():
	tryna_swap = not tryna_swap
	if tilect < 3:
		swap_error()
		return
	if tryna_swap:
		msgbox.text = "Please Select a Tile to Remove :p"
		msgbox.visible = true
	else:
		msgbox.visible = false

func swap_error():
	print("not enough tiles to swap!")
	msgbox.text = "Not Enough Tiles to Swap :O"
	msgbox.visible = true
	await get_tree().create_timer(1.0).timeout
	
	msgbox.visible = false
	

func on_swap_tile_clicked(tile):
	tryna_swap = false
	msgbox.visible = false
	
	if tilect < 3:
		swap_error()
		return
	
	var letter = tile.letter
	tile.queue_free()
	
	request_swap.rpc_id(1)
	add_tile_to_bag.rpc_id(1, letter)


@rpc("any_peer", "call_local")
func add_tile_to_bag(letter: String):
	if not multiplayer.is_server():
		print(">>>> YOU HAVE PROBLEMS <<<<")
	else:
		var board = get_node("/root/Main/1/Board_1")
		board.host_add_tile_to_bag(letter)


func host_add_tile_to_bag(letter: String):
	tile_pool.insert(0, letter)
	host_update_tile_count()

@rpc("any_peer", "call_local")
func request_swap():
	if not multiplayer.is_server():
		print(">>>> YOU HAVE PROBLEMS <<<<")
	else:
		var board = get_node("/root/Main/1/Board_1")
		board.host_request_swap()

func host_request_swap():
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1 		# should never occur..?
	if tile_pool.size() < 3:		# should never occur
		swap_error()
		return
	if sender_id == 1:		# when i was testing it was 1... so...
		for i in range (3):
			var tile = tile_pool.pop_back()
			give_tile(tile)
	else:
		for i in range (3):
			var tile = tile_pool.pop_back()
			var board_node = get_node("/root/Main/%s/Board_%s" % [sender_id, sender_id])
			board_node.rpc_id(sender_id, "give_tile", tile)
	


# i genuinely do not know how this works
@rpc("any_peer", "call_local")
func request_peel():
	if not multiplayer.is_server():
		print(">>>> YOU HAVE PROBLEMS <<<<")
	else:
		var board = get_node("/root/Main/1/Board_1")
		board.host_request_peel()

#@rpc("authority")	# this is so weird. authority == get_multiplayer_authority, authority != host
func host_request_peel():
	var sender_id = multiplayer.get_remote_sender_id()
	
	# this also works too?!?!?
	if sender_id == 0:
		sender_id = 1	# actually idk i think it might just be 1 auto
	
	#print("authority: ", get_multiplayer_authority())
	#print("multiplayer_is_server: ", multiplayer.is_server())
	
	# Host pulls one tile for each player
	for peer_id in multiplayer.get_peers():
		if tile_pool.size() == 0:
			print("bag empty!")
			break
		var tile = tile_pool.pop_back()
		
		# get teh board node for this peer and call rpc on it?
		var board_node = get_node("/root/Main/%s/Board_%s" % [peer_id, peer_id])
		board_node.rpc_id(peer_id, "give_tile", tile)
	
	# give host a tile, too :)
	if (tile_pool.size() != 0):
		var host_board = get_node("/root/Main/1/Board_1")
		host_board.give_tile(tile_pool.pop_back())
	
	host_update_tile_count()

## should only be called by authority = 1, is_server(). rpcs the tile count to everyone else to adjust.
func host_update_tile_count():
	print("hello this runs")
	tilect = tile_pool.size()
	print("tilect: ", tilect)
	tile_count.text = "Tiles Left: %d" % tilect
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "update_tile_count", tilect)

@rpc("any_peer")
func update_tile_count(count: int):
	var my_id = multiplayer.get_unique_id()
	var path = "/root/Main/%d/Board_%d/" % [my_id, my_id]
	var board = get_node_or_null(path)
	if board == null:
		print("❌ Couldn't find label for my board at path:", path)
		return
	board.tilect = count
	board.tile_count.text = "Tiles Left: %d" % count

@rpc("any_peer")
func give_tile(tile):
	tile_rack.add_tile(tile)

## helper function
func add_letter(pool: Array, letter: String, count: int) -> void:
	for i in count:
		pool.append(letter)

func generate_tile_pool() -> Array:
	var pool = []
	
	# this is just testing lol
	for l in ["E", "D", "C", "B", "A"]:
		add_letter(pool, l, 1)
#
	#for l in ["J", "K", "Q", "X", "Z"]:
		#add_letter(pool, l, 2)
#
	#for l in ["B", "C", "F", "H", "M", "P", "V", "W", "Y"]:
		#add_letter(pool, l, 3)
#
	#add_letter(pool, "G", 4)
	#add_letter(pool, "L", 5)
#
	#for l in ["D", "S", "U"]:
		#add_letter(pool, l, 6)
#
	#add_letter(pool, "N", 8)
#
	#for l in ["T", "R"]:
		#add_letter(pool, l, 9)
#
	#add_letter(pool, "O", 11)
	#add_letter(pool, "I", 12)
	#add_letter(pool, "A", 13)
	#add_letter(pool, "E", 18)

	pool.shuffle()
	return pool
