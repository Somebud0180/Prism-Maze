extends Node3D

signal finished_loading

@onready var player_3d = %Player3D
@onready var _level_3d = preload("res://scenes/3D/level_3d.tscn").instantiate()

@export var level_amount: int = 6

var starting_marker
var levels = [] # The levels in the node
var level_collection = [] # The final level set to be played
var current_level = 0


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("load_level"):
		place_level()


func _ready() -> void:
	# First, handle the starting level
	var starting = _level_3d.get_child(0)
	var copy_starting = starting.duplicate()
	add_child(copy_starting)
	level_collection.append(copy_starting)
	get_child(get_child_count() - 1)._show()
	
	starting_marker = level_collection[0].get_node("EntranceMarker")
	
	# Grab the marker’s global transform
	var spawn_transform = starting_marker.global_transform
	# Adjust the origin slightly so the player doesn't clip into the floor
	spawn_transform.origin += Vector3(0.0, 1.0, 0.0)
	
	# Now place the player at that Marker
	player_3d.global_transform = spawn_transform
	
	emit_signal("finished_loading")


func place_level():
	if current_level < level_amount:
		var next_level = _level_3d.get_next_random_level()
		if next_level:
			add_child(next_level)
			level_collection.append(next_level)
		
		# Show level in level_collection
		get_child(get_child_count() - 1)._show()
		
		var last_level = level_collection[get_child_count() - 2]
		var current_level = level_collection[get_child_count() - 1]
		
		var exit_marker = last_level.get_node("ExitMarker")
		var entrance_marker = current_level.get_node("EntranceMarker")
			
		var exit_global = exit_marker.global_transform
		var entrance_local = entrance_marker.transform
		current_level.global_transform = exit_global * entrance_local.affine_inverse()
		
		# Remove old levels
		cull_levels()


func cull_levels():
	if level_collection.size() > 4 and get_child_count() > 4:
		# Close door of the second oldest level
		level_collection[1].close_door()
		await Signal(level_collection[1], "door_close_animation_finished")
		
		# Remove from both the scene tree and the level_collection
		var removed_level = level_collection[0]
		removed_level.queue_free()
		level_collection.remove_at(0)
