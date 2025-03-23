extends Node3D

@onready var menu = get_node("/root/Menu")

func _ready() -> void:
	set_shadow()
	set_shadow_quality()
	set_sdfgi()


func set_shadow() -> void:
	$DirectionalLight3D.shadow_enabled = menu.shadow_enabled


func set_shadow_quality() -> void:
	$DirectionalLight3D.directional_shadow_mode = menu.shadow_quality


func set_sdfgi() -> void:
	$WorldEnvironment.environment.sdfgi_enabled = menu.sdfgi_enabled
	RenderingServer.gi_set_use_half_resolution(!menu.sdfgi_full_res)
	
	if $WorldEnvironment.environment.sdfgi_enabled:
		$Player3D/Player/OmniLight3D.light_energy = 1.0
		$Player3D/Player/OmniLight3D.light_indirect_energy = 5.0
		$DirectionalLight3D.light_energy = 2.0
		$DirectionalLight3D.light_indirect_energy = 5.0
	else:
		$Player3D/Player/OmniLight3D.light_energy = 0.0
		$Player3D/Player/OmniLight3D.light_indirect_energy = 0.0
		$DirectionalLight3D.light_energy = 0.5
		$DirectionalLight3D.light_indirect_energy = 1.0


func _on_level_layer_3d_finished_loading() -> void:
	await get_tree().create_timer(0.5).timeout
	$Player3D._on_game_loaded()