extends NinePatchRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var platform = OS.get_name()
	if platform == "Web" or platform == "iOS":
		$VBoxContainer/ButtonSpacer4.visible = false
		$VBoxContainer/Quit.visible = false
		$VBoxContainer/Play3D.focus_neighbor_top = "../Controls"
		$VBoxContainer/Controls.focus_neighbor_bottom = "../Play3D"
