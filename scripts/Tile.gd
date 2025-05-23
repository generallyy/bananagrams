# Tile
extends Control

@export var letter: String = "A"

var is_hovered := false
var dragging := false
var offset := Vector2.ZERO

func _ready():
	add_to_group("draggable_tile")
	mouse_entered.connect(func(): is_hovered = true)
	mouse_exited.connect(func(): is_hovered = false)
		# Optional: update label if you have one
	if has_node("CenterContainer/Label"):
		$CenterContainer/Label.text = letter
	add_to_group("draggable_tile")  # still used to filter clicks on the board


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true

		else:
			dragging = false

func _process(delta):
	if dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		position = mouse_pos - size / 2  # 🔥 center the tile on the mouse

