extends TileMapLayer

const FLAG_ALTERNATIVE_ID = 0
const DOOR_REPLACEMENT_SOURCE_ID = 0
const DOOR_REPLACEMENT_ATLAS_COORDS = Vector2i(0,0)

## When randomizing the door, pick the one next to a flag.
@export var pick_door_with_flag: bool = false

var _removed_flags := []
var _hidden_tile_flags: Array = []
var _removed_keys: Array = []
var _hidden_keys: Array = []


func init_level() -> void:
	randomize_flags()
	randomize_keys_and_doors()
	show_flags(false)
	show_keys(false)
	
	get_tree().create_timer(2.0).timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	show_flags(true)
	show_keys(true)


func show_flags(_visible: bool) -> void:
	if _visible:
		# Restore any flags we previously hid
		for _hidden in _hidden_tile_flags:
			set_cell(
				_hidden["pos"], 
				_hidden["source_id"], 
				_hidden["atlas_coords"], 
				_hidden["alternative_tile"]
			)
		
		_hidden_tile_flags.clear()
	
	else:
		# Hide the currently existing flags (if any remain)
		_hidden_tile_flags.clear()
		
		# Grab whatever flag tiles exist (source_id=1, atlas=FLAG_ATLAS in your setup)
		var used_flag_cells = get_used_cells_by_id(1, Vector2i(0, 0), FLAG_ALTERNATIVE_ID)
		for cell_pos in used_flag_cells:
			var source_id = get_cell_source_id(cell_pos)
			var atlas_coords = get_cell_atlas_coords(cell_pos)
			var alt_tile = get_cell_alternative_tile(cell_pos)
			
			_hidden_tile_flags.append({
				"pos": cell_pos,
				"source_id": source_id,
				"atlas_coords": atlas_coords,
				"alternative_tile": alt_tile
			})
		
		# Now remove them so they disappear (hidden)
		for _hidden in _hidden_tile_flags:
			set_cell(_hidden["pos"], -1, Vector2i(-1, -1), -1)


func show_keys(_visible: bool) -> void:
	if _visible:
		for k in _hidden_keys:
			k.set_deferred("visible", true)
			if k is CollisionObject2D:
				k.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		_hidden_keys.clear()
	else:
		_hidden_keys.clear()
		_hide_all_keys_recursive(self)


func _hide_all_keys_recursive(current_node: Node) -> void:
	for child in current_node.get_children():
		# If the child is a Key
		if child is CharacterBody2D and child is Key and child not in _removed_keys:
			_hidden_keys.append(child)
			child.set_deferred("visible", false)
			if child is CollisionObject2D:
				child.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		# Recurse on the actual child node (not the same level_name again)
		_hide_all_keys_recursive(child)


func randomize_flags() -> void:
	var flag_cells = get_used_cells_by_id(1, Vector2(0, 0), FLAG_ALTERNATIVE_ID)
	if flag_cells.size() <= 1:
		return
	
	# Randomize the seed
	randomize()
	var keep_index = randi() % flag_cells.size()
	
	for i in range(flag_cells.size()):
		if i != keep_index:
			var cell_pos = flag_cells[i]
			_removed_flags.append({
				"pos": cell_pos,
				"source_id": get_cell_source_id(cell_pos),
				"atlas_coords": get_cell_atlas_coords(cell_pos),
				"alternative_tile": get_cell_alternative_tile(cell_pos)
			})
			
			set_cell(cell_pos, -1, Vector2i(-1, -1), -1)


func randomize_keys_and_doors() -> void:
	# Dictionary: key_id => [list_of_key_nodes]
	var keys_by_id: Dictionary = {}
	# Dictionary: door_id => [list_of_door_nodes]
	var doors_by_id: Dictionary = {}
	
	# Collect all Keys and Doors (recursively)
	_collect_keys_and_doors(self, keys_by_id, doors_by_id)
	
	# Randomize Keys -- for each ID, keep 1, hide the others
	for key_id in keys_by_id.keys():
		var key_nodes = keys_by_id[key_id]
		if key_nodes.size() > 1:
			# Pick one to keep
			randomize()
			var keep_index = randi() % key_nodes.size()
			for i in range(key_nodes.size()):
				if i != keep_index:
					var key_node = key_nodes[i]
					
					# Hide the key node (instead of queue_free)
					# and disable it so it won't process or collide
					key_node.set_deferred("visible", false)
					if key_node is CollisionObject2D:
						key_node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
					
					# Save so we can restore later
					_removed_keys.append(key_node)
	
	# Randomize Doors -- for each ID, keep 1, replace the rest with a tile
	for door_id in doors_by_id.keys():
		var door_nodes = doors_by_id[door_id]
		if door_nodes.size() > 1:
			if pick_door_with_flag:
				var flag_found = false
				for i in range(door_nodes.size()):
					var door_node = door_nodes[i]
					
					# x => floor(global_x/32), y => ceil(global_y/32)
					var gpos = door_node.global_position
					var tile_x = int(floor(gpos.x / 32.0))
					var tile_y = int(floor(gpos.y / 32.0))
					var tile_pos = Vector2i(tile_x, tile_y)
					
					var surrounding_cells = get_surrounding_cells(tile_pos)
					
					for neighbor_pos in surrounding_cells:
						# Check if the cell is a Flag tile
						var src_id = get_cell_source_id(neighbor_pos)
						var atlas_coords = get_cell_atlas_coords(neighbor_pos)
						var alternative_id = get_cell_alternative_tile(neighbor_pos)
						# Compare to Flag ID
						if src_id == 1 and atlas_coords == Vector2i(0, 0) and alternative_id == 0:
							# Found a Flag tile
							flag_found = true
							break
					
					if flag_found:
						# Keep this door and remove others
						for j in range(door_nodes.size()):
							if j != i:
								var door_to_remove = door_nodes[j]
								var parent = door_to_remove.get_parent()
								if parent:
									parent.remove_child(door_to_remove)
						break
			else:
				randomize()
				var keep_index = randi() % door_nodes.size()
				for i in range(door_nodes.size()):
					if i != keep_index:
						var door_node = door_nodes[i]
						
						# Calculate tilemap coords:
						# x => floor(global_x/32), y => ceil(global_y/32)
						var gpos = door_node.global_position
						var tile_x = int(floor(gpos.x / 32.0))
						var tile_y = int(floor(gpos.y / 32.0))
						var tile_pos = Vector2i(tile_x, tile_y)
						
						# Replace the door with a tile in the tilemap
						set_cell(
							tile_pos,
							DOOR_REPLACEMENT_SOURCE_ID,
							DOOR_REPLACEMENT_ATLAS_COORDS
						)
						# Remove this door from the scene
						var parent = door_node.get_parent()
						if parent:
							parent.remove_child(door_node)


func _collect_keys_and_doors(current: Node, keys_by_id: Dictionary, doors_by_id: Dictionary) -> void:
	# If this node is a Key, group it by key_id
	if current is Key:
		var kid = current.key_id
		if not keys_by_id.has(kid):
			keys_by_id[kid] = []
		keys_by_id[kid].append(current)

	# If this node is a Door, group it by id
	if current is Door:
		var did = current.id
		if not doors_by_id.has(did):
			doors_by_id[did] = []
		doors_by_id[did].append(current)

	# Recurse over children
	for child in current.get_children():
		_collect_keys_and_doors(child, keys_by_id, doors_by_id)
