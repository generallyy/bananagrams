extends Control


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
signal player_ready

@onready var info_label = $Label
@onready var main = get_parent()

func _ready():
	# Called after the node is fully added to the scene tree
	emit_signal("player_ready")
	print("Player owned by: %s | Am I authority? %s" % [get_multiplayer_authority(), is_multiplayer_authority()])
	#if is_multiplayer_authority():
	create_board() # so that everyone can access this board using RPC

func create_board():
	# moving instantiation to playerboard
	#var tile_rack = preload("res://scenes/TileRack.tscn").instantiate()
	#tile_rack.set_multiplayer_authority(get_multiplayer_authority())  # 👈 this
	#add_child(tile_rack)
	var board = preload("res://scenes/PlayerBoard.tscn").instantiate()
	board.set_multiplayer_authority(get_multiplayer_authority())  # 👈 and this
	board.name = "Board_%s" % board.get_multiplayer_authority()
	add_child(board)
	

	# Disable interaction if this peer isn't the authority
	#if not is_multiplayer_authority():
		#board.visible = false  # You can also disable input manually if needed'
		#print("HEYYYYY THIS IS NOT THE AUTHORITY.")
	#else:
		#print("✅ This player owns their board and can interact with it.")


func _enter_tree():
	print(">> Player %s entering tree" % name)
	set_multiplayer_authority(name.to_int())


