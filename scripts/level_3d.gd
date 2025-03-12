extends Node3D

var level_indices_used = []

func get_next_random_level() -> Node3D:
	# If no more children to pick from, return null
	if get_child_count() <= 1:
		return null
	
	var tries = 10
	while tries > 0:
		if level_indices_used.size() == get_child_count() - 1:
			level_indices_used.clear()
		
		# Pick a random index from 1..(child_count-1)
		var r = randi_range(1, get_child_count() - 1)
		var original_child = get_child(r)
		# If we want to ensure it’s not repeated in the last 3 picks, etc.,
		# do that check here. Otherwise, just pick it:
		if original_child not in level_indices_used:
			level_indices_used.append(original_child)
			
			# Actually duplicate the child
			var copy_child = original_child.duplicate()
			return copy_child
		tries -= 1
	
	# If we fail to find a new one, return null
	return null
