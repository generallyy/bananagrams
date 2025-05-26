#tilerack
extends Control

@onready var tile_container: HBoxContainer = $PanelContainer/HBoxContainer

func _ready():
	print("TileRack owned by: %s | Am I authority? %s" % [get_multiplayer_authority(), is_multiplayer_authority()])


func add_tile(letter: String):
	var tile = preload("res://scenes/ControlTile.tscn").instantiate()
	tile.letter = letter
	#move_to_front()
	
	tile_container.add_child(tile)
	tile.set_multiplayer_authority(multiplayer.get_unique_id())
	
	#await get_tree().process_frame


	print("Tile owned by: %s | My ID: %s | Am I authority? %s" % [
		tile.get_multiplayer_authority(),
		multiplayer.get_unique_id(),
		tile.is_multiplayer_authority()
	])



func remove_tile(tile: Node):
	if tile.get_parent() == tile_container:
		tile_container.remove_child(tile)
