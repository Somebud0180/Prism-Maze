extends Area2D
class_name Flag

var menu
var game_manager
var player

func _ready() -> void:
	$AnimationPlayer.play("RESET")
	call_deferred("_init_zone")
	
	get_tree().create_timer(0.5).timeout.connect(play_animation)


func _init_zone() -> void:
	# Re-enable collision monitoring.
	monitoring = true
	# Ensure every CollisionShape2D child is enabled.
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false
	# Connect the body_entered signal if it isn't already connected.
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(_body: Node2D) -> void:
	player = get_node("../../../Player")
	player.game_initialized = false
	game_manager = get_node("../../../GameManager")
	game_manager.progress_level()
	menu = get_node("/root/Menu")
	if menu.character_life < 5:
		menu.character_life += 1


func play_animation() -> void:
	$AnimationPlayer.play("show_flag")
