extends Node

# The Game Manager holds the set of levels, game mode, and level progression.
# It is also responsible for loading the game and the levels.

@onready var main_layer = get_node("/root/Game/MainLayer")
@onready var player_camera = %Camera2D
@onready var player = %Player
@export var level: int = 0

var level_collection: Array[String] = [] # The level set for the current playthrough
var level_amount: int = 10 # The amount of levels to create for the playthrough.
var game_ready: bool = false
var GAME_MODE: int = 2  # 1: Platformer, 2: Maze

func _ready() -> void:
	# Load Maze Layer
	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	main_layer.add_child(maze_instance)
	
	# Load Platform Layer
	var platform_layer = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_layer.instantiate()
	main_layer.add_child(platform_instance)
	
	load_game(maze_instance, platform_instance)
	load_level()

func load_game(maze_instance: Node, platform_instance: Node) -> void:
	# Create a level collection
	for i in range(level_amount): 
		var this_level = randi_range(0, 1)
		if this_level == 0:
			level_collection.append("Maze")
		else:
			level_collection.append("Platform")
		
	level_collection.append(str(platform_instance.get_child_count() - 1))
	print(level_collection)
	
	for i in range(3):
		# Check levels thrice to optimize for speed and best level set.
		level_check()
	
	print(level_collection)
	
	level_set(maze_instance, platform_instance)
	print(level_collection)

func level_check() -> void:
	# Improve random level list
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
	GAME_MODE = 2
	
	# Load and instantiate a new maze scene.
	var gen_maze_scene = load("res://scenes/gen_maze_layer.tscn")
	var gen_maze_instance = gen_maze_scene.instantiate()
	main_layer.add_child(gen_maze_instance)
	
	gen_maze_instance.load_maze(level)

func load_maze(selected_level: int) -> void:
	# Set game mode
	GAME_MODE = 2

	var maze_layer = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_layer.instantiate()
	main_layer.add_child(maze_instance)

	maze_instance.disable_all_levels()
	maze_instance.load_level(selected_level)

func load_platform(selected_level: int) -> void:
	# Set game mode
	GAME_MODE = 1

	var platform_scene = load("res://scenes/platform_layer.tscn")
	var platform_instance = platform_scene.instantiate()
	main_layer.add_child(platform_instance)

	platform_instance.disable_all_levels()
	platform_instance.load_level(selected_level)
	
func load_end() -> void:
	print("Loading end")
	pass

func _process(_delta: float) -> void:
	pass
