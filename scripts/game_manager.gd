extends Node

# This Game Manager controls level progression by enabling only the active level’s nodes
# (including visibility, processing, physics interactions, and collisions)
# and disabling all others.
#
# The Tilemaps node is referenced using the shorthand '%Tilemaps' as specified.
# In this version, we use set_deferred() for properties that cannot be changed immediately,
# such as "visible" on CanvasItems and "monitoring" on Area2D, to avoid engine timing issues.
#
# Make sure that all your zone nodes (Platform Zone, Maze Zone, etc.) are set up with their proper
# collision layers, masks, and that they contain visible children (like Sprite) if you want 
# them to be visibly toggled.

@onready var levels: Node = %Tilemaps

var level: int = 0
var GAME_MODE: int = 1  # 1: Platformer, 2: Maze

# Dictionaries to store default physics properties.
var tilemap_defaults := {}  # For TileMap nodes.
var physics_defaults := {}  # For CollisionObject2D nodes (excluding TileMap).

func _ready() -> void:
	if not levels:
		push_error("Tilemaps node was not found. Adjust your node path!")
		return
	_store_tilemap_defaults()
	_store_physics_defaults(levels)
	update_levels_state()

func progress_level() -> void:
	level += 1
	print("Progressing to level:", level)
	update_levels_state()

func update_levels_state() -> void:
	var child_count = levels.get_child_count()
	if level < 0 or level >= child_count:
		print("Level index ", level, " is out of range (0 to ", child_count - 1, ").")
		return
	for i in range(child_count):
		var level_node: Node = levels.get_child(i)
		if i == level:
			_enable_level(level_node)
		else:
			_disable_level(level_node)

# Enables a level node by recursively showing it, enabling processing, and restoring its physics.
func _enable_level(level_node: Node) -> void:
	_set_visibility_recursive(level_node, true)
	if level_node.has_method("set_process"):
		level_node.set_process(true)
	if level_node.has_method("set_physics_process"):
		level_node.set_physics_process(true)
	if "collision_enabled" in level_node:
		level_node.collision_enabled = true
	_set_physics_state(level_node, true)

# Disables a level node by recursively hiding it, disabling processing, and turning off its physics.
func _disable_level(level_node: Node) -> void:
	_set_visibility_recursive(level_node, false)
	if level_node.has_method("set_process"):
		level_node.set_process(false)
	if level_node.has_method("set_physics_process"):
		level_node.set_physics_process(false)
	if "collision_enabled" in level_node:
		level_node.collision_enabled = false
	_set_physics_state(level_node, false)

# Recursively set the "visible" property for all CanvasItem nodes using deferred calls.
func _set_visibility_recursive(current_node: Node, visible: bool) -> void:
	if current_node is CanvasItem:
		current_node.set_deferred("visible", visible)
	for child in current_node.get_children():
		_set_visibility_recursive(child, visible)

# Recursively update physics/collision state for CollisionShape2D and CollisionObject2D nodes.
func _set_physics_state(current_node: Node, enable: bool) -> void:
	# For CollisionShape2D nodes, update their "disabled" property.
	if current_node is CollisionShape2D:
		current_node.disabled = not enable
	
	# For CollisionObject2D nodes (excluding TileMap) update collision layers and masks.
	if current_node is CollisionObject2D and not (current_node is TileMap):
		# For Area2D nodes, use deferred calls for the "monitoring" property.
		if current_node is Area2D:
			current_node.set_deferred("monitoring", enable)
		if enable:
			_restore_physics_properties(current_node)
		else:
			_disable_physics_properties(current_node)
	
	# Handle TileMap nodes separately.
	if current_node is TileMap:
		if enable:
			_enable_tilemap_collisions(current_node)
		else:
			_disable_tilemap_collisions(current_node)
			
	for child in current_node.get_children():
		_set_physics_state(child, enable)

# Store default collision_layer and collision_mask for each TileMap under levels.
func _store_tilemap_defaults() -> void:
	for i in range(levels.get_child_count()):
		var level_node: Node = levels.get_child(i)
		for child in level_node.get_children():
			if child is TileMap:
				var id = child.get_instance_id()
				if not tilemap_defaults.has(id):
					tilemap_defaults[id] = {
						"collision_layer": child.collision_layer,
						"collision_mask": child.collision_mask
					}

# Recursively store default physics properties for CollisionObject2D nodes (excluding TileMap) under current_node.
func _store_physics_defaults(current_node: Node) -> void:
	if current_node is CollisionObject2D and not (current_node is TileMap):
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
		obj.collision_layer = defaults["collision_layer"]
		obj.collision_mask = defaults["collision_mask"]
		# For Area2D nodes, monitoring is updated in _set_physics_state.

# Disable physics properties for a given CollisionObject2D.
func _disable_physics_properties(obj: CollisionObject2D) -> void:
	obj.collision_layer = 0
	obj.collision_mask = 0

# Restore the TileMap's collision properties from stored defaults.
func _enable_tilemap_collisions(tilemap: TileMap) -> void:
	var id = tilemap.get_instance_id()
	if tilemap_defaults.has(id):
		var defaults = tilemap_defaults[id]
		tilemap.collision_layer = defaults["collision_layer"]
		tilemap.collision_mask = defaults["collision_mask"]
	else:
		tilemap.collision_layer = 1
		tilemap.collision_mask = 1
	tilemap.update_dirty_quadrants()

# Disable collisions on the TileMap.
func _disable_tilemap_collisions(tilemap: TileMap) -> void:
	tilemap.collision_layer = 0
	tilemap.collision_mask = 0
	tilemap.update_dirty_quadrants()

func _process(delta: float) -> void:
	# Optional per-frame code.
	pass
