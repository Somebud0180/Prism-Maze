extends StaticBody3D

@export var conveyor_speed: float = 6.0
@onready var marker = %Marker3D

func _ready() -> void:
	var forward_dir = marker.global_transform.basis.z.normalized()
	constant_linear_velocity = forward_dir * conveyor_speed
