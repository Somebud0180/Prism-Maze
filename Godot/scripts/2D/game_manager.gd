extends Node
class_name GameManager

signal finished_loading

# The Game Manager holds the set of levels, game mode, and level progression.
# It is also responsible for loading the game and the levels.

@onready var game = $".."
@onready var menu = get_node("/root/Menu")
@onready var main_layer = $"../MainLayer"
@onready var player = $"../Player"
@onready var animation_player = $"../AnimationPlayer"
@onready var audio_player = $"../AudioStreamPlayer2D"

## Enables unlimited levels.  [code]level_amount[/code]  is disregarded when enabled.
@export var infinite_levels: bool = false

## The amount of levels to create for the playthrough. Excluding the final level.
@export var level_amount: int = 25

 ## A level to add first to the game, used for debugging. Follows the Maze: X, Platform: X, Maze format
@export var custom_level: String:
	set(value):
		_is_valid_custom_level(value)
		custom_level = value 

var _maze_scene = preload("res://scenes/2D/maze_layer.tscn").instantiate()
var _platform_scene = preload("res://scenes/2D/platform_layer.tscn").instantiate()

var custom_level_loaded = false
var level: int = 0
var level_times = []

var possible_colors = [Color.WHITE, Color.YELLOW, Color.ORANGE, Color.GREEN, Color.RED, Color.BLUE]
var selected_colors = []

var level_collection: Array[String] = [] # The level set for the current playthrough
var game_mode: int = 2  # 1: Platformer, 2: Maze
var platform_list: Array[int] = []
var maze_list: Array[int] = []

var finish_sound = [load("res://resources/Sound/Level/SFX/Finish.wav"), load("res://resources/Sound/Level/SFX/Finish 2.wav"), load("res://resources/Sound/Level/SFX/Finish 3.wav")]

func _ready() -> void:
	if menu.in_game:
		infinite_levels = menu.is_infinite_levels
	
	randomize()
	# Reset the key color list
	_reset_keys()
	
	await Signal(player, "player_loaded")
	player._on_game_manager_loaded()
	
	next_level()
	await get_tree().process_frame
	emit_signal("finished_loading")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("load_level"):
		progress_level()


func next_level() -> void:
	_reset_keys()
	
	if infinite_levels or level <= level_amount:
		for child in main_layer.get_children():
			child.queue_free()
		
		var new_level = get_next_level()
		if new_level:
			level_collection.append(new_level)
			load_rand_level(new_level)


func get_next_level() -> String:
	# If a custom level is defined and not loaded yet, return it
	if !custom_level.is_empty() and !custom_level_loaded:
		custom_level_loaded = true
		return custom_level
	
	if !infinite_levels and level == level_amount:
		return "Platform: End"
	
	var candidate: String = ""
	var tries: int = 10
	while tries > 0:
		# Randomly pick Maze or Platform (using your existing logic)
		randomize()
		var level_rand = randi_range(0, 3)
		if level_rand == 0:
			candidate = "Maze"
		elif level_rand == 1:
			candidate = "GenMaze"
		elif level_rand == 2 or level_rand == 3:
			candidate = "Platform"
		
		# Convert candidate placeholder into a resolved value
		candidate = get_random_level(candidate)
		
		# Check if candidate is equal to the last played level.
		# Here we assume level tells you the current level index,
		# and that level_collection holds the sequence of finalized level strings.
		if level > 0 and candidate == level_collection[level - 1]:
			tries -= 1
			continue
		else:
			return candidate
	
	# If all attempts failed, default to GenMaze
	push_warning("Cannot find a random Level! Defaulting to GenMaze.")
	return "GenMaze"


func get_random_level(selected_level: String) -> String:
	# Replace placeholder platformer levels to real levels, keep GenMaze
	if selected_level == "Maze":
		var resolved = str(get_maze_index(_maze_scene))
		return "Maze: " + resolved
	elif selected_level == "Platform":
		var resolved = str(get_platform_index(_platform_scene))
		return "Platform: " + resolved
	else:
		return "GenMaze"


func load_rand_level(selected_level: String):
	if selected_level == "GenMaze":
		load_gen_maze()
	elif selected_level.begins_with("Maze"):
		var level_name = selected_level.replace("Maze: ", "")
		load_maze(level_name)
	elif selected_level.begins_with("Platform"):
		var level_name = selected_level.replace("Platform: ", "")
		load_platform(level_name)
	
	player.position = Vector2i(0,0)
	
	# Enable player again
	player.game_initialized = true


func get_custom_level_amount() -> int:
	if custom_level.is_empty():
		return level_amount
	else:
		return level_amount - 1


func level_check() -> void:
	# Improve random level list
	for i in range(level_collection.size()):
		if i > 1:
			if level_collection[i] == "Maze" and level_collection[i - 1] == "Maze" and level_collection[i - 2] == "Maze":
				level_collection[i] = "Platform"
			elif level_collection[i] == "Platform" and level_collection[i - 1] == "Platform" and level_collection[i - 2] == "Platform":
				level_collection[i] = "Maze"


