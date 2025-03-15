extends Control
class_name Menu

@export var game_overlay: CanvasLayer
@export var main: NinePatchRect
@export var settings: NinePatchRect
@export var animation_player: AnimationPlayer
@export var resolution_picker: OptionButton
@export var health_bar: ProgressBar

var _game_scene = preload("res://scenes/2D/game.tscn").instantiate()
var _game_scene_3d = preload("res://scenes/3D/game_3d.tscn").instantiate()
var resolution_icon = load("res://resources/Menu/Resize.png")
var native_icon = load("res://resources/Menu/Native.png")

var popup_scene

var game_scene_path = "res://scenes/2D/game.tscn"
var game_scene_3d_path = "res://scenes/3D/game_3d.tscn"

enum WINDOW_STATE { FULLSCREEN, WINDOWED }
var window_state = WINDOW_STATE.WINDOWED:
	set(value):
		window_state = value
		_manage_resolution_picker()

enum STATE { MAIN, SETTINGS, CONTROLS, OVERLAY, GAME, GAME3D, GAMEMIXED }
var menu_state = STATE.MAIN:
	set(value):
		manage_game_timer(value)
		menu_state = value

var in_game = false:
	set(value):
		in_game = value
		_manage_game_overlay()
		_manage_color_buttons()

var in_game_3d = false:
	set(value):
		in_game_3d = value
		_manage_game_overlay()

var is_loading = false
var last_state = STATE.MAIN

var is_popup_displaying = false
var resolution = Vector2i(1280, 720)

var time_elapsed: float = 0.0
var is_timer_running: bool = false

@export var character_life: int = 5:
	set(value):
		character_life = value
		health_bar.value = value
		_check_health()

var supported_resolutions = ["2560x1600", "2560x1440", "2560x1080", "2048x1536", "1920x1200", "1920x1080", "1680x1050", "1600x900", "1440x900", "1366x768", "1280x1024", "1280x720", "1024x768", "800x600", "640x480", "640x360"]

func _ready() -> void:
	$MenuLayer.show()
	$GameOverlay.hide()
	animation_player.play("RESET_main")
	
	_add_full_window_resolution()
	_add_resolutions()
	_manage_resolution_picker()
	_manage_color_buttons()
	
	popup_scene = get_node("/root/LevelPopup")
	
	$MenuLayer/Main/VBoxContainer/Play.grab_focus()


func _input(event):
	if event.is_action_pressed("ui_cancel") and not animation_player.is_playing() and not popup_scene.is_playing and not is_loading:
		match menu_state:
			STATE.SETTINGS:
				menu_state = STATE.MAIN
				_hide_and_show("settings", "main")
				await animation_player.animation_finished
				$MenuLayer/Main/VBoxContainer/Play.grab_focus()
			STATE.CONTROLS:
				menu_state = STATE.MAIN
				_hide_and_show("controls", "main")
				await animation_player.animation_finished
				$MenuLayer/Main/VBoxContainer/Play.grab_focus()
			STATE.GAME, STATE.GAME3D, STATE.GAMEMIXED, STATE.OVERLAY:
				last_state = menu_state
				menu_state = STATE.MAIN
				animation_player.play("show_main")
				_manage_popup(menu_state)
				await animation_player.animation_finished
				$MenuLayer/Main/VBoxContainer/Play.grab_focus()
			STATE.MAIN:
				# Recover menu state
				menu_state = last_state
				
				if in_game:
					animation_player.play("hide_main")
					_manage_popup(menu_state)
				elif in_game_3d:
					animation_player.play("hide_main")


func manage_background(is_visible: bool):
	# Control the parallax background visibility
	$Background.visible = is_visible


func _hide_and_show(first: String, second: String):
	animation_player.play("hide_" + first)
	await animation_player.animation_finished
	animation_player.play("show_" + second)


func _on_play_pressed() -> void:
	# Check if already in-game in another dimension
	if in_game_3d:
		_reset_game_3d()
	
	menu_state = STATE.GAME
	animation_player.play("hide_main")
	await animation_player.animation_finished
	if !in_game:
		LoadingManager.load_scene(game_scene_path)
		in_game = true


func _on_play_3d_pressed() -> void:
	# Check if already in-game in another dimension
	if in_game:
		_reset_game()
	
	menu_state = STATE.GAME3D
	animation_player.play("hide_main")
	await animation_player.animation_finished
	
	if !in_game_3d:
		LoadingManager.load_scene(game_scene_3d_path)
		in_game_3d = true


func _on_settings_pressed() -> void:
	menu_state = STATE.SETTINGS
	_hide_and_show("main", "settings")
	$MenuLayer/Settings/VBoxContainer/Resolution.grab_focus()


func _on_controls_pressed() -> void:
	menu_state = STATE.CONTROLS
	_hide_and_show("main", "controls")
	$"MenuLayer/Controls/Exit Controls".grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_exit_settings_pressed() -> void:
	menu_state = STATE.MAIN
	_hide_and_show("settings", "main")
	$MenuLayer/Main/VBoxContainer/Play.grab_focus()


func _on_exit_controls_pressed() -> void:
	menu_state = STATE.MAIN
	_hide_and_show("controls", "main")
	$MenuLayer/Main/VBoxContainer/Play.grab_focus()


