extends Button

@onready var menu = get_node("/root/Menu")
@export var color: Color

func _ready():
	toggled.connect(_on_toggled)
	get_child(0).get_child(0).self_modulate = color


func _process(_delta: float) -> void:
	if menu.player_color == color:
			button_pressed = true


func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		menu.player_color = color
	else:
		menu.player_color = Color.WHITE
		if color == Color.WHITE:
			toggled_on = true
