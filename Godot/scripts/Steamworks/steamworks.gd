extends Node

var this_platform: String = "steam"
var steam_api: Object = null

var app_id: int
var steam_id: int
var steam_avatar

func _init() -> void:
	# Set your game's Steam app ID here
	OS.set_environment("SteamAppId", str(3675570))
	OS.set_environment("SteamGameId", str(3675570))


func _ready() -> void:
	initialize_steam()
	
	if is_steam_enabled():
		print("Running Steamworks Functions")
		app_id = int(OS.get_environment("SteamAppId"))
		steam_id = steam_api.getSteamID()


func _process(_delta: float) -> void:
	if is_steam_enabled():
		steam_api.run_callbacks()


# Initialize Steam
func initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		this_platform = "steam"
		steam_api = Engine.get_singleton("Steam")
		
		var initialized: Dictionary = steam_api.steamInitEx(false)
		
		print("[STEAM] Did Steam initialize?: %s" % initialized)
		
		# In case it does fail, let's find out why and null the steam_api object
		if initialized['status'] > 0:
			print("Failed to initialize Steam, disabling all Steamworks functionality: %s" % initialized)
			steam_api = null
	else:
		this_platform = "standard"


func is_steam_enabled() -> bool:
	if this_platform == "steam" and steam_api != null:
		return true
	return false
