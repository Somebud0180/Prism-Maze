extends Node3D

@export var conveyor_speed: float = 6.0
@onready var conveyor = %StaticBody3D
@onready var marker = %Marker3D

func _ready() -> void:
	var forward_dir = marker.global_transform.basis.z.normalized()
	conveyor.constant_linear_velocity = forward_dir * conveyor_speed
