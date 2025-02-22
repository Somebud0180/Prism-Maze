extends Control

@export var main: NinePatchRect
@export var settings: NinePatchRect

@export var animation_player: AnimationPlayer
@export var camera: Camera2D

var simultaneous_scene = preload("res://scenes/game.tscn").instantiate()

enum STATE { MAIN, SETTINGS, GAME }
var menu_state = STATE.MAIN
var in_game = false

func _ready() -> void:
	camera.enabled = true

func _input(event):
	if event.is_action_pressed("ui_cancel") and not animation_player.is_playing():
		match menu_state:
			STATE.SETTINGS:
				menu_state = STATE.MAIN
				hide_and_show("settings", "main")
			STATE.GAME:
				menu_state = STATE.MAIN
				simultaneous_scene.hide()
				camera.enabled = true
				animation_player.play("show_main")
			STATE.MAIN:
				if in_game:
					menu_state = STATE.GAME
					animation_player.play("hide_main")
					await animation_player.animation_finished
					camera.enabled = false
					simultaneous_scene.show()

func hide_and_show(first: String, second: String):
	animation_player.play("hide_" + first)
	await animation_player.animation_finished
	animation_player.play("show_" + second)


func _on_play_pressed() -> void:
	menu_state = STATE.GAME
	animation_player.play("hide_main")
	await animation_player.animation_finished
	camera.enabled = false
	get_tree().root.add_child(simultaneous_scene)
	simultaneous_scene.show()
	in_game = true


func _on_settings_pressed() -> void:
	menu_state = STATE.SETTINGS
	hide_and_show("main", "settings")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_exit_settings_pressed() -> void:
	menu_state = STATE.MAIN
	hide_and_show("settings", "main")
