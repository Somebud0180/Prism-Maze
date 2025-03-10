extends Node3D

@onready var player_3d = get_node("/root/Game3D/Player3D")

var level_amount: int = 6

var starting_marker
var levels = [] # The levels in the node
var level_collection = [] # The final level set to be played

func _ready() -> void:
	_get_levels()
	
	# Hide levels
	for i in range(get_child_count()):
		get_child(i)._hide()
	
	# Restore/show every level in level_collection
	for this_level in level_collection:
		this_level._show()
	
	starting_marker = level_collection[0].get_node("EntranceMarker")
	
	# Grab the marker’s global transform
	var spawn_transform = starting_marker.global_transform
	# Adjust the origin slightly so the player doesn't clip into the floor
	spawn_transform.origin += Vector3(0.0, 1.0, 0.0)

	# Now place the player at that Marker
	player_3d.global_transform = spawn_transform
	
	for i in range(level_collection.size() - 1):
		var current_level = level_collection[i]
		var next_level = level_collection[i + 1]
		
		var exit_marker = current_level.get_node("ExitMarker")
		var entrance_marker = next_level.get_node("EntranceMarker")
		
		var exit_global = exit_marker.global_transform
		var entrance_local = entrance_marker.transform
		next_level.global_transform = exit_global * entrance_local.affine_inverse()


func _get_levels():
	level_collection.clear()
	# Always add the starting level first
	var starting = get_child(0)
	level_collection.append(starting)
	
	# Randomly add unique levels from index 1..(child_count-1)
	var used_indices = []
	while level_collection.size() < (level_amount + 1):
		if used_indices.size() == get_child_count() - 1:
			used_indices.clear()
		
		var r = randi_range(1, get_child_count() - 1)
		
		if r not in used_indices:
			used_indices.append(r)
			level_collection.append(get_child(r))
	
	# Requires levels to be added to a separate node (to allow repeats, future implementation)
	# Randomly add unique levels from index 1..(child_count-1)
	#var used_indices = []
	#while level_collection.size() < (level_amount + 1):
		#if used_indices.size() == get_child_count() - 1:
			#used_indices.clear()
		#
		#var r = randi_range(1, get_child_count() - 1)
		#
		#if r not in used_indices:
			#used_indices.append(r)
			#level_collection.append(get_child(r))
