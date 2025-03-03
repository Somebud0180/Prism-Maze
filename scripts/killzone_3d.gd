extends Area3D

@onready var timer = $Timer
@onready var player = get_node("/root/Game3D/Player3D")

func _on_body_entered(_body: Node3D) -> void:
	print("You Died")
	player = get_node("/root/Game3D/Player3D")
	player.gravity_direction = 1
	timer.start()


func _on_timer_timeout() -> void:
	player.velocity.x = 0
	player.velocity.y = 0
	player.position = Vector3(0, 10, 0)
	timer.stop()
