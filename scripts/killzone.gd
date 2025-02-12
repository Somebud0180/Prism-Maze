extends Area2D

@onready var timer = $Timer
@onready var game_manager = get_node("/root/Game/GameManager")

func _on_body_entered(_body: Node2D) -> void:
	print("You Died")
	timer.start()
	

func _on_timer_timeout() -> void:
	game_manager.load_level()
