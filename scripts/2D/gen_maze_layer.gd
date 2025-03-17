extends TileMapLayer

# A maze generator
# From https://godotengine.org/asset-library/asset/2199
# Modified to fit the game.

var _hidden_tile_flag: Dictionary = {}

var allow_loops = true
var current_level = 0
var starting_pos = Vector2i()
const normal_wall_atlas_coords = Vector2i(0, 0)
const FLAG_SOURCE_ID = 1
const FLAG_ATLAS_COORDS = Vector2i(0, 0)
const FLAG_ALTERNATIVE_ID = 0
const SOURCE_ID = 0

@export var y_dim = 35
@export var x_dim = 35
@export var starting_coords = Vector2i(0, 0)
@export var timer: Timer

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
	
	x_dim = random_odd_in_range(min_range, max_range)
	y_dim = random_odd_in_range(min_range, max_range)
	
	place_border()
	dfs(starting_coords)
	place_flag()
	
	# Hide the flag for 1 second to avoid spoiling it during camera movement
	show_flags(false)
	timer.start()


func determine_size(level: int):
	if level <= 5:
		return Vector2i(13, 17)
	elif level > 5:
		return Vector2i(17, 33)


func random_odd_in_range(min_val: int, max_val: int) -> int:
	# Shift min up to the next odd number if it's even
	if min_val % 2 == 0:
		min_val += 1
	# Shift max down to the previous odd number if it's even
	if max_val % 2 == 0:
		max_val -= 1
	
	# If the adjusted min exceeds max, just return min
	if min_val > max_val:
		return min_val

	# Randomly pick an odd number by dividing the odd range into steps of 2
	var step_count = int(((max_val - min_val) / 2)) + 1
	var rand_step = randi_range(0, step_count - 1)
	return min_val + (rand_step * 2)


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
		
		# *Tile-based* flag placement instead of adding a "flag" scene:
		set_cell(chosen, FLAG_SOURCE_ID, FLAG_ATLAS_COORDS, FLAG_ALTERNATIVE_ID)
	else:
		load_maze(current_level)


func show_flags(visible: bool) -> void:
	if visible:
		# Restore the single flag if we previously hid it
		if _hidden_tile_flag.size() > 0:
			set_cell(
				_hidden_tile_flag["pos"],
				_hidden_tile_flag["source_id"],
				_hidden_tile_flag["atlas_coords"],
				_hidden_tile_flag["alternative_tile"]
			)
			_hidden_tile_flag = {}
	else:
		_hidden_tile_flag = {}
		
		# Grab the (one) flag tile (source_id=1, atlas=FLAG_ALTERNATIVE_ID in your setup).
		var used_flag_cells = get_used_cells_by_id(FLAG_SOURCE_ID, Vector2i(0, 0), FLAG_ALTERNATIVE_ID)
		if used_flag_cells.size() > 0:
			var cell_pos = used_flag_cells[0]
			_hidden_tile_flag = {
				"pos": cell_pos,
				"source_id": get_cell_source_id(cell_pos),
				"atlas_coords": get_cell_atlas_coords(cell_pos),
				"alternative_tile": get_cell_alternative_tile(cell_pos)
			}
			
			# Remove the flag tile so it's invisible
			set_cell(cell_pos, -1, Vector2i(-1, -1), -1)


func _on_timer_timeout() -> void:
	show_flags(true)
