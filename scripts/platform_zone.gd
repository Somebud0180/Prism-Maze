extends Area2D

@onready var game_manager = get_node("/root/Game/GameManager")

# This PlatformZone Area2D should trigger its body_entered signal
# when the player enters the zone on level 1.
#
# In this script we defer enabling monitoring to ensure it is set after engine processing.
# We also connect the "body_entered" signal using a Callable to ensure the correct argument type.
# Adjust collision layers, masks, and group checks as needed for your project.

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
	print("PlatformZone ready with monitoring: ", monitoring)

func _on_body_entered(body: Node2D) -> void:
	game_manager.GAME_MODE = 1
	print("PlatformZone triggered by player!")
