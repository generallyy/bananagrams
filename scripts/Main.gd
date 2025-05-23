extends Control

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@onready var start_menu = get_node("Start Menu")
@onready var top_label = $Label
@onready var right_panel = $RightPanel/MarginContainer/PanelNames
@onready var name_field = get_node("Start Menu/VBoxContainer/NameField")
var player_names = {}

func _on_host_pressed():
	peer.create_server(135)
	on_join_setup()

func _on_join_pressed():
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	peer.create_client("localhost", 135)
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server():
	print("hi this happens btw")
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	on_join_setup()

# things that both host and client must do. 
func on_join_setup():
	start_menu.visible = false
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	multiplayer.multiplayer_peer = peer
	
	var player_name = name_field.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player %d" % (multiplayer.get_peers().size() + 1)
	
	# store and send names
	player_names[multiplayer.get_unique_id()] = player_name
	send_name_to_host(player_name)

	
func update_player_ui():
	var my_id = multiplayer.get_unique_id()
	top_label.text = "You (%s)" % player_names.get(my_id, "unnamed")

	# Clear existing right panel
	for child in right_panel.get_children():
		child.queue_free()

	var all_ids = multiplayer.get_peers().duplicate() #+ [1]  # add host manually if not self
	if not all_ids.has(my_id):	# add host.
		all_ids.append(my_id)
	
	all_ids.sort()

	for id in all_ids:
		if id == my_id:
			continue  # skip yourself

		var label = Label.new()
		label.text = player_names.get(id, "Player %d" % id)
		right_panel.add_child(label)

func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	
	# If I'm the host and this is not me, send all existing names to the new guy
	if multiplayer.is_server() and id != multiplayer.get_unique_id():
		for other_id in player_names.keys():
			broadcast_name_to_all.rpc_id(id, other_id, player_names[other_id])  # tell the new player
	
	update_player_ui()
	
@rpc("any_peer")
func send_name_to_host(player_name: String):
	if multiplayer.is_server(): 	#register as host.
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == 0:
			sender_id = multiplayer.get_unique_id()
		# now broadcast.
		player_names[sender_id] = player_name
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
