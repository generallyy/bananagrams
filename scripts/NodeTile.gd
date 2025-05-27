# 2dnode tile
extends Area2D

@export var letter: String
var dragging := false
var offset := Vector2.ZERO
var is_hovered = false

func _ready():
	if has_node("CenterContainer/Label"):
		$CenterContainer/Label.text = letter
	set_pickable(true)
	add_to_group("draggable_tile")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("hi this tile exists")
			dragging = true
			offset = get_global_mouse_position() - global_position
		elif not event.pressed:
			dragging = false

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() - offset

func is_mouse_hovering() -> bool:
	return is_hovered
