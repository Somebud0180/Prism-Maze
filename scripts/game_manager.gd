extends Node

# This Game Manager controls level progression by enabling only the active level’s nodes
# (including visibility, processing, physics interactions, and collisions)
# and disabling all others.

var level: int = 1 # Start on the second level (Maze)
var GAME_MODE: int = 2  # 1: Platformer, 2: Maze
var PLATFORM_LEVEL = -1

@onready var platform_layer = get_node("../PlatformLayer") # Reference to the PlatformLayer node
@onready var main_layer = get_node("/root/Game/MainLayer")

func _ready() -> void:
	reset_maze()
	# platform_layer.update_levels_state()

func progress_level() -> void:
	level += 1
	print("Progressing to level:", level)
	reset_maze()
	# platform_layer.update_levels_state() # Call the function in PlatformLayer

func load_random_platform() -> void:
	platform_layer.randomize_platforms() # Call the function in PlatformLayer

func reset_maze() -> void:
	# Remove any existing maze instances.
	for child in main_layer.get_children():
		if child is MazeGen:
			child.queue_free()
	
	# Load and instantiate a new maze scene.
	var maze_scene = load("res://scenes/maze_layer.tscn")
	var maze_instance = maze_scene.instantiate()
	main_layer.add_child(maze_instance)
	maze_instance.reset_level()

func _process(delta: float) -> void:
	# Optional per-frame code.
	pass
