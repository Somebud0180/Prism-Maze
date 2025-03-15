extends Node3D

var level_indices_used = []
var last_level = null
var level_exclude = 2 # Beginning/Special levels to exclude from randomization


func get_next_random_level() -> Node3D:
	# If no more children to pick from, return null
	if get_child_count() <= 1:
		return null
	
	var tries = 10
	while tries > 0:
		if level_indices_used.size() == get_child_count() - level_exclude:
			# Set last_level as reference for the next level loaded
			last_level = level_indices_used[-1]
			level_indices_used.clear()
		
		# Pick a random index from Level1 to LevelX (excluding Starting and Tutorial Level)
		var r = randi_range(level_exclude, get_child_count() - 1)
		var original_child = get_child(r)
		
		# Check if child is already exhausted
		if original_child not in level_indices_used:
			if original_child != last_level:
				level_indices_used.append(original_child)
				
				# Reset last_level after loading the first level after resetting indices
				if last_level != null:
					last_level = null
			
			# Duplicate the child
			var copy_child = original_child.duplicate()
			return copy_child
		tries -= 1
	
	# If we fail to find a new one, return null
	return null
