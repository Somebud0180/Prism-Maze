extends TileMapLayer

const FLAG_ALTERNATIVE_ID = 0
const DOOR_REPLACEMENT_SOURCE_ID = 0
const DOOR_REPLACEMENT_ATLAS_COORDS = Vector2i(0,0)

var _removed_flags := []
var _hidden_tile_flags: Array = []
var _removed_keys: Array = []
var _hidden_keys: Array = []
var _replaced_doors: Array = []


func init_level() -> void:
	randomize_flags()
	randomize_keys_and_doors()
	show_flags(false)
	show_keys(false)
	
	get_tree().create_timer(2.0).timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	show_flags(true)
	show_keys(true)


func show_flags(visible: bool) -> void:
	if visible:
		# Restore any flags we previously hid
		for hidden in _hidden_tile_flags:
			set_cell(
				hidden["pos"], 
				hidden["source_id"], 
				hidden["atlas_coords"], 
				hidden["alternative_tile"]
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
		for hidden in _hidden_tile_flags:
			set_cell(hidden["pos"], -1, Vector2i(-1, -1), -1)


func show_keys(visible: bool) -> void:
	if visible:
		for k in _hidden_keys:
			k.set_deferred("visible", true)
			if k is CollisionObject2D:
				k.process_mode = Node.PROCESS_MODE_INHERIT
		_hidden_keys.clear()
	else:
		_hidden_keys.clear()
		_hide_all_keys_recursive(self)


func _hide_all_keys_recursive(current_node: Node) -> void:
	for child in current_node.get_children():
		# If the child is a Key (which may be directly under the TileMapLayer or under a "Keys" node)
		if child is CharacterBody2D and child is Key and child not in _removed_keys:
			_hidden_keys.append(child)
			child.set_deferred("visible", false)
			if child is CollisionObject2D:
				child.process_mode = Node.PROCESS_MODE_DISABLED
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


func restore_flags() -> void:
	for removed in _removed_flags:
		var pos = removed["pos"]
		# Single call to restore the tile:
		set_cell(pos, removed["source_id"], removed["atlas_coords"], removed["alternative_tile"])
	
	_removed_flags.clear()


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
						key_node.process_mode = Node.PROCESS_MODE_DISABLED
					
					# Save so we can restore later
					_removed_keys.append(key_node)
	
	# Randomize Doors -- for each ID, keep 1, replace the rest with a tile
	for door_id in doors_by_id.keys():
		var door_nodes = doors_by_id[door_id]
		if door_nodes.size() > 1:
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
					
					# Save info to restore later
					_replaced_doors.append({
						"door_node": door_node,
						"parent": parent,
						"tile_pos": tile_pos
					})


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


func restore_keys_and_doors() -> void:
	# Restore hidden keys
	for key_node in _removed_keys:
		# Make it visible and active again
		if key_node is Node2D:
			key_node.visible = true
		if key_node is CollisionObject2D:
			key_node.process_mode = Node.PROCESS_MODE_INHERIT
	_removed_keys.clear()

	# Restore replaced doors
	for entry in _replaced_doors:
		var door_node = entry["door_node"]
		var parent = entry["parent"]
		var tile_pos = entry["tile_pos"]

		set_cell(tile_pos, -1, Vector2i(-1, -1), -1)

		# Re-add the door node to its original parent
		if parent:
			parent.add_child(door_node)

	_replaced_doors.clear()
