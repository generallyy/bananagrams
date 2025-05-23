extends Node2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var info_label = $Label

func create_board():
	print("hello this happened")
	var board = preload("res://scenes/PlayerBoard.tscn").instantiate()
	add_child(board)

func _enter_tree():
	set_multiplayer_authority(name.to_int())


