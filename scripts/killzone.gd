extends Area2D

@onready var timer = $Timer
@onready var player = get_node("/root/Game/Player")

func _on_body_entered(_body: Node2D) -> void:
	print("You Died")
	timer.start()
	

func _on_timer_timeout() -> void:
	player = get_node("/root/Game/Player")
	player.position = Vector2i(0,0)
	timer.stop()
