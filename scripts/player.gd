extends Node2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var info_label = $Label

func _ready():
	update_info()

func update_info():
	if is_multiplayer_authority():
		var player_id = multiplayer.get_unique_id()
		var role = "Host" if multiplayer.is_server() else "Client"
		info_label.text = "Player ID: %d\nRole: %s" % [player_id, role]

func _enter_tree():
	set_multiplayer_authority(name.to_int())


