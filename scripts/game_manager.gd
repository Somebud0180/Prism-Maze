extends Node

# The Game Manager holds the set of levels, game mode, and level progression.
# It is also responsible for loading the game and the levels.

@onready var menu = get_node("/root/Menu")
@onready var main_layer = get_node("/root/Game/MainLayer")
@onready var player = get_node("/root/Game/Player")

@export var level_amount: int = 10 # The amount of levels to create for the playthrough. Excluding the final level.

var level: int = 0
var level_times = []
var popup_scene = preload("res://scenes/level_popup.tscn").instantiate()
var maze_scene = preload("res://scenes/maze_layer.tscn").instantiate()
var platform_scene = preload("res://scenes/platform_layer.tscn").instantiate()

var level_collection: Array[String] = [] # The level set for the current playthrough
var game_mode: int = 2  # 1: Platformer, 2: Maze
var platform_list: Array[int] = []
var maze_list: Array[int] = []

func _ready() -> void:
	# Load Maze Layer
	main_layer.add_child(maze_scene)
	
	# Load Platform Layer
	main_layer.add_child(platform_scene)

	# Fill each list with all valid indices initially, excluding the final platform level.
	for i in range(platform_scene.get_child_count() - 1):
		platform_list.append(i)
	
	for i in range(maze_scene.get_child_count()):
		maze_list.append(i)
	
	# Shuffle them for random selection if desired:
	platform_list.shuffle()
	maze_list.shuffle()
	
	load_game(platform_scene)
	load_level()

func load_game(platform_instance: Node) -> void:
	# Create a level collection
	for i in range(level_amount): 
		var this_level = randi_range(0, 1)
		if this_level == 0:
			level_collection.append("Maze")
		else:
			level_collection.append("Platform")
	
	for i in range(3):
		# Check levels thrice to optimize for speed and best level set.
		level_check()
	
	level_set(platform_instance)

func level_check() -> void:
	# Improve random level list
	for i in range(level_collection.size()):
		if i > 1:
			if level_collection[i] == "Maze" and level_collection[i - 1] == "Maze" and level_collection[i - 2] == "Maze":
				level_collection[i] = "Platform"
			elif level_collection[i] == "Platform" and level_collection[i - 1] == "Platform" and level_collection[i - 2] == "Platform":
				level_collection[i] = "Maze"

func level_set(platform_instance: Node) -> void:
	# Replace placeholder platformer levels to real levels
	for i in range(level_collection.size()):
		if level_collection[i] == "Maze":
			if randi_range(0, 2) == 1:
				var resolved = str(get_maze_index())
				level_collection[i] = "Maze: " + resolved
			
		elif level_collection[i] == "Platform":
			var resolved = str(get_platform_index())
			level_collection[i] = "Platform: " + resolved
	
	# Append last level
	level_collection.append("Platform: " + str(platform_instance.get_child_count() - 1))

func progress_level() -> void:
	# Compute how long this level took
	var total_previous = 0.0
	for t in level_times:
		total_previous += t
	
	var current_time = menu.time_elapsed
	var current_level_time = current_time - total_previous
	level_times.append(snapped(current_level_time, 0.01))

	# Increase level index and load next
	level += 1
	print("Progressing to level:", level)
	load_level()
	
	# If completed all levels, finalize
	if level == level_collection.size() - 1:
		menu.is_timer_running = false
		popup_scene.output_timer(snapped(menu.time_elapsed, 0.01), level_times)
		main_layer.add_child(popup_scene)
		menu.is_popup_displaying = true
		popup_scene.animation_player.play("show_finish")

func load_level() -> void:
	maze_scene = preload("res://scenes/maze_layer.tscn").instantiate()
	platform_scene = preload("res://scenes/platform_layer.tscn").instantiate()
	
	maze_scene.disable_all_levels()
	platform_scene.disable_all_levels()
	
	# Reset player gravity and sprite
	player.gravity_direction = 1
	
	for child in main_layer.get_children():
		child.queue_free()
		
	if level_collection[level] == "Maze":
		load_gen_maze()
	else:
		if level_collection[level].begins_with("Maze: "):
			var raw_level_string = level_collection[level]
			var parts = raw_level_string.split(": ")
			var level_number = int(parts[1])   # Parse the number portion
			load_maze(level_number)

		elif level_collection[level].begins_with("Platform: "):
			var raw_level_string = level_collection[level]
			var parts = raw_level_string.split(": ")
			var level_number = int(parts[1])
			load_platform(level_number)
	
	player.position = Vector2i(0,0)

func load_gen_maze() -> void:
	# Set game mode
	game_mode = 2
	
	# Load and instantiate a new maze scene.
	var gen_maze_scene = load("res://scenes/gen_maze_layer.tscn")
	var gen_maze_instance = gen_maze_scene.instantiate()
	main_layer.add_child(gen_maze_instance)
	
	gen_maze_instance.load_maze(level)

func load_maze(selected_level: int) -> void:
	# Set game mode
	game_mode = 2
	
	maze_scene = preload("res://scenes/maze_layer.tscn").instantiate()
	main_layer.add_child(maze_scene)
	
	maze_scene.disable_all_levels()
	maze_scene.load_level(selected_level)

func load_platform(selected_level: int) -> void:
	# Set game mode
	game_mode = 1
	
	platform_scene = preload("res://scenes/platform_layer.tscn").instantiate()
	main_layer.add_child(platform_scene)
	
	platform_scene.disable_all_levels()
	platform_scene.load_level(selected_level)

func get_platform_index() -> int:
	# Load Platform Layer
	platform_scene = preload("res://scenes/platform_layer.tscn").instantiate()
	main_layer.add_child(platform_scene)
	
	# If the list is empty, refill it
	if platform_list.size() == 0:
		for i in range(platform_scene.get_child_count() - 1):
			platform_list.append(i)
		platform_list.shuffle()
	
	return platform_list.pop_back()

func get_maze_index() -> int:
	# Load Maze Layer
	maze_scene = preload("res://scenes/maze_layer.tscn").instantiate()
	main_layer.add_child(maze_scene)
	
	# If the list is empty, refill it
	if maze_list.size() == 0:
		for i in range(maze_scene.get_child_count()):
			maze_list.append(i)
		maze_list.shuffle()
	
	return maze_list.pop_back()

func hide_flags_in_current_level() -> void:
	# Loop over all children in main_layer (which is where levels are added)
	for child in main_layer.get_children():
		# If that child implements hide_flags(), call it
		if child.has_method("hide_flags"):
			child.show_flags(false)


func reset_game() -> void:
	for child in main_layer.get_children():
		child.queue_free()
	
	level_collection = []
	platform_list = []
	maze_list = []
	menu.time_elapsed = 0.0
