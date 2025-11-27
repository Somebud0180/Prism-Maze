extends CheckButton

@onready var menu = get_node("/root/Menu")
@onready var settings = %Settings
@onready var resolution_picker = %Resolution

var stored_text = ""

func _ready() -> void:
	stored_text = text

func _update_button() -> void:
	button_pressed = menu.fullscreen
	
	if menu.text_enabled:
		text = stored_text
		icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		text = ""
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		menu.window_state = menu.WINDOW_STATE.FULLSCREEN
		menu.fullscreen = true
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution.x) + "x" + str(current_resolution.y)
		for i in range(settings.supported_resolutions.size()):
			if settings.supported_resolutions[i] == string_current:
				resolution_picker.selected = i
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		settings.set_resolution()
		menu.window_state = menu.WINDOW_STATE.WINDOWED
		menu.fullscreen = false
		
		var current_resolution = DisplayServer.window_get_size()
		var string_current = str(current_resolution.x) + "x" + str(current_resolution.y)
		for i in range(settings.supported_resolutions.size()):
			if settings.supported_resolutions[i] == string_current:
				resolution_picker.selected = i
