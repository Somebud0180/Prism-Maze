extends NinePatchRect

@onready var menu = get_node("/root/Menu")
@export var resolution_picker: OptionButton
@export var fullscreen_toggle: CheckButton
@export var shadow_toggle: CheckButton
@export var sdfgi_toggle: CheckButton
@export var sdfgi_full_toggle: CheckButton

var supported_resolutions = ["2560x1600", "2560x1440", "2560x1080", "2048x1536", "1920x1200", "1920x1080", "1680x1050", "1600x900", "1440x900", "1366x768", "1280x1024", "1280x720", "1024x768", "800x600", "640x480", "640x360"]
var resolution_icon = load("res://resources/Menu/Resize.png")
var native_icon = load("res://resources/Menu/Native.png")

func _ready() -> void:
	resolution_picker.connect("item_selected", _on_resolution_item_selected)
	fullscreen_toggle.connect("toggled", _on_fullscreen_toggled)
	shadow_toggle.connect("toggled", _on_shadow_toggled)
	sdfgi_toggle.connect("toggled", _on_sdfgi_toggled)
	sdfgi_full_toggle.connect("toggled", _on_sdfgi_full_toggled)


# Game Settings
func _manage_resolution_picker() -> void:
	var platform = OS.get_name()
	if platform == "Web" or platform == "iOS":
		resolution_picker.hide()
		fullscreen_toggle.hide()
		return
	
	# Check for window state if fullscreen
	if menu.window_state == menu.WINDOW_STATE.FULLSCREEN:
		resolution_picker.disabled = true
	else:
		resolution_picker.disabled = false


func _on_resolution_item_selected(index: int) -> void:
	var selected_resolution = resolution_picker.get_item_text(index)
	var parts = selected_resolution.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		menu.resolution = Vector2i(width, height)
		set_resolution()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		fullscreen_toggle.button_pressed = true
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		menu.window_state = menu.WINDOW_STATE.FULLSCREEN
		menu.fullscreen = true
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution.x) + "x" + str(current_resolution.y)
		for i in range(supported_resolutions.size()):
			if supported_resolutions[i] == string_current:
				resolution_picker.selected = i
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		set_resolution()
		menu.window_state = menu.WINDOW_STATE.WINDOWED
		menu.fullscreen = false
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution.x) + "x" + str(current_resolution.y)
		var rect = DisplayServer.get_display_safe_area()
		var fw_w = int(rect.size.x)
		var fw_h = int(rect.size.y)
		for i in range(supported_resolutions.size()):
			if supported_resolutions[i] == string_current:
				resolution_picker.selected = i


func set_resolution() -> void:
	# Set window mode to window
	# Workaround for macOS not allowing resizing from native resolution
	DisplayServer.window_set_size(menu.resolution)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Reposition the current menu
	match menu.menu_state:
		menu.STATE.SETTINGS:
			menu.animation_player.play("RESET_settings")
		menu.STATE.CONTROLS:
			menu.animation_player.play("RESET_controls")
		menu.STATE.GAME:
			menu.animation_player.play("RESET_game")
		menu.STATE.MAIN:
			menu.animation_player.play("RESET_main")
	
	# Get window placement
	var rect = DisplayServer.screen_get_usable_rect()
	var win_pos = DisplayServer.window_get_position()
	var x_overhang = (win_pos.x + menu.resolution.x) - (rect.position.x + rect.size.x)
	var y_overhang = (win_pos.y + menu.resolution.y) - (rect.position.y + rect.size.y)
	
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
	
	for i in range(supported_resolutions.size()):
		var resolution_name: String = supported_resolutions[i]
		
		resolution_picker.add_icon_item(resolution_icon, resolution_name, i)
		
		# Set as selected if same as current resolution
		if resolution_name == string_current:
			resolution_picker.selected = i
	
	_update_resolution_icons()


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


func _update_resolution_icons() -> void:
	var native_resolution = DisplayServer.screen_get_size()
	var string_native = str(native_resolution.x) + "x" + str(native_resolution.y)
	
	var native_windowed = DisplayServer.get_display_safe_area()
	var string_windowed = str(native_windowed.size.x) + "x" + str(native_windowed.size.y)
	
	for i in range(supported_resolutions.size()):
		var resolution_name = supported_resolutions[i]
		# Default icon is the regular resolution icon
		var icon = resolution_icon
		
		# If fullscreen mode AND matches the screen's native resolution, use native_icon
		if resolution_name == string_native:
			icon = native_icon
		# If windowed mode AND matches the "usable" windowed resolution, use native_icon
		elif resolution_name == string_windowed:
			icon = native_icon
		
		# Update the existing resolution picker item’s icon
		resolution_picker.set_item_icon(i, icon)


func _compare_resolutions(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y > b.y
	return a.x > b.x


func _update_player_color() -> void:
	var player_ref = get_tree().get_first_node_in_group("Player")
	if player_ref:
		player_ref.change_color()


# 3D Settings
func _graphics_check() -> void:
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		sdfgi_toggle.disabled = true
		sdfgi_full_toggle.disabled = true
		menu.sdfgi_enabled = false


func _set_resize():
	get_viewport().get_window().unresizable = !menu.resizable


func _on_shadow_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	shadow_toggle.button_pressed = toggled_on
	%Shadow_Quality.editable = toggled_on
	
	menu.shadow_enabled = toggled_on


func _on_sdfgi_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	sdfgi_toggle.button_pressed = toggled_on
	
	menu.sdfgi_enabled = toggled_on
	
	sdfgi_full_toggle.disabled = !menu.sdfgi_enabled


func _on_sdfgi_full_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	sdfgi_full_toggle.button_pressed = toggled_on
	
	menu.sdfgi_full_res = toggled_on