func _manage_resolution_picker() -> void:
	var platform = OS.get_name()
	if platform == "Web" or platform == "iOS":
		resolution_picker.hide()
		return
	
	# Check for window state if fullscreen
	if window_state == WINDOW_STATE.FULLSCREEN:
		resolution_picker.disabled = true
	else:
		resolution_picker.disabled = false


func _on_resolution_item_selected(index: int) -> void:
	var selected_resolution = resolution_picker.get_item_text(index)
	var parts = selected_resolution.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		resolution = Vector2i(width, height)
		set_resolution()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		window_state = WINDOW_STATE.FULLSCREEN
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution[0]) + "x" + str(current_resolution[1])
		for i in range(supported_resolutions.size()):
			# Set as selected if same as current resolution
			if supported_resolutions[i] == string_current:
				resolution_picker.selected = i
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		set_resolution()
		window_state = WINDOW_STATE.WINDOWED
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution[0]) + "x" + str(current_resolution[1])
		for i in range(supported_resolutions.size()):
			# Set as selected if same as current resolution
			if supported_resolutions[i] == string_current:
				resolution_picker.selected = i


func set_resolution() -> void:
	# Doesnt seem to be an issue anymore
	#
	# Set window mode to window
	# Workaround for macOS not allowing resizing from native resolution
	# DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_size(resolution)
	
	# Reposition the current menu
	match menu_state:
		STATE.SETTINGS:
			animation_player.play("RESET_settings")
		STATE.CONTROLS:
			animation_player.play("RESET_controls")
		STATE.GAME:
			animation_player.play("RESET_game")
		STATE.MAIN:
			animation_player.play("RESET_main")

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


func _add_resolutions():
	var current_resolution: Vector2i = DisplayServer.window_get_size()
	var string_current: String = str(current_resolution[0]) + "x" + str(current_resolution[1])
	
	var native_resolution: Vector2i = DisplayServer.screen_get_size()
	var string_native: String = str(native_resolution[0]) + "x" + str(native_resolution[1])
	
	var native_windowed: Rect2i = DisplayServer.screen_get_usable_rect()
	var string_windowed: String = str(native_windowed.size.x) + "x" + str(native_windowed.size.y)
	
	for i in range(supported_resolutions.size()):
		var resolution_name: String = supported_resolutions[i]
		var icon = ""
		
		# Add a native icon to the native resoluton
		if (resolution_name == string_native and DisplayServer.window_get_mode() == 3) or (resolution_name == string_windowed and DisplayServer.window_get_mode() == 0):
			icon = native_icon
		else:
			icon = resolution_icon
		
		resolution_picker.add_icon_item(icon, resolution_name, i)
		
		# Set as selected if same as current resolution
		if resolution_name == string_current:
			resolution_picker.selected = i


func _add_full_window_resolution():
	var rect = DisplayServer.screen_get_usable_rect()
	var fw_w = int(rect.size.x)
	var fw_h = int(rect.size.y)
	
	# Convert each supported resolution to a (width, height) pair
	var resolution_pairs = []
	for res_str in supported_resolutions:
		var parts = res_str.split("x")
		var w = int(parts[0])
		var h = int(parts[1])
		resolution_pairs.append(Vector2i(w, h))
	
	# Insert your full-window resolution
	resolution_pairs.append(Vector2i(fw_w, fw_h))
	
	# Sort by width, then height
	resolution_pairs.sort_custom(_compare_resolutions)
	
	# Rebuild the string list
	supported_resolutions.clear()
	for pair in resolution_pairs:
		supported_resolutions.append(str(pair.x) + "x" + str(pair.y))


func _compare_resolutions(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y > b.y
	return a.x > b.x


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
	_manage_color_buttons()


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


func _manage_color_buttons() -> void:
	# Reference to the GridContainer holding all color buttons
	var grid = $MenuLayer/Settings/VBoxContainer/Panel/VBoxContainer/HBoxContainer/GridContainer
	
	# Loop through all children of the GridContainer (all color buttons)
	for button in grid.get_children():
		if button is Button:
			button.disabled = !in_game


# Player Color Settings
func _on_white_pressed() -> void:
	var player_ref = _game_scene.get_node("/root/Game/Player")
	player_ref.change_color(Color.WHITE)


func _on_red_pressed() -> void:
	var player_ref = _game_scene.get_node("/root/Game/Player")
	player_ref.change_color(Color.RED)


func _on_green_pressed() -> void:
	var player_ref = _game_scene.get_node("/root/Game/Player")
	player_ref.change_color(Color.WEB_GREEN)


func _on_blue_pressed() -> void:
	var player_ref = _game_scene.get_node("/root/Game/Player")
	player_ref.change_color(Color.DARK_BLUE)


func _on_yellow_pressed() -> void:
	var player_ref = _game_scene.get_node("/root/Game/Player")
	player_ref.change_color(Color.YELLOW)


func _check_health() -> void:
	if character_life <= 0:
		var player
		if in_game:
			player = get_node("/root/Game/Player")
		elif in_game_3d:
			player = get_node("/root/Game3D/Player3D")
		
		menu_state = STATE.OVERLAY
		player.hide_on_death()
		popup_scene.popup_state = level_popup.POPUP.DEATH
		popup_scene.animation_player.play("show_death")
		is_popup_displaying = true

func _process(delta: float) -> void:
	if is_timer_running:
		time_elapsed += delta
