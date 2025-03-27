extends Area2D

@onready var timer = $Timer
var player
var menu

func _on_body_exited(_body: Node2D) -> void:
	print("You Died")
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		
		# If player is uninitialized ignore death
		if !player.killable:
			return
		
		# Else, continue with death
		player.gravity_direction = 1
		timer.start()


func _on_timer_timeout() -> void:
	menu = get_node("/root/Menu")
	menu.character_life -= 1
	player.velocity.x = 0
	player.velocity.y = 0
	player.position = Vector2i(0,0)
