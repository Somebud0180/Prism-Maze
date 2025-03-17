extends "res://scripts/3D/3d_level.gd"

@export var grid_map: GridMap
@export var wall_mesh_id: int = 0

var x_dim = 12  # Width
var y_dim = 5   # Height (number of floors)
var z_dim = 12  # Depth
var starting_pos = Vector3i(0, 0, 0)
var allow_loops = true

var entrance_pos = Vector3i(0, 0, 0)
var exit_pos = Vector3i(x_dim-1, 0, z_dim-1)  # Opposite corner, ground level

# 6 directions in 3D space
var adj6 = [
	Vector3i(-1, 0, 0),  # Left
	Vector3i(1, 0, 0),   # Right
	Vector3i(0, 1, 0),   # Up
	Vector3i(0, -1, 0),  # Down
	Vector3i(0, 0, 1),   # Forward
	Vector3i(0, 0, -1),  # Backward
]

# Dictionary to track wall positions
var maze_grid = {}


func _ready() -> void:
	_generate_maze()


func _generate_maze():
	# Randomize seed
	randomize()
	
	# Allow loops randomly
	allow_loops = randi() % 2 == 0
	
	# Initialize grid with all walls
	for x in range(x_dim):
		for y in range(y_dim):
			for z in range(z_dim):
				maze_grid[Vector3i(x, y, z)] = true  # true = wall
	
	# Place border walls
	place_border()
	
	# Set entrance and exit positions - ensure they're not walls
	maze_grid[entrance_pos] = false
	maze_grid[exit_pos] = false
	
	# Generate paths using DFS
	dfs(entrance_pos)  # Start from the entrance
	
	# Ensure exit is reachable
	ensure_exit_reachable()
	
	# Place blocks based on grid - this now fills everything and carves paths
	create_maze_blocks()
	
	# Create 2x2 holes at entrance and exit
	create_entrance_exit_wall_holes()
	
	# Place entrance marker, exit marker, and door
	place_markers_and_door()

func ensure_exit_reachable():
	# Simple function to make sure there's a path to the exit
	# Clear any walls directly around the exit
	for dir in adj6:
		var pos = exit_pos + dir
		if is_within_bounds(pos):
			maze_grid[pos] = false  # Make it a path

func create_entrance_exit_wall_holes():
	# Create 2x2 holes in the walls at entrance and exit (1 block up from ground)
	
	# For entrance (hole in the wall at x=-1)
	var entrance_wall_holes = [
		Vector3i(-1, 1, 0),  # Bottom left
		Vector3i(-1, 1, 1),  # Bottom right
		Vector3i(-1, 2, 0),  # Top left
		Vector3i(-1, 2, 1)   # Top right
	]
	
	# For exit (hole in the wall at x=x_dim)
	var exit_wall_holes = [
		Vector3i(x_dim, 1, z_dim-2),  # Bottom left
		Vector3i(x_dim, 1, z_dim-1),  # Bottom right
		Vector3i(x_dim, 2, z_dim-2),  # Top left
		Vector3i(x_dim, 2, z_dim-1)   # Top right
	]
	
	# Remove these wall blocks
	for pos in entrance_wall_holes:
		grid_map.set_cell_item(pos, -1)  # -1 removes the cell
		
	for pos in exit_wall_holes:
		grid_map.set_cell_item(pos, -1)  # -1 removes the cell

func add_floors():
	# Add a floor beneath each level
	for y in range(y_dim):
		for x in range(x_dim):
			for z in range(z_dim):
				# Place floor blocks at y-1 of each level
				# y=0 gets floor at y=-1, y=1 gets floor at y=0, etc.
				var floor_pos = Vector3i(x, y-1, z)
				grid_map.set_cell_item(floor_pos, wall_mesh_id)

func place_border():
	# X borders
	for y in range(-1, y_dim + 1):
		for z in range(-1, z_dim + 1):
			place_wall(Vector3i(-1, y, z))
			place_wall(Vector3i(x_dim, y, z))
	
	# Y borders
	for x in range(-1, x_dim + 1):
		for z in range(-1, z_dim + 1):
			place_wall(Vector3i(x, -1, z))
			place_wall(Vector3i(x, y_dim, z))
	
	# Z borders
	for x in range(-1, x_dim + 1):
		for y in range(-1, y_dim + 1):
			place_wall(Vector3i(x, y, -1))
			place_wall(Vector3i(x, y, z_dim))

