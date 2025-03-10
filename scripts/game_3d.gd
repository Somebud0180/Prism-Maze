extends Node3D

func _ready() -> void:
	await Signal(LoadingManager, "load_finish") 
	$Player3D._on_game_loaded()
