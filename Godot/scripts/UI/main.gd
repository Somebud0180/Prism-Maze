extends NinePatchRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var platform = OS.get_name()
	
	if !Steamworks.is_steam_enabled():
		$VBoxContainer/Play3D.focus_neighbor_top = "../Controls"
		$VBoxContainer/Play3D.focus_neighbor_right = ""
		$VBoxContainer/Play3D.focus_previous = ""
	
	if platform == "Web" or platform == "iOS":
		$VBoxContainer/ButtonSpacer4.visible = false
		$VBoxContainer/Quit.visible = false
		$VBoxContainer/Controls.focus_neighbor_bottom = "../Play3D"
