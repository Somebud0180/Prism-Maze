extends Area3D

var level_music_player
var has_played = false

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player3D" and !has_played:
		level_music_player = get_tree().get_first_node_in_group("LevelMusicPlayer")
		level_music_player.play_finish()
		has_played = true
