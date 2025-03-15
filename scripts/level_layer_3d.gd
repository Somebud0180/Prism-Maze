extends Node3D
class_name LevelLayer3D

signal finished_loading

@onready var player_3d = %Player3D
@onready var tutorial_layer = %TutorialLayer
@onready var _level_3d = preload("res://scenes/3D/level_3d.tscn").instantiate()

## Enables unlimited levels.  [code]level_amount[/code]  is disregarded when enabled.
@export var infinite_levels: bool = false

## The amount of levels to spawn
@export var level_amount: int = 6 

## Spawn this amount of levels in advance
@export var level_advance: int = 1 

## Cull levels past this amount
@export var level_cull: int = 5 

## Use the tutorial level as the spawn
@export var is_starting_on_tutorial = false

enum TUTORIAL_STATE { RESET, MOVE, JUMP, DOUBLE_JUMP, WALL_JUMP, SUCCESS }
var tutorial_state = TUTORIAL_STATE.MOVE:
	set(value):
		tutorial_state = value
		change_overlay()

var starting_marker
var levels = [] # The levels in the node
var level_collection = [] # The final level set to be played
var current_level = 0


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("load_level"):
		place_level()


func _ready() -> void:
	# First, handle the starting level
	var copy_starting
	if is_starting_on_tutorial:
		var tutorial = _level_3d.get_child(0)
		copy_starting = tutorial.duplicate()
	else:
		var starting = _level_3d.get_child(1)
		copy_starting = starting.duplicate()
	
	add_child(copy_starting)
	level_collection.append(copy_starting)
	get_child(get_child_count() - 1)._show()
	
	starting_marker = level_collection[0].get_node("EntranceMarker")
	
	# Grab the marker’s global transform
	var spawn_transform = starting_marker.global_transform
	# Adjust the origin slightly so the player doesn't clip into the floor
	spawn_transform.origin += Vector3(0.0, 1.0, 0.0)
	
	# Now place the player at that Marker
	player_3d.global_transform = spawn_transform
	
	# Place level(s) in advance
	for i in range(level_advance):
		place_level()
	
	emit_signal("finished_loading")


func place_level():
	if infinite_levels or (current_level < level_amount):
		var next_level = _level_3d.get_next_random_level()
		if next_level:
			add_child(next_level)
			level_collection.append(next_level)
		
		# Show level in level_collection
		get_child(get_child_count() - 1)._show()
		
		var last_level = level_collection[get_child_count() - 2]
		var this_level = level_collection[get_child_count() - 1]
		
		var exit_marker = last_level.get_node("ExitMarker")
		var entrance_marker = this_level.get_node("EntranceMarker")
			
		var exit_global = exit_marker.global_transform
		var entrance_local = entrance_marker.transform
		this_level.global_transform = exit_global * entrance_local.affine_inverse()
		
		# Remove old levels
		cull_levels()


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
	# Resets the related variables
	levels = [] # The levels in the node
	level_collection = [] # The final level set to be played
	current_level = 0

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


func _on_tree_exiting() -> void:
	reset_game_3d()
