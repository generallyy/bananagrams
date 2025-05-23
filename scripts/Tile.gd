# Tile
extends Control

@export var letter: String:
	set(value):
		letter = value
		$CenterContainer/Label.text = value

var is_hovered := false

func _ready():
	add_to_group("draggable_tile")
	mouse_filter = Control.MOUSE_FILTER_STOP  # ensure it catches input
	
	mouse_entered.connect(func(): is_hovered = true)
	mouse_exited.connect(func(): is_hovered = false)
		## Optional: update label if you have one
	if has_node("CenterContainer/Label"):
		$CenterContainer/Label.text = letter

func _get_drag_data(_at_position: Vector2) -> Variant:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	
	var preview = self.duplicate()
	#preview.position -= Vector2(32, 32)	# just doesn't work
	if preview.has_node("ColorRect"):
		preview.get_node("ColorRect").position -= preview.size / 2
	if preview.has_node("CenterContainer"):
		preview.get_node("CenterContainer").position -= preview.size / 2
	set_drag_preview(preview)

	#var preview = self.duplicate()
	modulate = Color(1, 1, 1, 0.5)
	#set_visible(false)
#
	#preview.set_deferred("global_position", global_position)
	#
	#set_drag_preview(preview)

	
	return {
		"letter": letter,
		"source": self
	}

func _can_drop_data(_at_position, _data):
	# this removes the "no no" icon... or is supposed to.
	return false  # not a drop target


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#set_drag_preview(duplicate())
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		print("the drag occurs! unc.")
		#pass
		#set_drag_forwarding(this)
		# Triggers get_drag_data next frame
#
#func _process(delta):
	#if dragging:
		#var mouse_pos = get_viewport().get_mouse_position()
		#position = mouse_pos - size / 2  # 🔥 center the tile on the mouse
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		modulate = Color(1, 1, 1, 1)  # Restore original alpha

