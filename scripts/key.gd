extends Area2D


@onready var game_manager = get_node("/root/Game/GameManager")


@export var id = 0
var color = Color.WHITE

func _ready() -> void:
	# Pick a random color and set it as the color
	color = game_manager.get_color(id)
	visible = true
	$AnimatedSprite2D.self_modulate = color
	
	call_deferred("_init_zone")


func get_key() -> void:
	visible = false


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
	print("Grabbed Key")
	game_manager.store_key(id)
	get_key()
