extends Area3D

@onready var menu = get_node("/root/Menu")
var viewport
var level
var level_layer
var Player3D
var player_3d

var is_in_area = false

func _ready() -> void:
	viewport = get_node("../../SubViewport")
	level = get_parent().get_parent()
	Player3D = get_tree().get_nodes_in_group("Player3D")
	if Player3D.size() > 0:
		player_3d = Player3D[0]


func _on_body_entered(_body: Node3D) -> void:
	is_in_area = true
	player_3d.subviewport = viewport
	
	# Display guidee
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = LevelLayer3D.TUTORIAL_STATE.INTERACT
	player_3d.player_controlled = get_node("../../SubViewport/Game/Player")


func _on_body_exited(_body: Node3D) -> void:
	is_in_area = false
	player_3d.subviewport = null
	
	# Reset mode
	menu.menu_state = Menu.STATE.GAME3D
	player_3d.is_in_subviewport = false
	player_3d._handle_input_mode_switch()
	
	# Reset guide
	level_layer = get_node("/root/Game3D/LevelLayer3D")
	level_layer.tutorial_state = LevelLayer3D.TUTORIAL_STATE.RESET
	player_3d.player_controlled = null


func _physics_process(_delta: float) -> void:
	if is_in_area:
		if Input.is_action_just_pressed("interact"):
			if menu.menu_state == Menu.STATE.GAME3D:
				menu.menu_state = Menu.STATE.GAMEMIXED
				player_3d.is_in_subviewport = true
				player_3d._handle_input_mode_switch()
			elif menu.menu_state == Menu.STATE.GAMEMIXED:
				menu.menu_state = Menu.STATE.GAME3D
				player_3d.is_in_subviewport = false
				player_3d._handle_input_mode_switch()


func _input(event: InputEvent) -> void:
	if menu.menu_state != Menu.STATE.GAMEMIXED and !is_in_area:
		return
	
	elif not event.is_action("interact") and level.viewport and player_3d.is_in_subviewport:
		level.viewport.push_input(event)
		# Prevent input from propagating further
		level.get_viewport().set_input_as_handled()
