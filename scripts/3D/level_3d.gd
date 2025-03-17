extends Node3D

var level_count = 0
var level_indices_used = []
var last_level = null
var level_exclude = 3 # Beginning/Special levels to exclude from randomization


func get_next_level(custom_level: String = "") -> Node3D:
	# If no more children to pick from, return null
	if get_child_count() <= 1:
		return null
	
	# If it is the first level and there is a custom level defined, return the custom level
	if !custom_level.is_empty() and level_count == 0:
		var levels = get_children()
		for level in levels:
			if level.name == custom_level:
				level_indices_used.append(level)
				var level_copy = level.duplicate()
				level_count += 1
				return level_copy
		
		push_warning("Custom level not found!")
	
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
			level_count += 1
			return copy_child
		tries -= 1
	
	# If we fail to find a new one, return null
	return null
