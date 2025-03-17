extends TabContainer

var icon_2d = load("res://resources/Menu/Headers/2D_Tab.png")
var icon_3d = load("res://resources/Menu/Headers/3D_Tab.png")

func _ready() -> void:
	set_tab_icon(0, icon_2d)
	set_tab_title(0, "")
	set_tab_icon(1, icon_3d)
	set_tab_title(1, "")
