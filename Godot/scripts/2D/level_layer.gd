extends Node

var _level_name = ""

func return_level(level_name: String) -> Node2D:
	_level_name = level_name
	
	# Enable only the level with the matching name, disable the others
	var level_node
	
	for child in get_children():
		if child.name == level_name:
			level_node = child
	
	var level_copy = level_node.duplicate()
	
	return level_copy
