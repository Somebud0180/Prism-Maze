extends Node

signal finish_tween_out

@onready var menu = get_node("/root/Menu")
@onready var audio_player = $AudioStreamPlayer

@export var transition_duration = 0.5
@export var transition_type = 1

var music_played = []
var music = [load("res://resources/Sound/Level/Music/Level.wav"), load("res://resources/Sound/Level/Music/Robot.wav")]
var finish_music = load("res://resources/Sound/Level/Music/Finish.wav")
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
	if tween_music:
		tween_music.stop()
	tween_music = get_tree().create_tween()
	tween_music.tween_property(audio_player, "volume_db", -80, transition_duration * 2).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()
	tween_music.tween_callback(emit_signal.bind("finish_tween_out"))


func fade_music_in():
	# tween music volume up to 0
	if tween_music:
		tween_music.stop()
	audio_player.stream_paused = false
	tween_music = get_tree().create_tween()
	tween_music.tween_property(audio_player, "volume_db", music_volume, transition_duration).set_trans(transition_type).set_ease(Tween.EASE_IN)
	tween_music.play()


func _on_finish_tween_out():
	audio_player.stream_paused = true


func play_random_music():
	# Pick a random theme song
	randomize()
	var chosen_index = randi() % music.size()
	
	# Check if song is already played, pick another if so.
	while music_played.has(music[chosen_index]):
		# Check if song played is already full, reset if so.
		if music_played.size() == music.size():
			music_played.clear()
			
		chosen_index = randi() % music.size()
	
	audio_player.stop()
	audio_player.stream = music[chosen_index]
	music_played.append(music[chosen_index])
	audio_player.play()


func play_finish():
	fade_music_out()
	await finish_tween_out
	audio_player.stop()
	audio_player.stream = finish_music
	audio_player.play()
	audio_player.volume_db = clamp(-20, -80, music_volume)
	fade_music_in()


func _on_audio_stream_player_finished() -> void:
	# Wait for awhile before starting a new song
	await get_tree().create_timer(randf_range(5.0, 20.0)).timeout
	
	# Play a new song
	play_random_music()
