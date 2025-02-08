extends Area2D

@onready var game_manager = %GameManager

# This MazeZone Area2D should trigger its body_entered signal
# when the player enters the zone on level 2.
#
# In this script we defer initializing the zone to ensure delayed updates occur outside of signal callbacks.
# We also make sure that the CollisionShape2D is enabled so that the body_entered signal can fire.
# Adjust collision layers, masks, and group checks as needed.

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
	print("MazeZone ready with monitoring: ", monitoring)

func _on_body_entered(body: Node) -> void:
	game_manager.GAME_MODE = 2
	print("MazeZone triggered by player!")
