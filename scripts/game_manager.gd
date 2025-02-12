extends Node

# This Game Manager controls level progression by enabling only the active level’s nodes
# (including visibility, processing, physics interactions, and collisions)
# and disabling all others.

@export var level: int = 0
var level_collection: Array[String] = [] # The level set for the current playthrough
var game_ready: bool = false
var GAME_MODE: int = 2  # 1: Platformer, 2: Maze
var PLATFORM_LEVEL = -1

@onready var main_layer = get_node("/root/Game/MainLayer")
@onready var player_camera = %Camera2D
@onready var player = %Player

func _ready() -> void:
	load_game()
	load_level()

func load_game() -> void:
	# Load Platform Layer
	var platform_layer = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_layer.instantiate()
	main_layer.add_child(platform_instance)
	
	# Create a level collection
	for i in range(10): 
		var this_level = randi_range(0, 1)
		if this_level == 0:
			level_collection.append("Maze")
		else:
			level_collection.append("Platform")
		# load_maze()
		# platform_layer.update_levels_state()
	print(level_collection)
	
	# Replace placeholder platformer levels to real levels
	for i in range(level_collection.size()):
		if level_collection[i] == "Maze":
			if level_collection.size() > 3:
				if level_collection[level_collection.size() - 1] == "Maze" and level_collection[level_collection.size() - 2] == "Maze" and level_collection[level_collection.size() - 3] == "Maze":
					level_collection[i] = "Platform"
			
		if level_collection[i] == "Platform":
			var resolved = str(platform_instance.get_random_level())
			# If there’s a previous level, re-resolve until it’s different.
			if i >= 0:
				while resolved == level_collection[i - 1]:
					resolved = str(platform_instance.get_random_level())
			elif i >= 1:
				while resolved == level_collection[i - 1] and resolved == level_collection[i - 2]:
					resolved = str(platform_instance.get_random_level())
			level_collection[i] = resolved
	
	print(level_collection)

func progress_level() -> void:
	level += 1
	print("Progressing to level:", level)
	load_level()
	#  load_maze()
	# platform_layer.update_levels_state() # Call the function in PlatformLayer

func load_level() -> void:
	for child in main_layer.get_children():
		child.queue_free()
		
	if level_collection[level] == "Maze":
		load_maze()
	else:
		print(int(level_collection[level]))
		load_platform(int(level_collection[level]))
		player.go_to(Vector2i(0, 0))

func load_maze() -> void:
	# Set game mode
	GAME_MODE = 2
	
	# Remove any existing maze instances.
	for child in main_layer.get_children():
		if child is Maze:
			child.queue_free()
	
	# Load and instantiate a new maze scene.
	var maze_scene = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_scene.instantiate()
	main_layer.add_child(maze_instance)
	
	maze_instance.load_maze(level)

func load_platform(selected_level: int) -> void:
	# Set game mode
	GAME_MODE = 1

	# Remove any existing Platform nodes.
	for child in main_layer.get_children():
		if child is Platform:
			child.queue_free()

	var platform_scene = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_scene.instantiate()
	main_layer.add_child(platform_instance)

	platform_instance.disable_all_levels()
	platform_instance.load_level(selected_level)

func _process(_delta: float) -> void:
	pass
