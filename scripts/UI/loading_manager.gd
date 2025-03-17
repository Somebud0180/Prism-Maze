extends Node

signal load_finish

var _loading_scene_path: String = "res://scenes/UI/loading_screen.tscn"
var _loading_scene = load(_loading_scene_path)
var _loaded_resource: PackedScene
var _scene_path: String
var _progress: Array = []

var use_sub_threads: bool = true


func load_scene(scene_path: String) -> void:
	var menu = get_node("/root/Menu")
	menu.is_loading = true
	
	_scene_path = scene_path
	
	var new_loading_scene = _loading_scene.instantiate()
	get_tree().get_root().add_child(new_loading_scene)
	
	self.load_finish.connect(new_loading_scene._start_outro_animation)
	
	await Signal(new_loading_scene, "loading_screen_has_full_coverage")
	
	menu.manage_background(false)
	start_load()


func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(_scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)


func unload_current_scene(node: String) -> void:
	# Find the Game node in the scene tree
	var remove_node = get_tree().get_root().get_node_or_null(node)
	
	if remove_node != null:
		# Queue it for deletion
		remove_node.queue_free()


func _process(_delta) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(_scene_path, _progress)
	match load_status:
		0, 2: #? THREAD_:PAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			return
		3: #? THREAD_LOAD_LOADED
			_loaded_resource = ResourceLoader.load_threaded_get(_scene_path)
			
			# Change to the loaded scene
			get_tree().get_root().add_child(_loaded_resource.instantiate())
			
			# Check if this scene has a GameManager node
			var game_manager = get_node_or_null("/root/Game/GameManager")
			if game_manager != null:
				# Wait for the game manager to finish loading
				await game_manager.finished_loading
			
			# Now emit the signal to hide the loading screen
			var menu = get_node("/root/Menu")
			menu.is_loading = false
			emit_signal("load_finish")
