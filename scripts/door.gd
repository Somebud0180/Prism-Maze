extends Node2D
class_name Door

@onready var game_manager = get_node("/root/Game/GameManager")


@export var id = 0:
	set(value):
		is_locked = value
		validate_id()

var is_locked = true:
	set(value):
		is_locked = value
		update_lock()

var found_color = null
var color = Color.WHITE


func validate_id() -> void:
	found_color = null
	
	for item in game_manager.selected_colors:
		if item["id"] == id:
			found_color = item["color"]
			break
	
	if found_color == null:
		# Error out or handle the failure case
		push_error("Error: No matching color for door id = ", id)
	else:
		color = found_color


func update_lock() -> void:
	if is_locked:
		$StaticBody2D.process_mode = Node.PROCESS_MODE_INHERIT
		$Padlock.visible = true
		$Padlock.self_modulate = found_color
		$Gate.self_modulate = Color("ffffff")
	else:
		$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
		$Padlock.visible = false
		$Gate.self_modulate = Color(0.0, 200.0, 0.0)


func key_lock() -> void:
	if game_manager.stored_keys.has(id):
		is_locked = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	validate_id()
	update_lock()
