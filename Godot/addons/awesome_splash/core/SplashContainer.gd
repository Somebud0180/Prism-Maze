## You can download demo splash screen here
## https://github.com/duongvituan/godot-awesome-splash
## Import a demo AweSplashScreen you like to your project.
## Drag and drop it to SplashContainer.
@icon("res://addons/awesome_splash/assets/icon/splash_container_icon.png")
@tool
extends "res://addons/awesome_splash/core/BaseSplashContainer.gd"
class_name SplashContainer


func _ready():
	super._ready()
	_config_load()
	if not Engine.is_editor_hint():
		finished_all.connect(self._on_finished_all_splash_screen)
		start_play_list_screen()


# Working only for screen type AweSplashScreen and you much set
# type skip = SKIP_ONE_SCREEN_WHEN_CLICKED or SKIP_ALL_SCREEN_WHEN_CLICKED
# Todo: update condition skip splash screen: when you click, when you press key...
func _skip_awe_splash_by_event(event) -> bool:
	return event.is_pressed() \
		and ((event is InputEventMouseButton and event.button_index == 1) \
		or (event is InputEventScreenTouch))


# Todo: move to other screen here:
func _on_finished_all_splash_screen():
	if move_to_scene != null:
		get_tree().change_scene_to_packed(move_to_scene)
	else:
		push_error("Please set move_to_scene in SplashContainer")


func _config_load():
	var config = ConfigFile.new()
	
	# Load data from a file.
	var err = config.load("user://settings.cfg")
	
	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	# Restore window configuration
	if config.get_value("Game", "fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	DisplayServer.window_set_position(config.get_value("Game", "window_position", Vector2i(0, 0)))
	DisplayServer.window_set_size(config.get_value("Game", "window_size", Vector2i(1280, 720)))
