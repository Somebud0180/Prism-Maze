extends CanvasLayer

@warning_ignore("unused_signal")
signal loading_screen_has_full_coverage

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _start_outro_animation() -> void:
	animation_player.play("end_load")
	await Signal(animation_player, "animation_finished")
	self.queue_free()
