# achievements.gd
extends Control

const BASE_RESOLUTION = Vector2(1280, 1136)

var screen_size: Vector2
var scale_factor: Vector2

@onready var scroll_container: ScrollContainer
@onready var achievement_list: VBoxContainer
@onready var back_button: Button
@onready var title_label: Label
@onready var progress_label: Label
@onready var bg: TextureRect = $TextureRect

func _ready():
	await get_tree().process_frame
	
	calculate_adaptive_sizes()
	setup_background()
	setup_ui()
	populate_achievements()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		i18n.language_changed.connect(_on_language_changed)

func calculate_adaptive_sizes():
	screen_size = get_viewport_rect().size
	scale_factor = screen_size / BASE_RESOLUTION

func _on_viewport_size_changed():
	calculate_adaptive_sizes()
	setup_background()
	reposition_ui()

func setup_background():
	if bg:
		# Обновляем размер фона для адаптивности
		bg.size = screen_size
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup_ui():
	var _min_scale = min(scale_factor.x, scale_factor.y)  # Исправлено: добавлен префикс _
	var _i18n = get_node_or_null("/root/I18nManager")     # Исправлено: добавлен префикс _
	
	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = _i18n.translate("achievements_title") if _i18n else "ACHIEVEMENTS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", int(42 * _min_scale))
	title_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 50 * scale_factor.y)
	title_label.size = Vector2(400 * scale_factor.x, 60 * scale_factor.y)
	add_child(title_label)
	
	# Progress
	progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color.YELLOW)
	progress_label.add_theme_font_size_override("font_size", int(24 * _min_scale))
	progress_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 120 * scale_factor.y)
	progress_label.size = Vector2(400 * scale_factor.x, 40 * scale_factor.y)
	add_child(progress_label)
	
	# Scroll Container
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.position = Vector2(50 * scale_factor.x, 180 * scale_factor.y)
	scroll_container.size = Vector2(screen_size.x - 100 * scale_factor.x, screen_size.y - 280 * scale_factor.y)
	add_child(scroll_container)
	
	# Achievement List
	achievement_list = VBoxContainer.new()
	achievement_list.name = "AchievementList"
	achievement_list.add_theme_constant_override("separation", int(10 * _min_scale))
	scroll_container.add_child(achievement_list)
	
	# Back Button
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = _i18n.translate("back") if _i18n else "Back"
	back_button.position = Vector2(screen_size.x / 2 - 75 * scale_factor.x, screen_size.y - 80 * scale_factor.y)
	back_button.size = Vector2(150 * scale_factor.x, 50 * scale_factor.y)
	back_button.add_theme_font_size_override("font_size", int(24 * _min_scale))
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

func populate_achievements():
	var achievement_mgr = get_node_or_null("/root/AchievementManager")
	if not achievement_mgr:
		return
	
	var achievements = achievement_mgr.get_all_achievements()
	var _i18n = get_node_or_null("/root/I18nManager")     # Исправлено: добавлен префикс _
	var _min_scale = min(scale_factor.x, scale_factor.y)  # Исправлено: добавлен префикс _
	
	for child in achievement_list.get_children():
		child.queue_free()
	
	for achievement in achievements:
		var achievement_panel = create_achievement_panel(achievement, _i18n, _min_scale)
		achievement_list.add_child(achievement_panel)
	
	update_progress_label()

func create_achievement_panel(achievement: Dictionary, _i18n, _min_scale: float) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100 * _min_scale)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Icon
	var icon_texture = TextureRect.new()
	icon_texture.custom_minimum_size = Vector2(80 * _min_scale, 80 * _min_scale)
	icon_texture.texture = load(achievement.icon)
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hbox.add_child(icon_texture)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Name and Description
	var name_label = Label.new()
	name_label.text = _i18n.translate(achievement.name_key) if _i18n else achievement.name_key
	name_label.add_theme_font_size_override("font_size", int(20 * _min_scale))
	name_label.add_theme_color_override("font_color", Color.YELLOW if achievement.unlocked else Color.GRAY)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = _i18n.translate(achievement.desc_key) if _i18n else achievement.desc_key
	desc_label.add_theme_font_size_override("font_size", int(16 * _min_scale))
	desc_label.add_theme_color_override("font_color", Color.WHITE if achievement.unlocked else Color.DARK_GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Status
	var status_label = Label.new()
	status_label.text = "UNLOCKED" if achievement.unlocked else "LOCKED"
	status_label.add_theme_font_size_override("font_size", int(18 * _min_scale))
	status_label.add_theme_color_override("font_color", Color.GREEN if achievement.unlocked else Color.RED)
	hbox.add_child(status_label)
	
	return panel

func update_progress_label():
	var achievement_mgr = get_node_or_null("/root/AchievementManager")
	var _i18n = get_node_or_null("/root/I18nManager")  # Исправлено: добавлен префикс _
	if achievement_mgr and progress_label:
		var unlocked = achievement_mgr.get_unlocked_count()
		var total = achievement_mgr.get_total_count()
		var percentage = achievement_mgr.get_completion_percentage()
		progress_label.text = "%d/%d (%.1f%%)" % [unlocked, total, percentage]

func reposition_ui():
	var _min_scale = min(scale_factor.x, scale_factor.y)  # Исправлено: добавлен префикс _
	
	if title_label:
		title_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 50 * scale_factor.y)
		title_label.size = Vector2(400 * scale_factor.x, 60 * scale_factor.y)
	
	if progress_label:
		progress_label.position = Vector2(screen_size.x / 2 - 200 * scale_factor.x, 120 * scale_factor.y)
		progress_label.size = Vector2(400 * scale_factor.x, 40 * scale_factor.y)
	
	if scroll_container:
		scroll_container.position = Vector2(50 * scale_factor.x, 180 * scale_factor.y)
		scroll_container.size = Vector2(screen_size.x - 100 * scale_factor.x, screen_size.y - 280 * scale_factor.y)
	
	if back_button:
		back_button.position = Vector2(screen_size.x / 2 - 75 * scale_factor.x, screen_size.y - 80 * scale_factor.y)
		back_button.size = Vector2(150 * scale_factor.x, 50 * scale_factor.y)

func _on_language_changed(_new_language: String):
	var _i18n = get_node_or_null("/root/I18nManager")  # Исправлено: добавлен префикс _
	if title_label:
		title_label.text = _i18n.translate("achievements_title") if _i18n else "ACHIEVEMENTS"
	if back_button:
		back_button.text = _i18n.translate("back") if _i18n else "Back"
	populate_achievements()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://mainmenu.tscn")
