extends Control

@export var timer_label = RichTextLabel
@onready var game_manager = get_node("/root/Game/GameManager")
@onready var menu = get_node("/root/Menu")

func output_timer(seconds_elapsed: float) -> void:
	# Total integer seconds
	var total_whole_seconds = int(seconds_elapsed)
	
	# Minutes, seconds
	var mins = total_whole_seconds / 60
	var secs = total_whole_seconds % 60
	
	# Hundredths (the two decimal points)
	var fractional = seconds_elapsed - float(total_whole_seconds)
	var hundredths = int(round(fractional * 100.0))
	
	# Format each component as two digits
	var mins_str = "%02d" % mins
	var secs_str = "%02d" % secs
	var hundredths_str = "%02d" % hundredths
	
	# Display as MM:SS:HH
	timer_label.text = mins_str + ":" + secs_str + ":" + hundredths_str

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_finish_pressed() -> void:
	game_manager.reset_game()
	menu.reset_game()
