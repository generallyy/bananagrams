# Main
extends Control

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@onready var start_menu = get_node("Start Menu")
@onready var top_label = $Label
@onready var right_panel = $PeersPanel/MarginContainer/PanelNames
@onready var name_field = get_node("Start Menu/VBoxContainer/NameField")
var player_names = {}
var next_default_name = 1


#func _ready():
	#start_menu.visible = true


func _on_host_pressed():
	peer.create_server(135)
	on_join_setup()

func _on_join_pressed():
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	peer.create_client("localhost", 135)
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server():
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	on_join_setup()

# things that both host and client must do. 
func on_join_setup():
	start_menu.visible = false
	if not multiplayer.peer_connected.is_connected(_add_player):
		multiplayer.peer_connected.connect(_add_player)
	if not multiplayer.peer_disconnected.is_connected(_on_player_disconnected):
		multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	var my_id = peer.get_unique_id()
	_add_player(my_id)  # So your own board appears!

	multiplayer.multiplayer_peer = peer

	var player_name = name_field.text.strip_edges()
	send_name_to_host(player_name)

	
func update_player_ui():
	var my_id = multiplayer.get_unique_id()
	top_label.text = "You (%s)" % player_names.get(my_id, "unnamed")

	# Clear existing right panel
	for child in right_panel.get_children():
		child.queue_free()

	var all_ids = Array(multiplayer.get_peers()) #+ [1]  # add host manually if not self
	if not all_ids.has(my_id):	# add host.
		all_ids.append(my_id)

	all_ids.sort_custom(Callable(self, "_sort_by_player_name"))

	for id in all_ids:
		if id == my_id:
			continue  # skip yourself

		var label = Label.new()
		label.text = player_names.get(id, "Player %d" % id)
		right_panel.add_child(label)

func _sort_by_player_name(a, b) -> bool:
	return player_names.get(a, "").to_lower() < player_names.get(b, "").to_lower()

func _add_player(id = 1):
	print("----------------- ADDING PLAYER ------------------")
	if has_node(str(id)):
		print("Player %d already added; skipping" % id)
		return
	print("++ Adding Player %d (mine? %s)" % [id, id == multiplayer.get_unique_id()])


	var player = player_scene.instantiate()
	player.name = str(id)
	if id == multiplayer.get_unique_id():
		player.set_multiplayer_authority(id)  # ✅ before add_child
	call_deferred("_finalize_add_player", player, id)
	
	# If I'm the host and this is not me, send all existing names to the new guy
	#bug fix#
	# this is so that the player only creates the board for himself.
	#if multiplayer.is_server() and id != multiplayer.get_unique_id():
		#for other_id in player_names.keys():
			#if other_id != id:
				#broadcast_name_to_all.rpc_id(id, other_id, player_names[other_id])  # tell the new player
	#update_player_ui()
	
func _finalize_add_player(player, id):
	add_child(player)
	await get_tree().process_frame

	# Send name sync info from host to new peer
	if multiplayer.is_server() and id != multiplayer.get_unique_id():
		for other_id in player_names.keys():
			if other_id != id:
				broadcast_name_to_all.rpc_id(id, other_id, player_names[other_id])

	update_player_ui()

	
@rpc("any_peer")
func send_name_to_host(player_name: String):
	if multiplayer.is_server(): 	#register as host.
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == 0:
			sender_id = multiplayer.get_unique_id()
		
		if player_name.is_empty():
			player_name = "Player %d" % (player_names.size() + 1)
			next_default_name += 1
		# store and send names
		player_names[sender_id] = player_name
		
		# now broadcast.
		broadcast_name_to_all.rpc(sender_id, player_name)
		
		# this is so that player 1 can see himself
		broadcast_name_to_all(sender_id, player_name)
	else:	# client oof
		send_name_to_host.rpc_id(1, player_name)
		
@rpc("authority")
func broadcast_name_to_all(id: int, player_name: String):
	player_names[id] = player_name
	update_player_ui()

func _on_player_disconnected(id):
	player_names.erase(id)
	update_player_ui()
