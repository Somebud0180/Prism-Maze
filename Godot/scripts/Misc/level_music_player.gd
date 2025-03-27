extends Node

@onready var menu = get_node("/root/Menu")
@onready var audio_player = $AudioStreamPlayer

@export var transition_duration = 0.5
@export var transition_type = 1

var music = [load("res://resources/Sound/Level/Music/Level.wav")]
var tween_music
var music_volume = 0.0:
	set(value):
		music_volume = value
		audio_player.volume_db = music_volume

func _ready() -> void:
	# Get music volume and play a random song on start
	var is_2d = get_parent().name == "Game"
	music_volume = menu.music_volume
	if !(is_2d and menu.in_game_3d):
		play_random_music()


func fade_music_out():
	# tween music volume down to -80
	print("Fading out")
	tween_music = get_tree().create_tween()
	tween_music.tween_property(audio_player, "volume_db", -80, transition_duration * 2).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()
	audio_player.stream_paused = true


func fade_music_in():
	# tween music volume up to 0
	audio_player.stream_paused = false
	tween_music = get_tree().create_tween()
	tween_music.tween_property(audio_player, "volume_db", music_volume, transition_duration).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()


func play_random_music():
	# Pick a random theme song
	randomize()
	var chosen_index = randi() % music.size()
	
	print("playing music")
	audio_player.stop()
	audio_player.stream = music[chosen_index]
	audio_player.play()


func _on_audio_stream_player_finished() -> void:
	# Wait for awhile before starting a new song
	await get_tree().create_timer(randf_range(1.0, 10.0)).timeout
	
	# Play a new song
	play_random_music()
