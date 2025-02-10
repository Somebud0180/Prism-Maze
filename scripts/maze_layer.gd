extends TileMapLayer
class_name MazeGen

# A maze generator
# From https://godotengine.org/asset-library/asset/2199
# Slightly modified to fit the game.

@onready var player = get_node("/root/Game/Player")
@onready var player_pos = player.position

const allow_loops = true

var starting_pos = Vector2i()
const normal_wall_atlas_coords = Vector2i(1, 0)
const walkable_atlas_coords = Vector2i(0, 0)
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
func _ready() -> void:
	print("Readying maze layer")
	reset_level()
	
func reset_level():
	print("Resetting maze layer")
	# Remove existing flag nodes.
	for flag in get_tree().get_nodes_in_group("flag"):
		flag.queue_free()
		
	# Clear the existing maze cells.
	for cell in get_used_cells():
		set_cell(cell, -1, Vector2i(-1, 0))  # -1 clears the cell

	# Re-assign starting position from player's current tile position.
	var player_tile: Vector2i = Vector2i(0, 0)
	player = get_node("/root/Game/Player")
	player.position = Vector2i(0,32)
	
	# Set maze dimensions.
	y_dim = randi_range(20, 30)
	x_dim = randi_range(20, 30)
	
	starting_coords = player_tile  # Use this as the start for DFS and border.
	
	print("Player tile:", player_tile)
	
	place_border()
	dfs(player_tile)
	place_flag()
	
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
		if current in spot_to_label:
			for node in spot_to_label[current]:
				node.queue_free()
##			var existing_letter = find_child(spot_to_letter[current])
#			if existing_letter != null:
#				existing_letter.queue_free()
		if current.x % 2 == 1 and current.y % 2 == 1:
			place_wall(current)
			continue
			
		set_cell(current, SOURCE_ID, walkable_atlas_coords)
		
		
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
	place_flag()
			
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
	else:
		print("No suitable flag candidate found.")
