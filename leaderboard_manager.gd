# leaderboard_manager.gd
extends Node

signal leaderboard_updated

const SAVE_PATH = "user://leaderboard.dat"
const MAX_ENTRIES = 100

var local_leaderboard: Array = []
var player_name: String = "Player"

func _ready():
	load_leaderboard()
	detect_player_name()

func detect_player_name():
	var saved_name = get_saved_player_name()
	if saved_name != "":
		player_name = saved_name
	else:
		player_name = "Player" + str(randi() % 10000)
		save_player_name()

func get_saved_player_name() -> String:
	var config = ConfigFile.new()
	if config.load("user://player.cfg") == OK:
		return config.get_value("player", "name", "")
	return ""

func save_player_name():
	var config = ConfigFile.new()
	config.set_value("player", "name", player_name)
	config.save("user://player.cfg")

func set_player_name(new_name: String):
	player_name = new_name
	save_player_name()

func submit_score(score: int):
	var entry = {
		"name": player_name,
		"score": score,
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_datetime_string_from_system()
	}
	
	local_leaderboard.append(entry)
	local_leaderboard.sort_custom(func(a, b): return a.score > b.score)
	
	if local_leaderboard.size() > MAX_ENTRIES:
		local_leaderboard.resize(MAX_ENTRIES)
	
	save_leaderboard()
	leaderboard_updated.emit()
	
	var game_api = get_node_or_null("/root/GamereadyApi")
	if game_api:
		game_api.send_analytics_event("score_submitted", {"score": score})
		submit_to_cloud(entry)

func submit_to_cloud(entry: Dictionary):
	var game_api = get_node_or_null("/root/GamereadyApi")
	if game_api:
		var cloud_data = {
			"leaderboard": {
				"name": entry.name,
				"score": entry.score,
				"timestamp": entry.timestamp
			}
		}
		game_api.save_cloud_data(cloud_data)

func get_leaderboard(limit: int = 10) -> Array:
	if limit <= 0 or limit > local_leaderboard.size():
		return local_leaderboard.duplicate()
	return local_leaderboard.slice(0, limit)

func get_player_rank(score: int = -1) -> int:
	var target_score = score if score >= 0 else get_player_best_score()
	
	for i in range(local_leaderboard.size()):
		if local_leaderboard[i].name == player_name and local_leaderboard[i].score == target_score:
			return i + 1
	
	return -1

func get_player_best_score() -> int:
	var best = 0
	for entry in local_leaderboard:
		if entry.name == player_name and entry.score > best:
			best = entry.score
	return best

func get_top_score() -> int:
	if local_leaderboard.is_empty():
		return 0
	return local_leaderboard[0].score

func is_high_score(score: int) -> bool:
	if local_leaderboard.is_empty():
		return true
	return score > local_leaderboard[0].score

func get_player_entries() -> Array:
	var entries = []
	for entry in local_leaderboard:
		if entry.name == player_name:
			entries.append(entry)
	return entries

func save_leaderboard():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(local_leaderboard)
		file.close()

func load_leaderboard():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		
		if typeof(data) == TYPE_ARRAY:
			local_leaderboard = data
			local_leaderboard.sort_custom(func(a, b): return a.score > b.score)

func reset_leaderboard():
	local_leaderboard.clear()
	save_leaderboard()
	leaderboard_updated.emit()

func merge_cloud_leaderboard(cloud_data: Array):
	for entry in cloud_data:
		if is_valid_entry(entry):
			local_leaderboard.append(entry)
	
	local_leaderboard.sort_custom(func(a, b): return a.score > b.score)
	
	if local_leaderboard.size() > MAX_ENTRIES:
		local_leaderboard.resize(MAX_ENTRIES)
	
	save_leaderboard()
	leaderboard_updated.emit()

func is_valid_entry(entry: Dictionary) -> bool:
	return entry.has("name") and entry.has("score") and entry.has("timestamp")

func get_statistics() -> Dictionary:
	if local_leaderboard.is_empty():
		return {
			"total_games": 0,
			"average_score": 0,
			"best_score": 0,
			"total_score": 0
		}
	
	var total_score = 0
	var best = 0
	var player_games = 0
	
	for entry in local_leaderboard:
		total_score += entry.score
		if entry.score > best:
			best = entry.score
		if entry.name == player_name:
			player_games += 1
	
	return {
		"total_games": player_games,
		"average_score": total_score / local_leaderboard.size() if local_leaderboard.size() > 0 else 0,
		"best_score": best,
		"total_score": total_score
	}
