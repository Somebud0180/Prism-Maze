extends Area2D
class_name Killzone2D

@onready var timer = $Timer
var player
var menu

func _on_body_exited(_body: Node2D) -> void:
	player = get_node("../../../Player")
	
	# If player is uninitialized ignore death
	if !player.killable:
		return
	
	# Else, continue with death
	print("You Died")
	player.gravity_direction = 1
	timer.start()


func _on_timer_timeout() -> void:
	menu = get_node("/root/Menu")
	menu.character_life -= 1
	player.velocity.x = 0
	player.velocity.y = 0
	player.position = Vector2i(0,0)
	player.game_initialized = true
