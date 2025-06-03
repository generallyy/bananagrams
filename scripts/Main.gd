# Main
extends Control

var peer = ENetMultiplayerPeer.new()
#@export var player_scene: PackedScene
@onready var start_menu = get_node("Start Menu")
@onready var top_label = $Label
@onready var right_panel = $PeersPanel/MarginContainer/PanelNames
@onready var name_field = get_node("Start Menu/VBoxContainer/NameField")

var player_names = {} # dict of id : name
var next_default_name = 1

var connected_peer_ids = []
var local_player_character


#func _ready():
	#start_menu.visible = true


func _on_host_pressed():
	start_menu.visible = false
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	
	add_player_character()
	
	peer.peer_connected.connect(
	func(new_peer_id):
		#await get_tree().create_timer(1).timeout
		rpc("add_newly_connected_player_character", new_peer_id)
		rpc_id(new_peer_id, "add_previously_connected_player_characters", connected_peer_ids)
		add_player_character(new_peer_id)
	)

func _on_join_pressed():
	start_menu.visible = false
	peer.create_client("localhost", 135)
	multiplayer.multiplayer_peer = peer



func add_player_character(peer_id = 1):
	connected_peer_ids.append(peer_id)
	var player_character = preload("res://scenes/player.tscn").instantiate()
	player_character.set_multiplayer_authority(peer_id)
	add_child(player_character)
	if peer_id == multiplayer.get_unique_id():
		local_player_character = player_character

	var player_name = name_field.text.strip_edges()
	send_name_to_host(player_name)

	#print_tree_pretty()

@rpc
func add_newly_connected_player_character(new_peer_id):
	add_player_character(new_peer_id)

@rpc
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		add_player_character(peer_id)

# outdated stuff ig

# things that both host and client must do. 
	
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


@rpc("any_peer")
func send_name_to_host(player_name: String):
	if multiplayer.is_server(): 	#register as host.
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == 0:
			sender_id = multiplayer.get_unique_id()
		
		
		if player_names.has(sender_id):
			player_name = player_names.get(sender_id)
		if player_name.is_empty():
			player_name = "Player %d" % (next_default_name)
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

#func _on_player_disconnected(id):
	#player_names.erase(id)
	#update_player_ui()


