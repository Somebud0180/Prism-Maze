extends Area2D

@onready var timer = $Timer
var player
var menu

func _on_body_entered(_body: Node2D) -> void:
	print("You Died")
	player = get_node("/root/Game/Player")
	player.gravity_direction = 1
	timer.start()


func _on_timer_timeout() -> void:
	player = get_node("/root/Game/Player")
	menu = get_node("/root/Menu")
	menu.character_life -= 1
	player.velocity.x = 0
	player.velocity.y = 0
	player.position = Vector2i(0,0)
