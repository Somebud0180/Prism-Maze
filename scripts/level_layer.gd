extends Node

var _level_name = ""
var _level_count = -1

func return_level(level_name: String) -> Node2D:
	_level_count = get_child_count() - 3
	_level_name = level_name
	
	# Enable only the level with the matching name, disable the others
	var level_node
	
	for child in get_children():
		if child.name == level_name:
			level_node = child
	
	var level_copy = level_node.duplicate()
	
	return level_copy