func dfs(start: Vector3i):
	var fringe = [start]
	var seen = {}
	
	while fringe.size() > 0:
		var current = fringe.pop_back()
		
		if current in seen or not can_move_to(current):
			continue
			
		seen[current] = true
		
		# Check if this is a wall position
		if is_wall_coordinate(current):
			place_wall(current)
			continue
		
		# Clear path at current position
		maze_grid[current] = false  # false = empty/path
		
		var found_new_path = false
		# Shuffle directions for randomness
		adj6.shuffle()
		
		for dir in adj6:
			var new_pos = current + dir
			
			if new_pos not in seen and can_move_to(new_pos):
				var chance_of_no_loop = 1
				if allow_loops:
					chance_of_no_loop = randi_range(1, 5)
				
				if is_wall_coordinate(new_pos) and chance_of_no_loop == 1:
					place_wall(new_pos)
				else:
					found_new_path = true
					fringe.append(new_pos)
		
		# If dead end or cross section
		if not found_new_path:
			place_wall(current)

func is_wall_coordinate(pos: Vector3i) -> bool:
	# For 3D, consider positions where x and z are both odd as wall candidates
	# This creates a grid pattern similar to the 2D version
	return (pos.x % 2 == 1 and pos.z % 2 == 1)

func can_move_to(pos: Vector3i) -> bool:
	return (
		pos.x >= 0 and pos.x < x_dim and
		pos.y >= 0 and pos.y < y_dim and
		pos.z >= 0 and pos.z < z_dim and
		not is_wall(pos)
	)

func is_wall(pos: Vector3i) -> bool:
	if not maze_grid.has(pos):
		return true
	return maze_grid[pos]

func place_wall(pos: Vector3i):
	if is_within_bounds(pos):
		maze_grid[pos] = true

func is_within_bounds(pos: Vector3i) -> bool:
	return (
		pos.x >= 0 and pos.x < x_dim and
		pos.y >= 0 and pos.y < y_dim and
		pos.z >= 0 and pos.z < z_dim
	)

func create_maze_blocks():
	# Clear existing cells first
	grid_map.clear()
	
	# First, place wall blocks everywhere within our dimension bounds
	for x in range(-1, x_dim+1):
		for y in range(-1, y_dim+1):
			for z in range(-1, z_dim+1):
				grid_map.set_cell_item(Vector3i(x, y, z), wall_mesh_id)
	
	# Then, remove blocks to create paths that are 2 blocks wide and (height-2) blocks tall
	for x in range(x_dim):
		for z in range(z_dim):
			for y in range(y_dim):
				var pos = Vector3i(x, y, z)
				
				# If this is a path in our maze_grid
				if pos in maze_grid and not maze_grid[pos]:
					# Only create open space up to 2 blocks from the ceiling
					if y < y_dim - 2:
						# Remove the block at this position
						grid_map.set_cell_item(pos, -1)
						
						# Make the path 2 blocks wide where possible
						# Try to expand in +X direction
						var pos_right = Vector3i(x + 1, y, z)
						if is_within_bounds(pos_right):
							grid_map.set_cell_item(pos_right, -1)
						
						# Try to expand in +Z direction
						var pos_forward = Vector3i(x, y, z + 1)
						if is_within_bounds(pos_forward):
							grid_map.set_cell_item(pos_forward, -1)
						
						# Try to expand diagonally where both adjacent cells are paths
						var pos_diag = Vector3i(x + 1, y, z + 1)
						if is_within_bounds(pos_diag) and not maze_grid.get(pos_right, true) and not maze_grid.get(pos_forward, true):
							grid_map.set_cell_item(pos_diag, -1)
	
	# Add floors to each level
	add_floors()

func add_wall_block(pos: Vector3i):
	# Set a cell in the GridMap at the given position with the wall mesh
	grid_map.set_cell_item(pos, wall_mesh_id)


func place_markers_and_door():
	# Create and position entrance marker
	var entrance_marker = Marker3D.new()
	entrance_marker.name = "EntranceMarker"
	add_child(entrance_marker)
	entrance_marker.transform.origin = Vector3(0, 0, 0.5)  # Place just inside entrance between blocks
	
	# Create and position exit marker
	var exit_marker = Marker3D.new()
	exit_marker.name = "ExitMarker"
	exit_marker.transform.origin = Vector3(x_dim-1, 0, z_dim-1.5)  # Place just inside exit between blocks
	
	# Create and position door
	var door = preload("res://scenes/3D/door_3d.tscn").instantiate()
	add_child(door)
	
	# Position door at exit, facing into the maze
	# Create a basis with the door rotated to face inward
	var basis = Basis(
		Vector3(0.0, 0.0, -1.0),  # x-basis
		Vector3(0.0, 1.0, 0.0),   # y-basis
		Vector3(1.0, 0.0, 0.0)    # z-basis
	)
	
	# Set the transform with the basis and origin
	door.transform = Transform3D(
		basis,
		Vector3(float(x_dim), 1.5, z_dim-1.5)  # origin position
	)
