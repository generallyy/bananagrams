extends Area2D

@export var letter: String = "A"

func _ready():
	add_to_group("draggable_tile")

func _get_drag_data(position):
	return self

func _can_drop_data(position, data):
	return false

func _drop_data(position, data):
	get_parent().add_child(data)
	data.position = Vector2.ZERO
	
