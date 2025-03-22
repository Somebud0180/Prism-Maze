extends Node3D

@export var audio_player: AudioStreamPlayer
@export var transition_duration = 0.5
@export var transition_type = 1

@onready var menu = get_node("/root/Menu")

var music = [load("res://resources/Sound/Level/Music/Level.wav")]
var tween_music
var music_volume = 0.0:
	set(value):
		music_volume = value
		audio_player.volume_db = music_volume

func _ready() -> void:
	# Play a random song on start
	play_random_music()
	
	await Signal(LoadingManager, "load_finish") 
	set_sdfgi()


func set_shadow() -> void:
	$DirectionalLight3D.shadow_enabled = menu.shadow_enabled

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


func fade_music_out():
	# tween music volume down to -80
	print("Fading out")
	tween_music = get_tree().create_tween()
	tween_music.tween_property(audio_player, "volume_db", -80, transition_duration).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()
	audio_player.stream_paused = true


func fade_music_in():
	# tween music volume up to 0
	tween_music = get_tree().create_tween()
	audio_player.stream_paused = false
	tween_music.tween_property(audio_player, "volume_db", music_volume, transition_duration).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()


func play_random_music():
	# Pick a random theme song
	randomize()
	var chosen_index = randi() % music.size()
	
	audio_player.stream = music[chosen_index]
	audio_player.play()

func _on_audio_stream_player_finished() -> void:
	# Wait for awhile before starting a new song
	await get_tree().create_timer(randf_range(1.0, 10.0)).timeout
	
	# Play a new song
	play_random_music()