func level_set() -> void:
	# Replace placeholder platformer levels to real levels
	for i in range(level_collection.size()):
		if level_collection[i] == "Maze":
			if randi_range(0, 2) == 1:
				var resolved = str(get_maze_index(_maze_scene))
				level_collection[i] = "Maze: " + resolved
			
		elif level_collection[i] == "Platform":
			var resolved = str(get_platform_index(_platform_scene))
			level_collection[i] = "Platform: " + resolved
	
	# Append last level
	level_collection.append("Platform: End")


func progress_level() -> void:
	if infinite_levels or level < level_amount:
		# Compute how long this level took
		var total_previous = 0.0
		for t in level_times:
			total_previous += t
		
		var current_time = menu.time_elapsed
		var current_level_time = current_time - total_previous
		level_times.append(snapped(current_level_time, 0.01))
		
		# Reset the key color list
		_reset_keys()
		
		# Disable player for a moment
		player.game_initialized = false
		
		# Reset player gravity and sprite
		player.gravity_direction = 1
		
		# Increase level index and load next
		level += 1
		next_level()
		audio_player.stream = finish_sound[randi_range(0, finish_sound.size() - 1)]
		audio_player.play()
		
		# If completed all levels, finalize
		if !infinite_levels and level == level_amount:
			if menu.menu_state == Menu.STATE.GAMEMIXED:
				var _level = get_node("../../../")
				var _layer = get_node("../../../../")
				_layer.current_level += 1
				_layer.place_level_async()
				_level.open_door()
			else:
				menu.is_timer_running = false
				menu.is_popup_displaying = true
				
				var popup_scene = get_tree().get_root().get_node_or_null("LevelPopup")
				
				if popup_scene != null:
					popup_scene.output_timer(snapped(menu.time_elapsed, 0.01), level_times)
					popup_scene.animation_player.play("show_finish")


func load_gen_maze() -> void:
	# Set game mode
	game_mode = 2
	
	# Load and instantiate a new maze scene.
	var gen_maze_scene = load("res://scenes/2D/gen_maze_layer.tscn")
	var gen_maze_instance = gen_maze_scene.instantiate()
	
	main_layer.add_child(gen_maze_instance)
	gen_maze_instance.load_maze(level)


func load_maze(selected_level: String) -> void:
	# Set game mode
	game_mode = 2
	
	var maze_scene = preload("res://scenes/2D/maze_layer.tscn").instantiate()
	
	main_layer.add_child(maze_scene.return_level(selected_level))
	main_layer.get_child(main_layer.get_child_count() - 1).show()
	main_layer.get_child(main_layer.get_child_count() - 1).init_level()


func load_platform(selected_level: String) -> void:
	# Set game mode
	game_mode = 1
	
	var platform_scene = preload("res://scenes/2D/platform_layer.tscn").instantiate()
	
	main_layer.add_child(platform_scene.return_level(selected_level))
	main_layer.get_child(main_layer.get_child_count() - 1).show()
	main_layer.get_child(main_layer.get_child_count() - 1).init_level()


func get_platform_index(platform_scene: Node) -> int:
	if platform_list.is_empty():
		# Account for special levels
		for i in range(platform_scene.get_child_count() - 3): 
			platform_list.append(i)
		platform_list.shuffle()
	
	return platform_list.pop_back()


func get_maze_index(maze_scene: Node) -> int:
	# If the list is empty, refill it
	if maze_list.is_empty():
		for i in range(maze_scene.get_child_count() - 1):
			maze_list.append(i)
		maze_list.shuffle()
	
	return maze_list.pop_back()


func reset_game() -> void:
	for child in main_layer.get_children():
		child.queue_free()
	
	level_collection = []
	platform_list = []
	maze_list = []
	menu.time_elapsed = 0.0


func _is_valid_custom_level(level_string: String) -> String:
	# Exit if empty
	if level_string.is_empty():
		return ""
	
	# 1) Generated Maze
	if level_string == "GenMaze":
		return level_string
	
	# 2) Maze: X
	if level_string.begins_with("Maze: "):
		var child_name = level_string.replace("Maze: ", "")
		# Confirm if _maze_scene actually has a child with the name child_name
		if not _maze_scene.has_node(child_name):
			push_warning("Custom maze level does not exist! Ignored.")
			return ""
		return level_string
	
	# 2) Platform: X
	if level_string.begins_with("Platform: "):
		var child_name = level_string.replace("Platform: ", "")
		# Confirm if _platform_scene actually has a child with the name child_name
		if not _platform_scene.has_node(child_name):
			push_warning("Custom platform level does not exist! Ignored.")
			return ""
		return level_string
	
	# If none of the above matched, string is invalid
	push_warning("Invalid custom_level, ignored. Must be one of: 'GenMaze', 'Maze: <number>', or 'Platform: <number>'!")
	return ""


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
