extends AspectRatioContainer

@onready var menu = get_node("/root/Menu")
@export var game_mode_rect: TextureRect
@export var animation_player: AnimationPlayer

var game_mode = 0

func _on_normal_pressed() -> void:
	menu.is_infinite_levels = false
	animation_player.play("hide_infinite")
	await animation_player.animation_finished
	_load_game()


func _on_infinite_pressed() -> void:
	menu.is_infinite_levels = true
	animation_player.play("hide_infinite")
	await animation_player.animation_finished
	_load_game()


func _load_game() -> void:
	game_mode_rect._set_game_mode_rect(menu.is_infinite_levels)
	
	if game_mode == 0:
		# Check if already in-game in another dimension
		if menu.in_game_3d:
			menu._reset_game_3d()
		
		menu.menu_state = Menu.STATE.GAME
		menu.animation_player.play("hide_main_invisible")
		await menu.animation_player.animation_finished
		if !menu.in_game:
			LoadingManager.load_scene(menu.game_scene_path)
			menu.in_game = true
		else:
			for music_player in get_tree().get_nodes_in_group("LevelMusicPlayer"):
						music_player.fade_music_in()
	elif game_mode == 1:
			# Check if already in-game in another dimension
		if menu.in_game:
			menu._reset_game()
		
		menu.menu_state = Menu.STATE.GAME3D
		menu.animation_player.play("hide_main_invisible")
		await menu.animation_player.animation_finished
		
		if !menu.in_game_3d:
			LoadingManager.load_scene(menu.game_scene_3d_path)
			menu.in_game_3d = true
		else:
			for music_player in get_tree().get_nodes_in_group("LevelMusicPlayer"):
						music_player.fade_music_in()
