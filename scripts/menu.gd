extends Control

@export var main: NinePatchRect
@export var settings: NinePatchRect

@export var animation_player: AnimationPlayer
@export var resolution_picker: OptionButton

var simultaneous_scene = preload("res://scenes/game.tscn").instantiate()

enum STATE { MAIN, SETTINGS, CONTROLS, GAME }
var menu_state = STATE.MAIN
var in_game = false
var resolution = Vector2i(1280, 720)


func _input(event):
	if event.is_action_pressed("ui_cancel") and not animation_player.is_playing():
		match menu_state:
			STATE.SETTINGS:
				menu_state = STATE.MAIN
				hide_and_show("settings", "main")
			STATE.CONTROLS:
				menu_state = STATE.MAIN
				hide_and_show("controls", "main")
			STATE.GAME:
				menu_state = STATE.MAIN
				animation_player.play("show_main")
			STATE.MAIN:
				if in_game:
					menu_state = STATE.GAME
					animation_player.play("hide_main")
					await animation_player.animation_finished


func hide_and_show(first: String, second: String):
	animation_player.play("hide_" + first)
	await animation_player.animation_finished
	animation_player.play("show_" + second)


func _on_play_pressed() -> void:
	menu_state = STATE.GAME
	animation_player.play("hide_main")
	await animation_player.animation_finished
	get_tree().root.add_child(simultaneous_scene)
	in_game = true


func _on_settings_pressed() -> void:
	menu_state = STATE.SETTINGS
	hide_and_show("main", "settings")


func _on_controls_pressed() -> void:
	menu_state = STATE.CONTROLS
	hide_and_show("main", "controls")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_exit_settings_pressed() -> void:
	menu_state = STATE.MAIN
	hide_and_show("settings", "main")


func _on_exit_controls_pressed() -> void:
	menu_state = STATE.MAIN
	hide_and_show("controls", "main")


func _on_resolution_item_selected(index: int) -> void:
	# 1 : 1280x720
	# 2 : 1280x960
	# 3 : 640x480
	# 4 : 640x360
	match index:
		0:
			resolution = Vector2i(1280, 720)
		1:
			resolution = Vector2i(1280, 960)
		2:
			resolution = Vector2i(640, 480)
		3:
			resolution = Vector2i(640, 360)
	
	set_resolution()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		resolution_picker.disabled = true 
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		set_resolution()
		resolution_picker.disabled = false


func set_resolution() -> void:
	DisplayServer.window_set_size(resolution)

	# Get window placement
	var rect = DisplayServer.screen_get_usable_rect()
	var win_pos = DisplayServer.window_get_position()
	var x_overhang = (win_pos.x + resolution.x) - (rect.position.x + rect.size.x)
	var y_overhang = (win_pos.y + resolution.y) - (rect.position.y + rect.size.y)
	
	# Ensure the whole window is on-screen
	if x_overhang > 0:
		win_pos.x -= x_overhang
	if win_pos.x < rect.position.x:
		win_pos.x = rect.position.x
	
	if y_overhang > 0:
		win_pos.y -= y_overhang
	if win_pos.y < rect.position.y:
		win_pos.y = rect.position.y
	
	DisplayServer.window_set_position(win_pos)
