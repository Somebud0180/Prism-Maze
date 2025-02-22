extends Node

@onready var player = get_node("/root/Game/Player")

var tilemap_defaults := {}  # For TileMap nodes.
var physics_defaults := {}  # For CollisionObject2D nodes (excluding TileMap).
var level_count = 0

<<<<<<< HEAD
var current_level = 0
var starting_pos = Vector2i()
const normal_wall_atlas_coords = Vector2i(1, 0)
const SOURCE_ID = 0
var spot_to_letter = {}
var spot_to_label = {}
var current_letter_num = 65

@export var y_dim = 35
@export var x_dim = 35
@export var starting_coords = Vector2i(0, 0)
var adj4 = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

# Called when the node enters the scene tree for the first time.
=======
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
func _ready() -> void:
	_store_tilemap_defaults()
	_store_physics_defaults(self)
	
# Give a random level between the first and the last, excluding the final level.
# Reduced by an additional 1 to match counting starting at 0.
func get_random_level() -> int:
	return randi_range(0, get_child_count() - 2)

func disable_all_levels() -> void:
	for i in range(level_count):
		var level_node: Node = get_child(i)
		_disable_level(level_node)

func enable_all_levels() -> void:
	for i in range(level_count):
		var level_node: Node = get_child(i)
		_enable_level(level_node)

func load_level(level: int) -> void:
	level_count = get_child_count()
	enable_all_levels()
	
	for i in range(level_count):
		print("level_count: " + str(i))
		var level_node = get_child(i)
		if i == level:
			_enable_level(level_node)
		else:
			_disable_level(level_node)

# Enables a level node by recursively showing it, enabling processing, and restoring its physics.
func _enable_level(level_node: Node) -> void:
	print("Enabling platform level")
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

<<<<<<< HEAD
func dfs(start: Vector2i):
	var fringe: Array[Vector2i] = [start]
	var seen = {}
	while fringe.size() > 0:
		var current: Vector2i 
		current = fringe.pop_back() as Vector2i
		if current in seen or not can_move_to(current):
			continue
			
		seen[current] = true
		if current in spot_to_label:
			for node in spot_to_label[current]:
				node.queue_free()
##			var existing_letter = find_child(spot_to_letter[current])
#			if existing_letter != null:
#				existing_letter.queue_free()
		if current.x % 2 == 1 and current.y % 2 == 1:
			place_wall(current)
			continue
		
		var found_new_path = false
		adj4.shuffle()
		for pos in adj4:
			var new_pos = current + pos
			if new_pos not in seen and can_move_to(new_pos):
				var chance_of_no_loop = randi_range(1, 1)
				if allow_loops:
					chance_of_no_loop = randi_range(1, 5)
				if will_be_converted_to_wall(new_pos) and chance_of_no_loop == 1:
					place_wall(new_pos)
				else:
					found_new_path = true
					fringe.append(new_pos)
					
		#if we hit a dead end or are at a cross section
		if not found_new_path:
			place_wall(current)
			
func place_flag() -> void:
	var candidate_positions = []
	for y in range(0, y_dim):
		for x in range(0, x_dim):
			var cell = Vector2i(x, y)
			# Skip if the cell is the starting position.
			if cell == starting_pos:
				continue
			# Only consider walkable cells.
			if not is_wall(cell):
				var wall_count = 0
				for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var neighbor = cell + direction
					# Out-of-bounds counts as a wall.
					if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= x_dim or neighbor.y >= y_dim:
						wall_count += 1
					elif is_wall(neighbor):
						wall_count += 1
				# If the cell is enclosed on three or more sides, add it.
				if wall_count >= 3:
					candidate_positions.append(cell)
					
	if candidate_positions.size() > 0:
		var chosen = candidate_positions[randi() % candidate_positions.size()]
		var flag_scene = load("res://scenes/flag.tscn")
		var flag_instance = flag_scene.instantiate()
		# Position the flag at the chosen cell (convert to local coordinates).
		flag_instance.position = map_to_local(chosen)
		# Add the flag node to the scene and the "flag" group for cleanup.
		add_child(flag_instance)
		flag_instance.add_to_group("flag")
		print("Placed flag at: ", chosen)
=======
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
	for i in range(get_child_count()):
		var level_node: Node = get_child(i)
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
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
	else:
		tilemap.set_deferred("collision_layer", 1)
		tilemap.set_deferred("collision_mask", 1)
	tilemap.update_dirty_quadrants()

# Disable collisions on the TileMap.
func _disable_tilemap_collisions(tilemap: TileMap) -> void:
	tilemap.set_deferred("collision_layer", 0)
	tilemap.set_deferred("collision_mask", 0)
	tilemap.update_dirty_quadrants()
