extends Area2D

func _ready() -> void:
	call_deferred("_init_zone")


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
	var player = get_node("../../../Player")
	player.gravity_direction = -1
