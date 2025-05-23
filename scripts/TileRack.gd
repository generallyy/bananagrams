extends Control

@onready var tile_container: HBoxContainer = $PanelContainer/HBoxContainer

func add_tile(letter: String):
	var tile = preload("res://scenes/Tile.tscn").instantiate()
	tile.letter = letter
	#move_to_front()
	tile_container.add_child(tile)

func remove_tile(tile: Node):
	if tile.get_parent() == tile_container:
		tile_container.remove_child(tile)
