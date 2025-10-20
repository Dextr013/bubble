# achievement_manager.gd
extends Node

signal achievement_unlocked(achievement_id: String)

var achievements: Dictionary = {}
const SAVE_PATH = "user://achievements.dat"

func _ready():
	initialize_achievements()
	load_achievements()

func initialize_achievements():
	achievements = {
		"first_win": {
			"id": "first_win",
			"name_key": "achievement_first_win",
			"desc_key": "achievement_first_win_desc",
			"icon": "res://assets/icons/achievement_first_win.png",
			"unlocked": false,
			"timestamp": 0
		},
		"combo_master": {
			"id": "combo_master",
			"name_key": "achievement_combo",
			"desc_key": "achievement_combo_desc",
			"icon": "res://assets/icons/achievement_combo.png",
			"unlocked": false,
			"timestamp": 0
		},
		"score_1000": {
			"id": "score_1000",
			"name_key": "achievement_score_1000",
			"desc_key": "achievement_score_1000_desc",
			"icon": "res://assets/icons/achievement_score.png",
			"unlocked": false,
			"timestamp": 0
		},
		"sharpshooter": {
			"id": "sharpshooter",
			"name_key": "achievement_sharpshooter",
			"desc_key": "achievement_sharpshooter_desc",
			"icon": "res://assets/icons/achievement_sharpshooter.png",
			"unlocked": false,
			"timestamp": 0
		},
		"perfect_aim": {
			"id": "perfect_aim",
			"name_key": "achievement_perfect_aim",
			"desc_key": "achievement_perfect_aim_desc",
			"icon": "res://assets/icons/achievement_perfect.png",
			"unlocked": false,
			"timestamp": 0
		},
		"score_5000": {
			"id": "score_5000",
			"name_key": "achievement_score_5000",
			"desc_key": "achievement_score_5000_desc",
			"icon": "res://assets/icons/achievement_score.png",
			"unlocked": false,
			"timestamp": 0
		}
	}

func unlock(achievement_id: String):
	if not achievements.has(achievement_id):
		print("Achievement not found: ", achievement_id)
		return
	
	if achievements[achievement_id].unlocked:
		return
	
	achievements[achievement_id].unlocked = true
	achievements[achievement_id].timestamp = Time.get_unix_time_from_system()
	
	save_achievements()
	achievement_unlocked.emit(achievement_id)
	show_achievement_popup(achievement_id)
	
	var game_api = get_node_or_null("/root/GamereadyApi")
	if game_api:
		game_api.send_analytics_event("achievement_unlocked", {"id": achievement_id})
	
	print("Achievement unlocked: ", achievement_id)

func is_unlocked(achievement_id: String) -> bool:
	if not achievements.has(achievement_id):
		return false
	return achievements[achievement_id].unlocked

func get_achievement(achievement_id: String) -> Dictionary:
	if achievements.has(achievement_id):
		return achievements[achievement_id]
	return {}

func get_all_achievements() -> Array:
	var result = []
	for ach_id in achievements.keys():
		result.append(achievements[ach_id])
	return result

func get_unlocked_count() -> int:
	var count = 0
	for ach in achievements.values():
		if ach.unlocked:
			count += 1
	return count

func get_total_count() -> int:
	return achievements.size()

func get_completion_percentage() -> float:
	if achievements.size() == 0:
		return 0.0
	return (float(get_unlocked_count()) / float(get_total_count())) * 100.0

func save_achievements():
	var save_data = {}
	for ach_id in achievements.keys():
		save_data[ach_id] = {
			"unlocked": achievements[ach_id].unlocked,
			"timestamp": achievements[ach_id].timestamp
		}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_achievements():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if typeof(save_data) == TYPE_DICTIONARY:
			for ach_id in save_data.keys():
				if achievements.has(ach_id):
					achievements[ach_id].unlocked = save_data[ach_id].get("unlocked", false)
					achievements[ach_id].timestamp = save_data[ach_id].get("timestamp", 0)

func reset_achievements():
	for ach in achievements.values():
		ach.unlocked = false
		ach.timestamp = 0
	save_achievements()

func show_achievement_popup(achievement_id: String):
	var ach = get_achievement(achievement_id)
	if ach.is_empty():
		return
	
	var i18n = get_node_or_null("/root/I18nManager")
	var name_text = i18n.tr(ach.name_key) if i18n else ach.name_key
	var desc_text = i18n.tr(ach.desc_key) if i18n else ach.desc_key
	
	var popup = preload("res://achievement_popup.tscn").instantiate() if ResourceLoader.exists("res://achievement_popup.tscn") else create_simple_popup(name_text, desc_text)
	
	var root = get_tree().root
	root.add_child(popup)
	
	if popup.has_method("show_achievement"):
		popup.show_achievement(name_text, desc_text, ach.icon)

func create_simple_popup(title: String, description: String) -> Control:
	var popup = Control.new()
	popup.name = "AchievementPopup"
	
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(300, 100)
	popup.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	var tween = popup.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).from(0.0)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(popup.queue_free)
	
	return popup
