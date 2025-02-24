extends Control

@export var main: NinePatchRect
@export var settings: NinePatchRect

@export var animation_player: AnimationPlayer
@export var resolution_picker: OptionButton

var simultaneous_scene = preload("res://scenes/game.tscn").instantiate()
var resolution_icon = load("res://resources/Menu/Resize.png")
var native_icon = load("res://resources/Menu/Native.png")

enum STATE { MAIN, SETTINGS, CONTROLS, GAME }
var menu_state = STATE.MAIN
var in_game = false
var resolution = Vector2i(1280, 720)

var supported_resolutions = ["2560x1600", "2560x1440", "2560x1080", "2048x1536", "1920x1200", "1920x1080", "1680x1050", "1600x900", "1440x900", "1366x768", "1280x1024", "1280x720", "1024x768", "800x600", "640x480", "640x360"]

func _ready() -> void:
	add_full_window_resolution()
	add_resolutions()

func add_resolutions():
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


func add_full_window_resolution():
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


func reset_game() -> void:
	in_game = false
	menu_state = STATE.MAIN
	animation_player.play("show_main")
	
	if simultaneous_scene.get_parent() != null:
		simultaneous_scene.get_parent().remove_child(simultaneous_scene)
	
	simultaneous_scene = preload("res://scenes/game.tscn").instantiate()

func _compare_resolutions(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y > b.y
	return a.x > b.x


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
		resolution_picker.disabled = true 
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution[0]) + "x" + str(current_resolution[1])
		for i in range(supported_resolutions.size()):
			# Set as selected if same as current resolution
			if supported_resolutions[i] == string_current:
				resolution_picker.selected = i
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		set_resolution()
		resolution_picker.disabled = false
		
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
