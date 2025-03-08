extends Node

const FLAG_ALTERNATIVE_ID = 0
const DOOR_REPLACEMENT_SOURCE_ID = 0
const DOOR_REPLACEMENT_ATLAS_COORDS = Vector2i(0,0)

var tilemap_defaults := {}  # For TileMap nodes.
var physics_defaults := {}  # For CollisionObject2D nodes (excluding TileMap).
var _removed_flags := []
var _hidden_tile_flags: Array = []
var _removed_keys: Array = []
var _hidden_keys: Array = []
var _replaced_doors: Array = []
var _level_name = ""
var _level_count = -1

@export var timer: Timer

func _ready() -> void:
	_store_tilemap_defaults()
	_store_physics_defaults(self)


func enable_all_levels() -> void:
	# Enable every child by name
	for i in range(get_child_count()):
		_enable_level(get_child(i).name)


func disable_all_levels() -> void:
	# Disable every child by name
	for i in range(get_child_count()):
		_disable_level(get_child(i).name)


func load_level(level_name: String) -> void:
	_level_count = get_child_count()
	_level_name = level_name
	enable_all_levels()
	restore_flags()
	restore_keys_and_doors()
	
	# Enable only the level with the matching name, disable the others
	for i in range(_level_count):
		var level_node = get_child(i)
		if level_node.name == level_name:
			_enable_level(level_node.name)
		else:
			_disable_level(level_node.name)
	
	# Hide the flag for 1 second to avoid spoiling it during camera movement
	show_flags(false, _level_name)
	show_keys(false, _level_name)
	timer.start()


# Enables a level node by recursively showing it, enabling processing, and restoring its physics.
func _enable_level(level_name: String) -> void:
	var level_node = get_node_or_null(level_name)
	if not level_node:
		return
	
	_set_visibility_recursive(level_node, true)
	if level_node.has_method("set_process"):
		level_node.set_process(true)
	if level_node.has_method("set_physics_process"):
		level_node.set_physics_process(true)
	if level_node is TileMapLayer:
		level_node.enabled = true
	_set_physics_state(level_node, true)
	randomize_flags(level_node)
	randomize_keys_and_doors(level_node)


# Disables a level node by recursively hiding it, disabling processing, and disabling its physics.
func _disable_level(level_name: String) -> void:
	var level_node = get_node_or_null(level_name)
	if not level_node:
		return
	_set_visibility_recursive(level_node, false)
	if level_node.has_method("set_process"):
		level_node.set_process(false)
	if level_node.has_method("set_physics_process"):
		level_node.set_physics_process(false)
	if level_node is TileMapLayer:
		level_node.enabled = false
	_set_physics_state(level_node, false)


# Recursively set the "visible" property for all CanvasItem nodes using deferred calls.
func _set_visibility_recursive(current_node: Node, visibility: bool) -> void:
	if current_node is CanvasItem:
		current_node.set_deferred("visible", visibility)
	for child in current_node.get_children():
		_set_visibility_recursive(child, visibility)


# Recursively update physics/collision state for CollisionShape2D and CollisionObject2D nodes.
func _set_physics_state(current_node: Node, enable: bool) -> void:
	# For CollisionShape2D nodes, update their "disabled" property using deferred call.
	if current_node is CollisionShape2D:
		current_node.set_deferred("disabled", not enable)
	
	# For CollisionObject2D nodes (excluding TileMap) update collision layers and masks.
	if current_node is CollisionObject2D and not (current_node is TileMapLayer):
		# For Area2D nodes, use deferred calls for the "monitoring" property.
		if current_node is Area2D:
			current_node.set_deferred("monitoring", enable)
		if enable:
			_restore_physics_properties(current_node)
		else:
			_disable_physics_properties(current_node)
	
	for child in current_node.get_children():
		_set_physics_state(child, enable)


# Store default collision_layer and collision_mask for each TileMap under levels.
func _store_tilemap_defaults() -> void:
	for i in range(get_child_count()):
		var level_node: Node = get_child(i)
		for child in level_node.get_children():
			if child is TileMapLayer:
				var id = child.get_instance_id()
				if not tilemap_defaults.has(id):
					tilemap_defaults[id] = {
						"collision_layer": child.collision_layer,
						"collision_mask": child.collision_mask
					}


# Recursively store default physics properties for CollisionObject2D nodes (excluding TileMap) under current_node.
func _store_physics_defaults(current_node: Node) -> void:
	if current_node is CollisionObject2D and not (current_node is TileMapLayer):
		var id = current_node.get_instance_id()
		# Only store if not already stored and if the node has collision properties.
		if not physics_defaults.has(id) and current_node.has_method("get_collision_layer") and current_node.has_method("get_collision_mask"):
			physics_defaults[id] = {
				"collision_layer": current_node.collision_layer,
				"collision_mask": current_node.collision_mask
			}
	for child in current_node.get_children():
		_store_physics_defaults(child)


# Restore physics properties for a given CollisionObject2D.
func _restore_physics_properties(obj: CollisionObject2D) -> void:
	var id = obj.get_instance_id()
	if physics_defaults.has(id):
		var defaults = physics_defaults[id]
		# Using deferred calls to ensure the changes are applied correctly.
		obj.set_deferred("collision_layer", defaults["collision_layer"])
		obj.set_deferred("collision_mask", defaults["collision_mask"])
		# For Area2D nodes, monitoring is updated in _set_physics_state.


