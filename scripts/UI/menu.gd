extends Control
class_name Menu

const _VirtualControllerHelper = preload("res://scripts/Misc/virtual_controller_helper.gd")

@export var main: NinePatchRect
@export var settings: NinePatchRect
@export var animation_player: AnimationPlayer

@export var game_overlay: CanvasLayer
@export var health_bar: ProgressBar

@onready var settings_node = %Settings
@onready var menu_button = %MenuButton

var is_loading = false
var last_state = STATE.MAIN
var is_popup_displaying = false

var time_elapsed: float = 0.0
var is_timer_running: bool = false

@onready var _popup_scene = get_tree().get_first_node_in_group("LevelPopup")
var _game_scene = preload("res://scenes/2D/game.tscn").instantiate()
var _game_scene_3d = preload("res://scenes/3D/game_3d.tscn").instantiate()

var game_scene_path = "res://scenes/2D/game.tscn"
var game_scene_3d_path = "res://scenes/3D/game_3d.tscn"

enum WINDOW_STATE { FULLSCREEN, WINDOWED }
var window_state = WINDOW_STATE.WINDOWED:
	set(value):
		window_state = value
		settings_node._manage_resolution_picker()

enum STATE { MAIN, SETTINGS, CONTROLS, OVERLAY, GAME, GAME3D, GAMEMIXED }
var menu_state = STATE.MAIN:
	set(value):
		manage_game_timer(value)
		menu_state = value
		menu_button._manage_visibility()
		_manage_touch_controller()

var in_game = false:
	set(value):
		in_game = value
		_manage_game_overlay()

var in_game_3d = false:
	set(value):
		in_game_3d = value
		_manage_game_overlay()

# Game Settings
var player_color: Color = Color.WHITE:
	set(value):
		player_color = value
		settings_node._update_player_color()
		_config_save()

var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_config_save()

var resolution = Vector2i(1280, 720):
	set(value):
		resolution = value
		_config_save()


var shadow_enabled: bool = true:
	set(value):
		shadow_enabled = value
		_config_save()
		var game_3d = get_tree().get_first_node_in_group("Game3D")
		if game_3d:
			game_3d.set_shadow()

var sdfgi_enabled: bool = true:
	set(value):
		sdfgi_enabled = value
		_config_save()
		var game_3d = get_tree().get_first_node_in_group("Game3D")
		if game_3d:
			game_3d.set_sdfgi()

var sdfgi_full_res: bool = false:
	set(value):
		sdfgi_full_res = value
		_config_save()
		var game_3d = get_tree().get_first_node_in_group("Game3D")
		if game_3d:
			game_3d.set_sdfgi()

@export var character_life: int = 5:
	set(value):
		character_life = value
		health_bar.value = value
		_check_health()


func _process(delta: float) -> void:
	if is_timer_running:
		time_elapsed += delta


func _ready() -> void:
	$MenuLayer.show()
	$GameOverlay.hide()
	animation_player.play("RESET_main")
	
	settings_node._add_full_window_resolution()
	settings_node._add_resolutions()
	settings_node._manage_resolution_picker()
	
	# Apply configurations
	_config_load()
	
	_manage_touch_controller()
	
	$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()


func _input(event):
	if event.is_action_pressed("ui_cancel") and not animation_player.is_playing() and not _popup_scene.is_playing and not is_loading:
		match menu_state:
			STATE.SETTINGS:
				menu_state = STATE.MAIN
				_hide_and_show("settings", "main")
				await animation_player.animation_finished
				$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()
			STATE.CONTROLS:
				menu_state = STATE.MAIN
				_hide_and_show("controls", "main")
				await animation_player.animation_finished
				$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()
			STATE.GAME, STATE.GAME3D, STATE.GAMEMIXED, STATE.OVERLAY:
				last_state = menu_state
				menu_state = STATE.MAIN
				animation_player.play("show_main")
				_manage_popup(menu_state)
				await animation_player.animation_finished
				$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()
			STATE.MAIN:
				# Recover menu state
				menu_state = last_state
				
				if in_game:
					animation_player.play("hide_main_invisible")
					_manage_popup(menu_state)
				elif in_game_3d:
					animation_player.play("hide_main_invisible")


func manage_background(_is_visible: bool):
	# Control the parallax background visibility
	$Background.visible = _is_visible


func _hide_and_show(first: String, second: String):
	animation_player.play("hide_" + first)
	await animation_player.animation_finished
	animation_player.play("show_" + second)


func _on_play_pressed() -> void:
	# Check if already in-game in another dimension
	if in_game_3d:
		_reset_game_3d()
	
	menu_state = STATE.GAME
	animation_player.play("hide_main_invisible")
	await animation_player.animation_finished
	if !in_game:
		LoadingManager.load_scene(game_scene_path)
		in_game = true


func _on_play_3d_pressed() -> void:
	# Check if already in-game in another dimension
	if in_game:
		_reset_game()
	
	menu_state = STATE.GAME3D
	animation_player.play("hide_main_invisible")
	await animation_player.animation_finished
	
	if !in_game_3d:
		LoadingManager.load_scene(game_scene_3d_path)
		in_game_3d = true


func _on_settings_pressed() -> void:
	menu_state = STATE.SETTINGS
	_hide_and_show("main", "settings")
	$"MenuLayer/Settings/TabContainer".grab_focus()


