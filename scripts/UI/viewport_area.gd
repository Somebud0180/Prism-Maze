extends Area3D

@onready var menu = get_node("/root/Menu")
var level
var level_layer
var Player3D
var player_3d

var is_in_area = false

func _ready() -> void:
	level = get_parent().get_parent()
	Player3D = get_tree().get_nodes_in_group("Player3D")
	if Player3D.size() > 0:
		player_3d = Player3D[0]


func _on_body_entered(_body: Node3D) -> void:
	is_in_area = true
	
	# Display guidee
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = LevelLayer3D.TUTORIAL_STATE.INTERACT


func _on_body_exited(_body: Node3D) -> void:
	is_in_area = false
	
	# Reset guide
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = LevelLayer3D.TUTORIAL_STATE.RESET


func _unhandled_input(event: InputEvent) -> void:
	if menu.menu_state != Menu.STATE.GAMEMIXED and !is_in_area:
		return
	
	if event.is_action_pressed("interact"):
		print("Pressing")
		if menu.menu_state == Menu.STATE.GAME3D:
			menu.menu_state = Menu.STATE.GAMEMIXED
			player_3d.is_in_subviewport = true
		elif menu.menu_state == Menu.STATE.GAMEMIXED:
			menu.menu_state = Menu.STATE.GAME3D
			player_3d.is_in_subviewport = false
		
		player_3d._handle_input_mode_switch()
	
	if level.viewport and player_3d.is_in_subviewport:
		# Propagate all inputs except "interact" to the subviewport
		if not event.is_action("interact"):
			level.viewport.push_input(event)
			# Prevent input from propagating further
			level.get_viewport().set_input_as_handled()
