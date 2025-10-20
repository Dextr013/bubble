# mainmenu.gd (с I18N)
extends Control

const BASE_RESOLUTION = Vector2(1280, 1136)

var screen_size: Vector2
var scale_factor: Vector2

@onready var vbox = $VBoxContainer
@onready var play_button = $VBoxContainer/PlayButton
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var leaderboard_button = $VBoxContainer/LeaderboardButton
@onready var achievements_button = $VBoxContainer/AchievementsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var bg: TextureRect = $TextureRect

var title_label: Label

func _ready():
	# Ждем инициализации всех автозагрузок
	await get_tree().process_frame
	
	calculate_adaptive_sizes()
	
	continue_button.disabled = not SaveManager.has_save()
	
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	setup_background()
	setup_title()
	setup_button_styles()
	position_ui_elements()
	update_button_texts()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Подключаемся к смене языка
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		i18n.language_changed.connect(_on_language_changed)
	
	# Аналитика открытия меню
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("main_menu_opened")

func _on_language_changed(_new_language: String):
	update_button_texts()

func calculate_adaptive_sizes():
	screen_size = get_viewport_rect().size
	scale_factor = screen_size / BASE_RESOLUTION

func _on_viewport_size_changed():
	calculate_adaptive_sizes()
	position_ui_elements()
	setup_background()
	if title_label:
		position_title()

func setup_background():
	if bg:
		# Обновляем размер фона для адаптивности
		bg.size = screen_size
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup_title():
	title_label = Label.new()
	title_label.name = "TitleLabel"
	var i18n = get_node_or_null("/root/I18nManager")
	title_label.text = i18n.tr("main_menu_title") if i18n else "BUBBLE SHOOTER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(title_label)
	position_title()

func position_title():
	var min_scale = min(scale_factor.x, scale_factor.y)
	title_label.position = Vector2(screen_size.x / 2 - 250 * scale_factor.x, 100 * scale_factor.y)
	title_label.size = Vector2(500 * scale_factor.x, 80 * scale_factor.y)
	title_label.add_theme_font_size_override("font_size", int(54 * min_scale))

func position_ui_elements():
	var min_scale = min(scale_factor.x, scale_factor.y)
	
	if vbox:
		vbox.position = Vector2(
			screen_size.x / 2 - 150 * scale_factor.x,
			screen_size.y / 2 - 150 * scale_factor.y
		)
		
		if vbox is VBoxContainer:
			vbox.add_theme_constant_override("separation", int(20 * min_scale))
	
	var buttons = [play_button, continue_button, settings_button, 
				   leaderboard_button, achievements_button, quit_button]
	
	for button in buttons:
		if button:
			button.custom_minimum_size = Vector2(300 * scale_factor.x, 60 * scale_factor.y)
			button.add_theme_font_size_override("font_size", int(24 * min_scale))

func setup_button_styles():
	var normal_font_color = Color.WHITE
	var hover_font_color = Color.YELLOW
	var pressed_font_color = Color.ORANGE
	
	var buttons = [play_button, continue_button, settings_button, 
				   leaderboard_button, achievements_button, quit_button]
	
	for button in buttons:
		if button:
			button.add_theme_color_override("font_color", normal_font_color)
			button.add_theme_color_override("font_hover_color", hover_font_color)
			button.add_theme_color_override("font_pressed_color", pressed_font_color)

func update_button_texts():
	var i18n = get_node_or_null("/root/I18nManager")
	if not i18n:
		return
		
	if play_button:
		play_button.text = i18n.tr("play")
	if continue_button:
		continue_button.text = i18n.tr("continue")
	if settings_button:
		settings_button.text = i18n.tr("settings")
	if leaderboard_button:
		leaderboard_button.text = i18n.tr("leaderboard")
	if achievements_button:
		achievements_button.text = i18n.tr("achievements")
	if quit_button:
		quit_button.text = i18n.tr("quit")
	if title_label:
		title_label.text = i18n.tr("main_menu_title")

func _on_play_pressed():
	SaveManager.delete_save()
	
	# Аналитика начала новой игры
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("new_game_started")
	
	get_tree().change_scene_to_file("res://main.tscn")

func _on_continue_pressed():
	# Аналитика продолжения игры
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("continue_game")
	
	get_tree().change_scene_to_file("res://main.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_leaderboard_pressed():
	print("Leaderboard")
	
	# Аналитика открытия лидерборда
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("leaderboard_opened")

func _on_achievements_pressed():
	print("Achievements")
	
	# Аналитика открытия достижений
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("achievements_opened")

func _on_quit_pressed():
	get_tree().quit()
