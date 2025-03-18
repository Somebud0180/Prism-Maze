extends Area3D

@export var tutorial: LevelLayer3D.TUTORIAL_STATE
var level_layer

func _ready() -> void:
	connect("body_exited", _on_body_exited)

func _on_body_entered(_body: Node3D) -> void:
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = tutorial

func _on_body_exited(_body: Node3D) -> void:
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = LevelLayer3D.TUTORIAL_STATE.RESET
