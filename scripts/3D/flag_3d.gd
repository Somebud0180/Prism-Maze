extends Area3D

var menu
var layer
var first_time = true

func _ready() -> void:
	call_deferred("_init_zone")


func _init_zone() -> void:
	# Re-enable collision monitoring.
	monitoring = true
	# Ensure every CollisionShape2D child is enabled.
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
	# Connect the body_entered signal if it isn't already connected.
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(_body: Node3D) -> void:
	if first_time:
		first_time = false
		menu = get_node("/root/Menu")
		layer = get_node("/root/Game3D/LevelLayer3D")
		if menu.character_life < 5:
			menu.character_life += 1
		
		layer.current_level += 1
		layer.place_level()
	
	get_parent_node_3d().open_door()
	
	print("You finished the level!")
