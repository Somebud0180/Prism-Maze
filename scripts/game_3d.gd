extends Node3D

func _ready() -> void:
	await Signal(LoadingManager, "load_finish") 


func _on_level_layer_3d_finished_loading() -> void:
	await get_tree().create_timer(0.5).timeout
	$Player3D._on_game_loaded()
