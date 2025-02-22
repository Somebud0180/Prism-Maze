extends Node

# The Game Manager holds the set of levels, game mode, and level progression.
# It is also responsible for loading the game and the levels.

@onready var main_layer = get_node("/root/Game/MainLayer")
@onready var menu = get_node("/root/Menu")
@onready var player_camera = %Camera2D
@onready var player = %Player
@export var level: int = 0

<<<<<<< HEAD
var level_collection: Array[String] = [] # The level set for the current playthrough
var level_amount: int = 10 # The amount of levels to create for the playthrough.
var game_ready: bool = false
var GAME_MODE: int = 2  # 1: Platformer, 2: Maze
=======
var platform_list: Array[int] = []
var maze_list: Array[int] = []
var level_collection: Array[String] = [] # The level set for the current playthrough
var level_amount: int = 10 # The amount of levels to create for the playthrough. Excluding the final level.
var game_mode: int = 2  # 1: Platformer, 2: Maze
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)

func _ready() -> void:
	# Load Maze Layer
	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	main_layer.add_child(maze_instance)
	
	# Load Platform Layer
	var platform_layer = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_layer.instantiate()
	main_layer.add_child(platform_instance)

	# Fill each list with all valid indices initially, excluding the final platform level.
	for i in range(platform_instance.get_child_count() - 1):
		platform_list.append(i)
	
<<<<<<< HEAD
	load_game(maze_instance, platform_instance)
	load_level()

func load_game(maze_instance: Node, platform_instance: Node) -> void:
=======
	for i in range(maze_instance.get_child_count()):
		maze_list.append(i)
	
	# Shuffle them for random selection if desired:
	platform_list.shuffle()
	maze_list.shuffle()
	
	load_game(platform_instance)
	load_level()

func load_game(platform_instance: Node) -> void:
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
	# Create a level collection
	for i in range(level_amount): 
		var this_level = randi_range(0, 1)
		if this_level == 0:
			level_collection.append("Maze")
		else:
			level_collection.append("Platform")
	print(level_collection)
	
	for i in range(3):
		# Check levels thrice to optimize for speed and best level set.
		level_check()
	
	print(level_collection)
	
<<<<<<< HEAD
	level_set(maze_instance, platform_instance)
=======
	level_set(platform_instance)
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
	print(level_collection)

func level_check() -> void:
	# Improve random level list
<<<<<<< HEAD
	for i in range(level_collection.size()):
		if level_collection[i] == "Maze":
			if level_collection.size() > 2:
				if level_collection[level_collection.size() - 1] == "Maze" and level_collection[level_collection.size() - 2] == "Maze":
					level_collection[i] = "Platform"
			
		if level_collection[i] == "Platform":
			if level_collection.size() > 2:
				if level_collection[level_collection.size() - 1] == "Platform" and level_collection[level_collection.size() - 2] == "Platform" and level_collection[level_collection.size() - 3] == "Platform":
					level_collection[i] = "Maze"

func level_set(maze_instance: Node, platform_instance: Node) -> void:
	# Replace placeholder platformer levels to real levels
	for i in range(level_collection.size()):
		if level_collection[i] == "Maze":
			var resolved = str(maze_instance.get_random_level())
			
			if i >= 1:
				while resolved == level_collection[i - 1] and resolved == level_collection[i - 2]:
					resolved = str(maze_instance.get_random_level())
			elif i >= 0:
				while resolved == level_collection[i - 1]:
					resolved = str(maze_instance.get_random_level())
			
			level_collection[i] = str("Maze: " + resolved)
			
		elif level_collection[i] == "Platform":
			var resolved = str(platform_instance.get_random_level())
			
			if i >= 1:
				while resolved == level_collection[i - 1] and resolved == level_collection[i - 2]:
					resolved = str(platform_instance.get_random_level())
			elif i >= 0:
				while resolved == level_collection[i - 1]:
					resolved = str(platform_instance.get_random_level())
			
			level_collection[i] = str("Platform: " + resolved)
=======
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
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)

func progress_level() -> void:
	if level > level_collection.size():
		load_end()
	else:
		level += 1
		print("Progressing to level:", level)
		load_level()

func load_level() -> void:
	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	maze_instance.disable_all_levels()
	
	var platform_scene = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_scene.instantiate()
	platform_instance.disable_all_levels()
	
<<<<<<< HEAD
=======
	# Reset player gravity and sprite
	player.gravity_direction = 1
	
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
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
<<<<<<< HEAD
	
	player.position = Vector2i(0,0)

func load_gen_maze() -> void:
	# Set game mode
	GAME_MODE = 2
	
=======
	
	player.position = Vector2i(0,0)

func load_gen_maze() -> void:
	# Set game mode
	game_mode = 2
	
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)
	# Load and instantiate a new maze scene.
	var gen_maze_scene = load("res://scenes/gen_maze_layer.tscn")
	var gen_maze_instance = gen_maze_scene.instantiate()
	main_layer.add_child(gen_maze_instance)
	
	gen_maze_instance.load_maze(level)

func load_maze(selected_level: int) -> void:
	# Set game mode
<<<<<<< HEAD
	GAME_MODE = 2
=======
	game_mode = 2
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)

	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	main_layer.add_child(maze_instance)

	maze_instance.disable_all_levels()
	maze_instance.load_level(selected_level)

func load_platform(selected_level: int) -> void:
	# Set game mode
<<<<<<< HEAD
	GAME_MODE = 1
=======
	game_mode = 1
>>>>>>> ade2381 (Added a main menu (Changed the primary scene to the menu), added new levels, made some changes throughout the code, and some asset reogranization and update. Also added a rough 3D scene implementation)

	var platform_scene = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_scene.instantiate()
	main_layer.add_child(platform_instance)

	platform_instance.disable_all_levels()
	platform_instance.load_level(selected_level)

func load_end() -> void:
	print("Loading end level!")
	pass

func get_platform_index() -> int:
	# Load Platform Layer
	var platform_layer = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_layer.instantiate()
	main_layer.add_child(platform_instance)
	
	# If the list is empty, refill it
	if platform_list.size() == 0:
		for i in range(platform_instance.get_child_count() - 1):
			platform_list.append(i)
		platform_list.shuffle()
	
	return platform_list.pop_back()

func get_maze_index() -> int:
	# Load Maze Layer
	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	main_layer.add_child(maze_instance)
	
	# If the list is empty, refill it
	if maze_list.size() == 0:
		for i in range(maze_instance.get_child_count()):
			maze_list.append(i)
		maze_list.shuffle()
	
	return maze_list.pop_back()

func _process(_delta: float) -> void:
	if menu.menu_state == menu.STATE.GAME:
		player_camera.enabled = true
	else:
		player_camera.enabled = false
