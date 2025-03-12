extends Node2D
class_name Door

var managers
var game_manager

@export var id = 0
var is_locked = true
var color = Color.WHITE


func validate_id() -> void:
	if !game_manager.selected_colors.is_empty:
		for item in game_manager.selected_colors:
			if item["id"] == id:
				color = item["color"]
	else:
		color = game_manager.get_color(id)


func update_lock() -> void:
	if is_locked:
		$StaticBody2D.process_mode = Node.PROCESS_MODE_INHERIT
		$Padlock.visible = true
		$Padlock.self_modulate = color
		$Gate.self_modulate = Color("ffffff")
	else:
		$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
		$Padlock.visible = false
		$Gate.self_modulate = Color(0.0, 200.0, 0.0)


func key_check(key_id: int) -> bool:
	if key_id == id:
		return true
	else:
		return false

func key_unlock(key_id: int) -> void:
	if key_id == id:
		is_locked = false
		update_lock()

func _ready() -> void:
	managers = get_tree().get_nodes_in_group("GameManager")
	if managers.size() > 0:
		game_manager = managers[0]
	
	validate_id()
	update_lock()
