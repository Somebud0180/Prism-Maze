extends Node3D
class_name LevelLayer3D

signal finished_loading

@onready var menu = get_node("/root/Menu")
@onready var player_3d = %Player3D
@onready var tutorial_layer = %TutorialLayer
@onready var _level_3d = preload("res://scenes/3D/level_3d.tscn").instantiate()

## A custom level to load as the next level (after spawn and  [code]level_advance[/code]  if set).
@export var custom_level: String:
	set(value):
		custom_level = value
		if _level_3d:
			_level_3d.custom_level_loaded = false  # Reset the state in Level3D

## Enables unlimited levels.  [code]level_amount[/code]  is disregarded when enabled.
@export var infinite_levels: bool = false:
	get():
		return menu.is_infinite_levels

## The amount of levels to spawn
@export var level_amount: int = 22

## Spawn this amount of levels in advance
@export var level_advance: int = 2

## Cull levels past this amount
@export var level_cull_enabled: bool = false

## Cull levels past this amount
@export var level_cull: int = 4

## Use the tutorial level as the spawn
@export var is_starting_on_tutorial = false

enum TUTORIAL_STATE { RESET, MOVE, JUMP, DOUBLE_JUMP, WALL_JUMP, SUCCESS, INTERACT }
var tutorial_state = TUTORIAL_STATE.RESET:
	set(value):
		tutorial_state = value
		change_overlay()

var levels = [] # The levels in the node
var level_collection = [] # The final level set to be played
var current_level = 0
var starting_marker: Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("load_level"):
		menu.cheat_used = true
		place_level_async()


func _ready() -> void:
	# First, handle the starting level
	var copy_starting
	if is_starting_on_tutorial:
		var tutorial = _level_3d.get_child(0)
		await get_tree().process_frame
		copy_starting = tutorial.duplicate()
		await get_tree().process_frame
	else:
		var starting = _level_3d.get_child(1)
		await get_tree().process_frame
		copy_starting = starting.duplicate()
		await get_tree().process_frame
	
	add_child(copy_starting)
	await get_tree().process_frame
	level_collection.append(copy_starting)
	get_child(get_child_count() - 1)._show()
	await get_tree().process_frame
	
	starting_marker = level_collection[0].get_node("EntranceMarker")
	
	# Grab the marker’s global transform
	var spawn_transform = starting_marker.global_transform
	# Adjust the origin slightly so the player doesn't clip into the floor
	spawn_transform.origin += Vector3(0.0, 1.0, 0.0)
	
	# Now place the player at that Marker
	player_3d.global_transform = spawn_transform
	
	# Place level(s) in advance
	for i in range(level_advance):
		place_level_async()
		await get_tree().process_frame
	
	emit_signal("finished_loading")


func place_level_async() -> void:
	# Step 1: Get the next level’s node
	var next_level = _level_3d.get_next_level(infinite_levels, levels.size() + 1, custom_level, level_amount)
	
	if next_level == null:
		return
	
	levels.append(next_level)
	
	# Yield a frame to avoid freezing if next_level is large
	await get_tree().process_frame
	
	if next_level:
		add_child(next_level)
		level_collection.append(next_level)
		
		# Show on the next frame
		await get_tree().process_frame
		get_child(get_child_count() - 1)._show()
		
		# Position and cull if enabled
		position_level(level_collection)
		
		if level_cull_enabled:
			cull_levels()


func position_level(_level_collection):
	var last_level = _level_collection[get_child_count() - 2]
	var this_level = _level_collection[get_child_count() - 1]
	
	var exit_marker = last_level.get_node("ExitMarker")
	var entrance_marker = this_level.get_node("EntranceMarker")
		
	var exit_global = exit_marker.global_transform
	var entrance_local = entrance_marker.transform
	this_level.global_transform = exit_global * entrance_local.affine_inverse()


func cull_levels():
	if level_collection.size() > level_cull and get_child_count() > level_cull:
		# Close door of the second oldest level
		level_collection[1].close_door()
		await Signal(level_collection[1], "door_close_animation_finished")
		
		# Remove from both the scene tree and the level_collection
		var removed_level = level_collection[0]
		removed_level.queue_free()
		level_collection.remove_at(0)


func reset_game_3d():
	# Resets the level_3d related variables (just in-case)
	_level_3d.custom_level_loaded = false
	_level_3d.level_indices_used = []
	_level_3d.last_level = null
	
	# Resets related variables
	levels = [] # The levels in the node
	level_collection = [] # The final level set to be played
	current_level = 0
	starting_marker = null
	tutorial_state = TUTORIAL_STATE.RESET


func change_overlay():
	match tutorial_state:
		TUTORIAL_STATE.RESET:
			tutorial_layer.reset_tutorial()
		TUTORIAL_STATE.MOVE:
			tutorial_layer.move_tutorial()
		TUTORIAL_STATE.JUMP:
			tutorial_layer.jump_tutorial()
		TUTORIAL_STATE.DOUBLE_JUMP:
			tutorial_layer.double_jump_tutorial()
		TUTORIAL_STATE.WALL_JUMP:
			tutorial_layer.wall_jump_tutorial()
		TUTORIAL_STATE.SUCCESS:
			tutorial_layer.success_tutorial()
		TUTORIAL_STATE.INTERACT:
			tutorial_layer.interact_tutorial()
