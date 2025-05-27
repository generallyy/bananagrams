#tilerack
extends Node2D

@onready var tile_layer: Node2D = $TileLayer
@onready var queue_label: Label = $QueueAmount
var tile_spacing = 70
var rack_limit = 7
var rack = []
var rack_queue = []

func _ready():
	rack.resize(rack_limit)

func add_tile(letter: String):
	if tile_layer.get_child_count() < rack_limit:
		_spawn_tile(letter)
	else:
		rack_queue.append(letter)
		update_queue_label()

func _spawn_tile(letter: String):
	var tile = preload("res://scenes/NodeTile.tscn").instantiate()
	tile.letter = letter
	tile.set_multiplayer_authority(multiplayer.get_unique_id())

	var index = get_first_null(rack)	# should hypothetically never be -1
	#print("index: %d" % index)
	tile.position = Vector2(index * tile_spacing, 0)
	
	rack[index] = tile

	tile_layer.add_child(tile)
	#await get_tree().process_frame
func get_first_null(arr: Array) -> int:
	for i in arr.size():
		if arr[i] == null:
			return i
	return -1

func remove_tile(tile: Node):
	if tile.get_parent() == tile_layer:
		var index = rack.find(tile)
		print("index %d" % index)
		if index != -1:
			rack[index] = null
			tile_layer.remove_child(tile)
		
		
		
			# If there's something in the queue, add it now
			if rack_queue.size() > 0:
				var next_letter = rack_queue.pop_front()
				_spawn_tile(next_letter)
				update_queue_label()
				
func update_queue_label():
	queue_label.text = "Tiles Queued: %d" % rack_queue.size()
	
