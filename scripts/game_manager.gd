extends Node
class_name GameManager


# The Game Manager holds the set of levels, game mode, and level progression.
# It is also responsible for loading the game and the levels.

signal finished_loading
signal finished_level_set

@onready var game = $".."
@onready var menu = get_node("/root/Menu")
@onready var main_layer = get_node("/root/Game/MainLayer")
var player

var _popup_scene = preload("res://scenes/2D/level_popup.tscn").instantiate()
var _maze_scene = preload("res://scenes/2D/maze_layer.tscn").instantiate()
var _platform_scene = preload("res://scenes/2D/platform_layer.tscn").instantiate()

@export var level_amount: int = 10 # The amount of levels to create for the playthrough. Excluding the final level.
@export var custom_level: String = "": # A level to add first to the game, used for debugging. Follows the Maze: X, Platform: X, Maze format
	set(value):
		if not _is_valid_custom_level(value):
			push_error("Invalid custom_level format. Must be one of: 'Maze', 'Maze: <number>', or 'Platform: <number>'!")
			get_tree().quit()
		custom_level = value 

var level: int = 0
var level_times = []

var possible_colors = [Color.WHITE, Color.YELLOW, Color.ORANGE, Color.GREEN, Color.RED, Color.BLUE]
var selected_colors = []

var level_collection: Array[String] = [] # The level set for the current playthrough
var game_mode: int = 2  # 1: Platformer, 2: Maze
var platform_list: Array[int] = []
var maze_list: Array[int] = []


func _ready() -> void:
	# Reset the key color list
	_reset_keys()
	
	var player_scene = preload("res://scenes/2D/player.tscn").instantiate()
	game.add_child.call_deferred(player_scene)
	await Signal(player_scene, "player_loaded")
	player = get_node("/root/Game/Player")
	player._on_game_manager_loaded()
	
	# Load Maze Layer
	main_layer.add_child(_maze_scene)
	
	# Load Platform Layer
	main_layer.add_child(_platform_scene)

	# Fill each list with all valid indices initially, excluding the final platform level and Timer.
	for i in range(_platform_scene.get_child_count() - 2):
		platform_list.append(i)
	
	for i in range(_maze_scene.get_child_count() - 1):
		maze_list.append(i)
	
	# Shuffle them for random selection if desired:
	platform_list.shuffle()
	maze_list.shuffle()
	
	load_game(_platform_scene)

func load_game(platform_instance: Node) -> void:
	# Create a level collection
	if !custom_level.is_empty():
		if custom_level == "Maze" or custom_level.begins_with("Maze: ") or custom_level.begins_with("Platform: "):
			level_collection.append(custom_level)
	
	var gen_level_amount: int = get_custom_level_amount()
	
	for i in range(gen_level_amount): 
		var this_level = randi_range(0, 1)
		if this_level == 0:
			level_collection.append("Maze")
		else:
			level_collection.append("Platform")
	
	for i in range(3):
		# Check levels thrice to optimize for speed and best level set.
		level_check()
	
	level_set(platform_instance)
	emit_signal("finished_level_set")


func get_custom_level_amount() -> int:
	if custom_level.is_empty():
		return level_amount
	else:
		return level_amount -1


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
				var resolved = str(get_maze_index(_maze_scene))
				level_collection[i] = "Maze: " + resolved
			
		elif level_collection[i] == "Platform":
			var resolved = str(get_platform_index(_platform_scene, i))
			level_collection[i] = "Platform: " + resolved
	
	# Append last level
	level_collection.append("Platform: " + str(platform_instance.get_child_count() - 2))


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
	load_level()
	
	# If completed all levels, finalize
	if level == level_collection.size() - 1:
		menu.is_timer_running = false
		_popup_scene.output_timer(snapped(menu.time_elapsed, 0.01), level_times)
		main_layer.add_child(_popup_scene)
		menu.is_popup_displaying = true
		_popup_scene.animation_player.play("show_finish")


func load_level() -> void:
	# Reset the key color list
	_reset_keys()
	
	var maze_scene = preload("res://scenes/2D/maze_layer.tscn").instantiate()
	var platform_scene = preload("res://scenes/2D/platform_layer.tscn").instantiate()
	
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
	var gen_maze_scene = load("res://scenes/2D/gen_maze_layer.tscn")
	var gen_maze_instance = gen_maze_scene.instantiate()
	main_layer.add_child(gen_maze_instance)
	
	gen_maze_instance.load_maze(level)


func load_maze(selected_level: int) -> void:
	# Set game mode
	game_mode = 2
	
	var maze_scene = preload("res://scenes/2D/maze_layer.tscn").instantiate()
	main_layer.add_child(maze_scene)
	
	maze_scene.disable_all_levels()
	maze_scene.load_level(selected_level)


func load_platform(selected_level: int) -> void:
	# Set game mode
	game_mode = 1
	
	var platform_scene = preload("res://scenes/2D/platform_layer.tscn").instantiate()
	main_layer.add_child(platform_scene)
	
	platform_scene.disable_all_levels()
	platform_scene.load_level(selected_level)


func get_platform_index(platform_scene: Node, current_level_index: int) -> int:
	# Only gather from first 5 children if current level is less than 6
	var limit = 0
	if current_level_index <= 5:
		limit = 5
	else:
		# Account for Timer child and last level
		limit = platform_scene.get_child_count() - 2
	
	if platform_list.is_empty():
		# Use the full range of available levels, not limited to 5
		for i in range(limit): 
			platform_list.append(i)
		platform_list.shuffle()
	
	return platform_list.pop_back()


func get_maze_index(maze_scene: Node) -> int:
	
	# If the list is empty, refill it
	if maze_list.is_empty():
		# Account for Timer child
		for i in range(maze_scene.get_child_count() - 1):
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


func _is_valid_custom_level(level_string: String) -> bool:
	# 1) Generated Maze
	if level_string == "Maze":
		return true
	
	# 2) Maze: X
	if level_string.begins_with("Maze: "):
		var parts = level_string.split(": ")
		if parts.size() < 2:
			return false
		var maze_index = int(parts[1])
		# Check if the index is within level count
		if maze_index < 0 or maze_index >= _maze_scene.get_child_count():
			return false
		return true
	
	# 3) Platform: X
	if level_string.begins_with("Platform: "):
		var parts = level_string.split(": ")
		if parts.size() < 2:
			return false
		var platform_index = int(parts[1])
		# Check if the index is within level count
		if platform_index < 0 or platform_index >= _platform_scene.get_child_count():
			return false
		return true
	
	# If none of the above matched, string is invalid
	return false


func _reset_keys() -> void:
	possible_colors = [Color.WHITE, Color.YELLOW, Color.ORANGE, Color.GREEN, Color.RED, Color.BLUE]
	selected_colors = []


func get_color(id: int) -> Color:
	var color: Color = Color.WHITE  # Set a default to avoid returning nil
	var found_color = false
	
	if !selected_colors.is_empty():
		for item in selected_colors:
			if item["id"] == id:
				color = item["color"]
				found_color = true
				break
	
	if !found_color:
		if possible_colors.size() > 0:
			var rand_index = randi_range(0, possible_colors.size() - 1)
			color = possible_colors[rand_index]
			selected_colors.append({"id": id, "color": color})
			possible_colors.remove_at(rand_index)
	
	return color


func _on_finished_level_set() -> void:
	load_level()
	
	emit_signal("finished_loading")
