extends Area3D

@export var reduce_life_by = 1
@onready var timer = $Timer
@onready var viewport = get_node_or_null("../ViewportQuad")
var player
var menu
var level

func _on_body_entered(_body: Node3D) -> void:
	player = get_node("/root/Game3D/Player3D")
	player.gravity_direction = 1
	timer.start()


func _on_timer_timeout() -> void:
	menu = get_node("/root/Menu")
	level = get_parent_node_3d()
	var entrance_marker = level.get_node("EntranceMarker")
	var respawn_point = entrance_marker.global_transform
	
	# Check if this level doesn't progress via minigame (or else the game softlocks when player dies after completing)
	if !viewport:
		level.close_door(2.0)
		
	respawn_point.origin += Vector3(0, 1, -1)
	
	# Check if this killzone reduces by 0 (Early Death/Tutorial Death)
	if reduce_life_by == 0 and !Achievements.achievements["EARLY_DEATH"]:
		Achievements.set_achievement("EARLY_DEATH")
	
	menu.character_life -= reduce_life_by
	player.velocity.x = 0
	player.velocity.y = 0
	player.global_transform = respawn_point
