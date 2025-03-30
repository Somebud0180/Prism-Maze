extends Area3D

var old_speed

func _ready() -> void:
	old_speed = get_tree().get_first_node_in_group("Player3D").SPEED


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player3D":
		body.SPEED = 1.0


func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player3D":
		body.SPEED = old_speed
