extends Area3D

@export var tutorial: LevelLayer3D.TUTORIAL_STATE
var level_layer

func _on_body_entered(body: Node3D) -> void:
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = tutorial
