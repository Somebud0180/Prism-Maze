extends Control
class_name level_popup

@export var timer_label: RichTextLabel
@export var level_label: RichTextLabel
@export var animation_player: AnimationPlayer

enum POPUP { NONE, FINISH, DEATH }
@export var popup_state = POPUP.NONE

var is_on_side: bool = false
var is_playing: bool = false:
	get():
		return animation_player.is_playing()

func _ready() -> void:
	animation_player.play("RESET")

func output_timer(seconds_elapsed: float, level_times: Array) -> void:
	# Cast to int for the "whole seconds" part
	var total_whole_seconds = int(seconds_elapsed)
	# Fraction is what's left after subtracting those whole seconds
	var total_fraction = seconds_elapsed - float(total_whole_seconds)

	var total_mins = int(total_whole_seconds / 60)
	var total_secs = int(total_whole_seconds % 60)
	var total_hundredths = int(round(total_fraction * 100.0))
	
	# Format each component as two digits
	var total_mins_str = "%02d" % total_mins
	var total_secs_str = "%02d" % total_secs
	var total_hundredths_str = "%02d" % total_hundredths
	
	# Display as MM:SS:HH
	timer_label.text = total_mins_str + ":" + total_secs_str + "." + total_hundredths_str
	
	# Compute average of all times in level_times
	var total_avg_time = 0.0
	for t in level_times:
		total_avg_time += t
	
	var avg_time = 0.0
	if level_times.size() > 0:
		avg_time = total_avg_time / float(level_times.size())
	
	# Minutes, seconds, hundredths
	var avg_whole_seconds = int(avg_time)
	var avg_fraction = avg_time - float(avg_whole_seconds)

	var avg_mins = int(avg_whole_seconds / 60)
	var avg_secs = int(int(avg_whole_seconds) % 60)
	var avg_hundredths = int(round(avg_fraction * 100.0))
	
	# Format each component as two digits
	var avg_mins_str = "%02d" % avg_mins
	var avg_secs_str = "%02d" % avg_secs
	var avg_hundredths_str = "%02d" % avg_hundredths
	
	level_label.text = avg_mins_str + ":" + avg_secs_str + "." + avg_hundredths_str


func _on_finish_pressed() -> void:
	var menu = get_node("/root/Menu")
	var game_manager = get_node("/root/Game/GameManager")
	
	if is_on_side:
		animation_player.play("hide_finish_side")
	else:
		animation_player.play("hide_finish")
	
	await animation_player.animation_finished
	menu.is_popup_displaying = false
	game_manager.reset_game()
	menu._reset_game()


func _on_restart_pressed() -> void:
	var menu = get_node("/root/Menu")
	
	if is_on_side:
		animation_player.play("hide_death_side")
	else:
		animation_player.play("hide_death") 
	
	await animation_player.animation_finished
	menu.is_popup_displaying = false
	
	if menu.in_game:
		var game_manager = get_node("/root/Game/GameManager")
		game_manager.reset_game()
		menu._reset_game()
	elif menu.in_game_3d:
		var level_layer_3d = get_node("/root/Game3D/LevelLayer3D")
		level_layer_3d.reset_game_3d()
		menu._reset_game_3d()
