# leaderboard.gd
extends Control

const BASE_RESOLUTION = Vector2(1280, 1136)

var screen_size: Vector2
var scale_factor: Vector2

@onready var scroll_container: ScrollContainer
@onready var leaderboard_list: VBoxContainer
@onready var back_button: Button
@onready var title_label: Label
@onready var player_rank_label: Label

var bg: TextureRect

func _ready():
	await get_tree().process_frame
	
	calculate_adaptive_sizes()
	setup_background()
	setup_ui()
	populate_leaderboard()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		i18n.language_changed.connect(_on_language_changed)
	
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr:
		leaderboard_mgr.leaderboard_updated.connect(populate_leaderboard)

func calculate_adaptive_sizes():
	screen_size = get_viewport_rect().size
	scale_factor = screen_size / BASE_RESOLUTION

func _on_viewport_size_changed():
	calculate_adaptive_sizes()
	if bg:
		bg.size = screen_size
	reposition_ui()

func setup_background():
	bg = TextureRect.new()
	bg.texture = load("res://assets/background/Mainmenubg.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = screen_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func setup_ui():
	var min_scale = min(scale_factor.x, scale_factor.y)
	var i18n = get_node_or_null("/root/I18nManager")
	
	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = i18n.tr("leaderboard_title") if i18n else "LEADERBOARD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", int(42 * min_scale))
	title_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 50 * scale_factor.y)
	title_label.size = Vector2(400 * scale_factor.x, 60 * scale_factor.y)
	add_child(title_label)
	
	# Player rank
	player_rank_label = Label.new()
	player_rank_label.name = "PlayerRankLabel"
	player_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_rank_label.add_theme_color_override("font_color", Color.YELLOW)
	player_rank_label.add_theme_font_size_override("font_size", int(24 * min_scale))
	player_rank_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 120 * scale_factor.y)
	player_rank_label.size = Vector2(400 * scale_factor.x, 40 * scale_factor.y)
	add_child(player_rank_label)
	
	# Header
	var header = create_header(i18n, min_scale)
	header.position = Vector2(50 * scale_factor.x, 180 * scale_factor.y)
	add_child(header)
	
	# Scroll Container
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.position = Vector2(50 * scale_factor.x, 230 * scale_factor.y)
	scroll_container.size = Vector2(screen_size.x - 100 * scale_factor.x, screen_size.y - 330 * scale_factor.y)
	add_child(scroll_container)
	
	# Leaderboard List
	leaderboard_list = VBoxContainer.new()
	leaderboard_list.name = "LeaderboardList"
	leaderboard_list.add_theme_constant_override("separation", int(10 * min_scale))
	scroll_container.add_child(leaderboard_list)
	
	# Back Button
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = i18n.tr("back") if i18n else "Back"
	back_button.position = Vector2(screen_size.x / 2 - 75 * scale_factor.x, screen_size.y - 80 * scale_factor.y)
	back_button.size = Vector2(150 * scale_factor.x, 50 * scale_factor.y)
	back_button.add_theme_font_size_override("font_size", int(24 * min_scale))
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func create_header(i18n, min_scale: float) -> HBoxContainer:
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(screen_size.x - 100 * scale_factor.x, 40 * min_scale)
	
	var rank_label = Label.new()
	rank_label.text = i18n.tr("position") if i18n else "#"
	rank_label.custom_minimum_size = Vector2(80 * min_scale, 0)
	rank_label.add_theme_font_size_override("font_size", int(20 * min_scale))
	rank_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(rank_label)
	
	var name_label = Label.new()
	name_label.text = i18n.tr("player") if i18n else "Player"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", int(20 * min_scale))
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(name_label)
	
	var score_label = Label.new()
	score_label.text = i18n.tr("score") if i18n else "Score"
	score_label.custom_minimum_size = Vector2(120 * min_scale, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", int(20 * min_scale))
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(score_label)
	
	return header

func populate_leaderboard():
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if not leaderboard_mgr:
		return
	
	var entries = leaderboard_mgr.get_leaderboard(50)
	var i18n = get_node_or_null("/root/I18nManager")
	var _min_scale = min(scale_factor.x, scale_factor.y)  # Исправлено: добавлен префикс _
	
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	if entries.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = i18n.tr("no_data") if i18n else "No data available"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.add_theme_font_size_override("font_size", int(24 * _min_scale))
		no_data_label.add_theme_color_override("font_color", Color.GRAY)
		leaderboard_list.add_child(no_data_label)
	else:
		for i in range(entries.size()):
			var entry_panel = create_entry_panel(i + 1, entries[i], leaderboard_mgr.player_name, _min_scale)
			leaderboard_list.add_child(entry_panel)
	
	# Update player rank
	var player_rank = leaderboard_mgr.get_player_rank()
	if player_rank > 0:
		# Исправлено: передача параметров через массив вместо словаря
		var rank_text = i18n.tr("your_rank") if i18n else "Your rank: "
		player_rank_label.text = rank_text + str(player_rank)
	else:
		player_rank_label.text = i18n.tr("no_data") if i18n else "No rank yet"

func create_entry_panel(rank: int, entry: Dictionary, player_name: String, min_scale: float) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60 * min_scale)
	
	var is_player = entry.name == player_name
	
	# Highlight player's entry
	if is_player:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.0, 0.5)
		style.border_width_left = int(4 * min_scale)
		style.border_width_right = int(4 * min_scale)
		style.border_color = Color.YELLOW
		panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Rank
	var rank_label = Label.new()
	rank_label.custom_minimum_size = Vector2(80 * min_scale, 0)
	rank_label.add_theme_font_size_override("font_size", int(24 * min_scale))
	
	# Special styling for top 3
	if rank == 1:
		rank_label.text = "🥇 1"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
	elif rank == 2:
		rank_label.text = "🥈 2"
		rank_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))  # Silver
	elif rank == 3:
		rank_label.text = "🥉 3"
		rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))  # Bronze
	else:
		rank_label.text = str(rank)
		rank_label.add_theme_color_override("font_color", Color.WHITE if is_player else Color.LIGHT_GRAY)
	
	hbox.add_child(rank_label)
	
	# Name
	var name_label = Label.new()
	name_label.text = entry.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", int(20 * min_scale))
	name_label.add_theme_color_override("font_color", Color.YELLOW if is_player else Color.WHITE)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(name_label)
	
	# Score
	var score_label = Label.new()
	score_label.text = str(entry.score)
	score_label.custom_minimum_size = Vector2(120 * min_scale, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", int(24 * min_scale))
	score_label.add_theme_color_override("font_color", Color.YELLOW if is_player else Color.WHITE)
	hbox.add_child(score_label)
	
	return panel

func reposition_ui():
	var _min_scale = min(scale_factor.x, scale_factor.y)  # Исправлено: добавлен префикс _
	
	if title_label:
		title_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 50 * scale_factor.y)
		title_label.size = Vector2(400 * scale_factor.x, 60 * scale_factor.y)
	
	if player_rank_label:
		player_rank_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 120 * scale_factor.y)
		player_rank_label.size = Vector2(400 * scale_factor.x, 40 * scale_factor.y)
	
	if scroll_container:
		scroll_container.position = Vector2(50 * scale_factor.x, 230 * scale_factor.y)
		scroll_container.size = Vector2(screen_size.x - 100 * scale_factor.x, screen_size.y - 330 * scale_factor.y)
	
	if back_button:
		back_button.position = Vector2(screen_size.x / 2 - 75 * scale_factor.x, screen_size.y - 80 * scale_factor.y)
		back_button.size = Vector2(150 * scale_factor.x, 50 * scale_factor.y)

func _on_language_changed(_new_language: String):
	var i18n = get_node_or_null("/root/I18nManager")
	if title_label:
		title_label.text = i18n.tr("leaderboard_title") if i18n else "LEADERBOARD"
	if back_button:
		back_button.text = i18n.tr("back") if i18n else "Back"
	populate_leaderboard()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://mainmenu.tscn")