# Disable physics properties for a given CollisionObject2D.
func _disable_physics_properties(obj: CollisionObject2D) -> void:
	obj.set_deferred("collision_layer", 0)
	obj.set_deferred("collision_mask", 0)


# Restore the TileMap's collision properties from stored defaults.
func _enable_tilemap_collisions(tilemap: TileMap) -> void:
	var id = tilemap.get_instance_id()
	if tilemap_defaults.has(id):
		var defaults = tilemap_defaults[id]
		tilemap.set_deferred("collision_layer", defaults["collision_layer"])
		tilemap.set_deferred("collision_mask", defaults["collision_mask"])
	else:
		tilemap.set_deferred("collision_layer", 1)
		tilemap.set_deferred("collision_mask", 1)
	tilemap.update_dirty_quadrants()


func show_flags(visible: bool, level_name: String) -> void:
	var tilemap = get_node_or_null(level_name)
	if tilemap is not TileMapLayer:
		return
	
	if visible:
		# Restore any flags we previously hid
		for hidden in _hidden_tile_flags:
			tilemap.set_cell(
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
		var used_flag_cells = tilemap.get_used_cells_by_id(1, Vector2i(0, 0), FLAG_ALTERNATIVE_ID)
		for cell_pos in used_flag_cells:
			var source_id = tilemap.get_cell_source_id(cell_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(cell_pos)
			var alt_tile = tilemap.get_cell_alternative_tile(cell_pos)
			
			_hidden_tile_flags.append({
				"pos": cell_pos,
				"source_id": source_id,
				"atlas_coords": atlas_coords,
				"alternative_tile": alt_tile
			})
		
		# Now remove them so they disappear (hidden)
		for hidden in _hidden_tile_flags:
			tilemap.set_cell(hidden["pos"], -1, Vector2i(-1, -1), -1)


func show_keys(visible: bool, level_name: String) -> void:
	var root_node = get_node_or_null(level_name)
	if root_node is not TileMapLayer:
		return
	
	if visible:
		for k in _hidden_keys:
			k.set_deferred("visible", true)
			if k is CollisionObject2D:
				k.process_mode = Node.PROCESS_MODE_INHERIT
		_hidden_keys.clear()
	else:
		_hidden_keys.clear()
		_hide_all_keys_recursive(root_node)


func _hide_all_keys_recursive(current_node: Node) -> void:
	if not current_node:
		return
	for child in current_node.get_children():
		# If the child is a Key (which may be directly under the TileMapLayer or under a "Keys" node)
		if child is CharacterBody2D and child is Key and child not in _removed_keys:
			_hidden_keys.append(child)
			child.set_deferred("visible", false)
			if child is CollisionObject2D:
				child.process_mode = Node.PROCESS_MODE_DISABLED
		# Recurse on the actual child node (not the same level_name again)
		_hide_all_keys_recursive(child)


func _on_timer_timeout() -> void:
	show_flags(true, _level_name)
	show_keys(true, _level_name,)


func randomize_flags(level_node: Node) -> void:
	var tilemap = level_node
	if tilemap is not TileMapLayer:
		return
	
	var flag_cells = tilemap.get_used_cells_by_id(1, Vector2(0, 0), FLAG_ALTERNATIVE_ID)
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
				"source_id": tilemap.get_cell_source_id(cell_pos),
				"atlas_coords": tilemap.get_cell_atlas_coords(cell_pos),
				"alternative_tile": tilemap.get_cell_alternative_tile(cell_pos)
			})
			
			tilemap.set_cell(cell_pos, -1, Vector2i(-1, -1), -1)


func restore_flags() -> void:
	var tilemap = get_node_or_null("TileMap")
	if not tilemap:
		return
	
	for removed in _removed_flags:
		var pos = removed["pos"]
		# Single call to restore the tile:
		tilemap.set_cell(pos, removed["source_id"], removed["atlas_coords"], removed["alternative_tile"])
	
	_removed_flags.clear()


func randomize_keys_and_doors(level_node: Node) -> void:
	# Dictionary: key_id => [list_of_key_nodes]
	var keys_by_id: Dictionary = {}
	# Dictionary: door_id => [list_of_door_nodes]
	var doors_by_id: Dictionary = {}
	
	# Collect all Keys and Doors (recursively)
	_collect_keys_and_doors(level_node, keys_by_id, doors_by_id)
	
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
					# (assumes 'level_node' is or contains your TileMap).
					if level_node is TileMapLayer:
						# Place a "wall" or "block" tile
						level_node.set_cell(
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
						"tilemap": level_node,
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
		var tilemap = entry["tilemap"]
		var tile_pos = entry["tile_pos"]

		# Remove the replacement tile from the tilemap
		if tilemap is TileMapLayer:
			tilemap.set_cell(tile_pos, -1, Vector2i(-1, -1), -1)

		# Re-add the door node to its original parent
		if parent:
			parent.add_child(door_node)

	_replaced_doors.clear()
