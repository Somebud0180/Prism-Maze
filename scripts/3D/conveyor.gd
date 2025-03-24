extends Area3D
# filepath: /Users/ethanlagera/prism-maze/scripts/3D/conveyor.gd

@export var conveyor_speed: float = 0.5
@export var lerp_factor: float = 0.1

var bodies_in_area = []

func _physics_process(_delta: float) -> void:
	var forward_dir = -global_transform.basis.z.normalized()
	for body in bodies_in_area:
		if body is CharacterBody3D:
			body.conveyor_velocity = forward_dir * conveyor_speed


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		bodies_in_area.append(body)


func _on_body_exited(body: Node) -> void:
	body.conveyor_velocity = Vector3.ZERO
	bodies_in_area.erase(body)