func _on_controls_pressed() -> void:
	menu_state = STATE.CONTROLS
	_hide_and_show("main", "controls")
	$"MenuLayer/Controls/Exit Controls".grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_exit_settings_pressed() -> void:
	menu_state = STATE.MAIN
	_hide_and_show("settings", "main")
	$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()


func _on_exit_controls_pressed() -> void:
	menu_state = STATE.MAIN
	_hide_and_show("controls", "main")
	$MenuLayer/Main/Main/VBoxContainer/Play.grab_focus()


func _reset_game() -> void:
	# Return background visibility
	manage_background(true)
	
	# Don't play show animation if it is on screen already
	var popup_ref = get_tree().get_root().get_node_or_null("LevelPopup")
	if popup_ref != null:
		if !popup_ref.is_on_side:
			animation_player.play("show_main")
		else:
			popup_ref.is_on_side = false
	
	character_life = 5
	in_game = false
	menu_state = STATE.MAIN
	
	if _game_scene != null:
		LoadingManager.unload_current_scene("/root/Game")
	
	_game_scene = preload("res://scenes/2D/game.tscn").instantiate()


func _reset_game_3d() -> void:
	# Return background visibility
	manage_background(true)
	
	# Don't play show animation if it is on screen already
	var popup_ref = get_tree().get_root().get_node_or_null("LevelPopup")
	if popup_ref != null:
		if !popup_ref.is_on_side:
			animation_player.play("show_main")
		else:
			popup_ref.is_on_side = false
	
	character_life = 5
	in_game_3d = false
	menu_state = STATE.MAIN
	
	if _game_scene_3d != null:
		LoadingManager.unload_current_scene("/root/Game3D")
	
	_game_scene_3d = preload("res://scenes/3D/game_3d.tscn").instantiate()


func manage_game_timer(state: STATE) -> void:
	if state == STATE.GAME and not is_popup_displaying:
		is_timer_running = true
	else:
		is_timer_running = false


func _manage_popup(state: STATE) -> void:
	var popup_ref = get_node_or_null("/root/LevelPopup")
	if popup_ref != null and is_popup_displaying:
		if state == Menu.STATE.MAIN and !popup_ref.is_on_side:
			if popup_ref.popup_state == level_popup.POPUP.FINISH:
				popup_ref.animation_player.play("side_finish")
			elif popup_ref.popup_state == level_popup.POPUP.DEATH:
				popup_ref.animation_player.play("side_death")
			
			popup_ref.is_on_side = true
		elif state == Menu.STATE.GAME and popup_ref.is_on_side:
			if popup_ref.popup_state == level_popup.POPUP.FINISH:
				popup_ref.animation_player.play("return_finish")
			elif popup_ref.popup_state == level_popup.POPUP.DEATH:
				popup_ref.animation_player.play("return_death")
			
			popup_ref.is_on_side = false


func _manage_game_overlay() -> void:
	if in_game or in_game_3d:
		await Signal(LoadingManager, "load_finish")
		game_overlay.show()
	else:
		game_overlay.hide()


func _check_health() -> void:
	if character_life <= 0:
		var player
		if in_game:
			player = get_node("/root/Game/Player")
		if in_game_3d:
			player = get_node("/root/Game3D/Player3D")
		
		menu_state = STATE.OVERLAY
		player.hide_on_death()
		_popup_scene.popup_state = level_popup.POPUP.DEATH
		_popup_scene.animation_player.play("show_death")
		is_popup_displaying = true


func _manage_touch_controller():
	var platform = OS.get_name()
	if platform != "iOS":
		return
	
	var virtual_controller = _VirtualControllerHelper.get_virtual_controller()
	if virtual_controller:
		if menu_state == STATE.GAME or menu_state == STATE.GAME3D or menu_state == STATE.GAMEMIXED: 
			virtual_controller.enable()
		else:
			virtual_controller.disable()


func _config_load():
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://settings.cfg")
	
	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	
	# Restore configuration
	resolution = config.get_value("Game", "window_size", Vector2i(1280, 720))
	fullscreen = config.get_value("Game", "fullscreen", false)
	player_color = config.get_value("Game", "player_color", Color.WHITE)
	
	shadow_enabled = config.get_value("Graphics", "shadow_enabled", true)
	sdfgi_enabled = config.get_value("Graphics", "sdfgi_enabled", true)
	sdfgi_full_res = config.get_value("Graphics", "sdfgi_full_res", false)
	
	# Restore config into button states
	settings_node._on_fullscreen_toggled(fullscreen)
	settings_node._on_shadow_toggled(shadow_enabled)
	settings_node._on_sdfgi_toggled(sdfgi_enabled)
	settings_node._on_sdfgi_full_toggled(sdfgi_full_res)
	
	settings_node._graphics_check()

func _config_save():
	# Create new ConfigFile object.
	var config = ConfigFile.new()
	
	# Store Game Settings
	config.set_value("Game", "window_size", resolution)
	config.set_value("Game", "fullscreen", fullscreen)
	config.set_value("Game", "player_color", player_color)
	
	# Store Graphics Settings
	config.set_value("Graphics", "shadow_enabled", shadow_enabled)
	config.set_value("Graphics", "sdfgi_enabled", sdfgi_enabled)
	config.set_value("Graphics", "sdfgi_full_res", sdfgi_full_res)
	
	# Save it to a file (overwrite if already exists).
	config.save("user://settings.cfg")
