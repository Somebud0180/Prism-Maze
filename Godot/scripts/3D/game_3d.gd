extends Node3D
class_name Game3D

signal finished_loading

@onready var menu = get_node("/root/Menu")
@onready var level_layer_3d = $LevelLayer3D

func _ready() -> void:
	set_shadow()
	await get_tree().process_frame
	set_shadow_quality()
	await get_tree().process_frame
	set_sdfgi()
	
	await get_tree().process_frame
	emit_signal("finished_loading")


func set_shadow() -> void:
	$WorldEnvironment/DirectionalLight3D.shadow_enabled = menu.shadow_enabled


func set_shadow_quality() -> void:
	$WorldEnvironment/DirectionalLight3D.directional_shadow_mode = menu.shadow_quality


func set_sdfgi() -> void:
	$WorldEnvironment.environment.sdfgi_enabled = menu.sdfgi_enabled
	RenderingServer.gi_set_use_half_resolution(!menu.sdfgi_full_res)
	
	if $WorldEnvironment.environment.sdfgi_enabled:
		$Player3D/Player/OmniLight3D.visible = true
		$WorldEnvironment/DirectionalLight3D.light_energy = 2.0
		$WorldEnvironment/DirectionalLight3D.light_indirect_energy = 5.0
	else:
		$Player3D/Player/OmniLight3D.visible = false
		$WorldEnvironment/DirectionalLight3D.light_energy = 0.5
		$WorldEnvironment/DirectionalLight3D.light_indirect_energy = 1.0


func _on_level_layer_3d_finished_loading() -> void:
	emit_signal("finished_loading")
	
	await get_tree().create_timer(0.5).timeout
	$Player3D._on_game_loaded()
