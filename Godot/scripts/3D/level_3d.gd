extends Node3D

var custom_level_loaded = false
var level_indices_used = []
var last_level = null
var level_exclude = 6 # Beginning/Special levels to exclude from randomization

var rand_mid_level = randi_range(-2, 2)
var mid_level_spawned = false

func get_next_level(is_infinite: bool, level_count: int, custom_level: String = "", max_levels: int = 0) -> Node3D:
	# If no more children to pick from, return null
	if get_child_count() <= 1:
		return null
	
	if !is_infinite:
		# Handle spawning Mid-Game and End-Game Levels
		if max_levels > 15:
			if level_count == (round(float(max_levels) / 2) + rand_mid_level) and !mid_level_spawned:
				var levels = get_children()
				for level in levels:
					if level.name == "MidLevel":
						level_indices_used.append(level)
						var level_copy = level.duplicate()
						custom_level_loaded = true
						mid_level_spawned = true
						return level_copy
			elif level_count == max_levels - 1:
				var levels = get_children()
				for level in levels:
					if level.name == "EndLevel":
						level_indices_used.append(level)
						var level_copy = level.duplicate()
						custom_level_loaded = true
						return level_copy
		elif max_levels > 9:
			if level_count == (round(float(max_levels) / 2) + rand_mid_level) and !mid_level_spawned:
				var levels = get_children()
				for level in levels:
					if level.name == "MidLevel":
						level_indices_used.append(level)
						var level_copy = level.duplicate()
						custom_level_loaded = true
						mid_level_spawned = true
						return level_copy
		
		# Handle spawning Final Level
		if level_count == max_levels:
			var levels = get_children()
			for level in levels:
				if level.name == "FinishLevel":
					level_indices_used.append(level)
					var level_copy = level.duplicate()
					custom_level_loaded = true
					return level_copy
		elif level_count > max_levels:
			return null
	
	# If it is the first level and there is a custom level defined, return the custom level
	if !custom_level.is_empty() and !custom_level_loaded:
		var levels = get_children()
		for level in levels:
			if level.name == custom_level:
				level_indices_used.append(level)
				var level_copy = level.duplicate()
				custom_level_loaded = true
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
			return copy_child
		tries -= 1
	
	# If we fail to find a new one, return null
	return null
