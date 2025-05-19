extends Node

var menu

var achievements = {
	"EARLY_DEATH": false,
	"FIRST_RESET": false,
	"FINISH_3D": false,
	"FINISH_2D": false
}

func set_achievement(this_achievement: String) -> void:
	if menu.cheat_used:
		print("Cheat detected, achievement not set: %s" % this_achievement)
		return
	
	if not achievements.has(this_achievement):
		print("This achievement does not exist locally: %s" % this_achievement)
		return
	
	achievements[this_achievement] = true
	
	if not Steamworks.steam_api.setAchievement(this_achievement):
		print("Failed to set achievement: %s" % this_achievement)
		return
	
	print("Set acheivement: %s" % this_achievement)
	
	# Pass the value to Steam then fire it
	if not Steamworks.steam_api.storeStats():
		print("Failed to store data on Steam, should be stored locally")
		return
	
	print("Data successfully sent to Steam")


func connect_achievements() -> void:
	menu = get_node("/root/Menu")
	
	if Steamworks.is_steam_enabled():
		Steamworks.steam_api.current_stats_received.connect(_on_steam_stats_ready)


func _on_steam_stats_ready(this_game: int, this_result: int, this_user: int) -> void:
	print("Received local player stats and achievements from Steam: %s / %s /%s" % [this_user, this_result, this_game])
	
	# These will check against the data we pulled in the initialization tutorial
	if this_user != Steamworks.steam_id:
		print("These stats belong to %s instead, aborting Steam stat and achievement loading" % this_user)
		return
	
	if this_game != Steamworks.app_id:
		print("Stats are for a different app ID: %s" % this_game)
		return
	
	if this_result != Steamworks.steam_api.RESULT_OK:
		print("Failed to get stats and achievements from Steam: %s" % this_result)
		return
	
	load_steam_achievements()


# Process achievements
func load_steam_achievements() -> void:
	for this_achievement in achievements.keys():
		var steam_achievement: Dictionary = Steamworks.steam_api.getAchievement(this_achievement)
		
		# The set_achievement function is below in the Setting Achievements section
		if not this_achievement['ret']:
			print("Steam does not have this achievement, defaulting to local value: achieve%s" % this_achievement)
			break
			
		if achievements[this_achievement] == steam_achievement['achieved']:
			print("Steam achievements match local file, skipping: %s" % this_achievement)
			break
			
		set_achievement(this_achievement)

	print("Steam achievements loaded")
