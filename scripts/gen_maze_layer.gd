extends TileMapLayer

# A maze generator
# From https://godotengine.org/asset-library/asset/2199
# Modified to fit the game.

var _hidden_tile_flags: Array = []

var allow_loops = true
var current_level = 0
var starting_pos = Vector2i()
const normal_wall_atlas_coords = Vector2i(0, 0)
const flag_alternative_id = 0
const SOURCE_ID = 0

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
func _ready() -> void:
	# Allow loops in maze randomly
	allow_loops = randi() % 2 == 0
	
	# Offset the maze position to allow the player to spawn in (0, 0)
	position.y = -32


func load_maze(level: int):
	# Store current level as needed.
	current_level = level
	
	# Remove existing flag nodes.
	for flag in get_tree().get_nodes_in_group("flag"):
		flag.queue_free()
		
	# Clear the existing maze cells.
	for cell in get_used_cells():
		set_cell(cell, -1, Vector2i(-1, 0))  # -1 clears the cell
	
	# Set maze dimensions.
	var size_range: Vector2i = determine_size(level)
	var min_range = size_range[0]
	var max_range = size_range[1]
	
	y_dim = randi_range(min_range, max_range)
	x_dim = randi_range(min_range, max_range)
	
	place_border()
	dfs(starting_coords)
	place_flag()
	
	# Hide the flag for 1 second to avoid spoiling it during camera movement
	show_flags(false)
	$Timer.start()


func determine_size(level: int):
	if level <= 5:
		return Vector2i(12, 16)
	elif level > 5:
		return Vector2i(16, 32)


func place_border():
	for y in range(-1, y_dim):
		place_wall(Vector2(-1, y))
	for x in range(-1, x_dim):
		place_wall(Vector2(x, -1))
	for y in range(-1, y_dim + 1):
		place_wall(Vector2(x_dim, y))
	for x in range(-1, x_dim + 1):
		place_wall(Vector2(x, y_dim))


func delete_cell_at(pos: Vector2i):
	set_cell(pos)


func place_wall(pos: Vector2i):
	set_cell(pos, SOURCE_ID, normal_wall_atlas_coords)


func will_be_converted_to_wall(spot: Vector2i):
	return (spot.x % 2 == 1 and spot.y % 2 == 1)


func is_wall(pos: Vector2i):
	return get_cell_atlas_coords(pos) == normal_wall_atlas_coords


func can_move_to(cell: Vector2i):
	# Adjusted to work in maze coordinates relative to starting_coords.
	return (
		cell.x >= starting_coords.x and cell.y >= starting_coords.y and
		cell.x < starting_coords.x + x_dim and cell.y < starting_coords.y + y_dim and
		not is_wall(cell)
	)


func dfs(start: Vector2i):
	var fringe: Array[Vector2i] = [start]
	var seen = {}
	while fringe.size() > 0:
		var current: Vector2i 
		current = fringe.pop_back() as Vector2i
		if current in seen or not can_move_to(current):
			continue
			
		seen[current] = true
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
		var flag_scene = load("res://scenes/2D/flag.tscn")
		var flag_instance = flag_scene.instantiate()
		# Position the flag at the chosen cell (convert to local coordinates).
		flag_instance.position = map_to_local(chosen)
		# Add the flag node to the scene and the "flag" group for cleanup.
		add_child(flag_instance)
		flag_instance.add_to_group("flag")
	else:
		load_maze(current_level)


func show_flags(visible: bool) -> void:
	var tilemap = get_node_or_null("TileMapLayer")
	# If no tilemap layer found, return
	if not tilemap:
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
		var used_flag_cells = tilemap.get_used_cells_by_id(1, flag_alternative_id)
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


func _show_flags_recursive(visible: bool, node: Node) -> void:
	# If you name nodes "Flag," check for node.name == "Flag."
	if node.name == "Flag" and node is CanvasItem:
		node.visible = visible
	#
	## Continue down the scene tree
	#for subchild in node.get_children():
		#_show_flags_recursive(visible, subchild)


func _on_timer_timeout() -> void:
	show_flags(true)
