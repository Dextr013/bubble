# settings.gd (с I18N)
extends Control

const BASE_RESOLUTION = Vector2(1280, 1136)

var screen_size: Vector2
var scale_factor: Vector2

@onready var vbox = $VBoxContainer
@onready var language_option = $VBoxContainer/LanguageOptionButton
@onready var music_checkbox = $VBoxContainer/MusicCheckBox
@onready var sound_checkbox = $VBoxContainer/SoundCheckBox
@onready var vibration_checkbox = $VBoxContainer/VibrationCheckBox
@onready var back_button = $VBoxContainer/BackButton

var bg: TextureRect
var title_label: Label

func _ready():
	# Ждем инициализации всех автозагрузок
	await get_tree().process_frame
	
	calculate_adaptive_sizes()
	
	# Настраиваем выбор языка
	language_option.clear()
	var i18n = get_node_or_null("/root/I18N")
	if i18n:
		language_option.add_item(i18n.tr("lang_ru"), 0)
		language_option.add_item(i18n.tr("lang_en"), 1)
	else:
		language_option.add_item("Русский", 0)
		language_option.add_item("English", 1)
	
	language_option.selected = SettingsManager.language
	music_checkbox.button_pressed = SettingsManager.music_enabled
	sound_checkbox.button_pressed = SettingsManager.sound_enabled
	vibration_checkbox.button_pressed = SettingsManager.vibration_enabled
	
	language_option.item_selected.connect(_on_language_selected)
	music_checkbox.toggled.connect(_on_music_toggled)
	sound_checkbox.toggled.connect(_on_sound_toggled)
	vibration_checkbox.toggled.connect(_on_vibration_toggled)
	back_button.pressed.connect(_on_back_pressed)
	
	setup_background()
	setup_title()
	setup_ui_styles()
	position_ui_elements()
	update_ui_texts()
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Подключаемся к смене языка
	if i18n:
		i18n.language_changed.connect(_on_language_changed)

func _on_language_changed(_new_language: String):
	update_ui_texts()
	# Обновляем элементы списка языков
	var i18n = get_node_or_null("/root/I18N")
	if not i18n:
		return
		
	var current_selection = language_option.selected
	language_option.clear()
	language_option.add_item(i18n.tr("lang_ru"), 0)
	language_option.add_item(i18n.tr("lang_en"), 1)
	language_option.selected = current_selection

func calculate_adaptive_sizes():
	screen_size = get_viewport_rect().size
	scale_factor = screen_size / BASE_RESOLUTION

func _on_viewport_size_changed():
	calculate_adaptive_sizes()
	position_ui_elements()
	if bg:
		bg.size = screen_size
	if title_label:
		position_title()

func setup_background():
	bg = TextureRect.new()
	bg.texture = load("res://assets/background/Mainmenubg.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = screen_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func setup_title():
	title_label = Label.new()
	title_label.name = "TitleLabel"
	var i18n = get_node_or_null("/root/I18N")
	title_label.text = i18n.tr("settings_title") if i18n else "SETTINGS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(title_label)
	position_title()

func position_title():
	var min_scale = min(scale_factor.x, scale_factor.y)
	title_label.position = Vector2(screen_size.x / 2 - 150 * scale_factor.x, 100 * scale_factor.y)
	title_label.size = Vector2(300 * scale_factor.x, 60 * scale_factor.y)
	title_label.add_theme_font_size_override("font_size", int(42 * min_scale))

func position_ui_elements():
	var min_scale = min(scale_factor.x, scale_factor.y)
	
	if vbox:
		vbox.position = Vector2(
			screen_size.x / 2 - 150 * scale_factor.x,
			screen_size.y / 2 - 150 * scale_factor.y
		)
		
		if vbox is VBoxContainer:
			vbox.add_theme_constant_override("separation", int(25 * min_scale))
	
	# Настройка элементов
	if language_option:
		language_option.custom_minimum_size = Vector2(300 * scale_factor.x, 50 * scale_factor.y)
		language_option.add_theme_font_size_override("font_size", int(20 * min_scale))
	
	if music_checkbox:
		music_checkbox.custom_minimum_size = Vector2(300 * scale_factor.x, 50 * scale_factor.y)
		music_checkbox.add_theme_font_size_override("font_size", int(20 * min_scale))
	
	if sound_checkbox:
		sound_checkbox.custom_minimum_size = Vector2(300 * scale_factor.x, 50 * scale_factor.y)
		sound_checkbox.add_theme_font_size_override("font_size", int(20 * min_scale))
	
	if vibration_checkbox:
		vibration_checkbox.custom_minimum_size = Vector2(300 * scale_factor.x, 50 * scale_factor.y)
		vibration_checkbox.add_theme_font_size_override("font_size", int(20 * min_scale))
	
	if back_button:
		back_button.custom_minimum_size = Vector2(300 * scale_factor.x, 60 * scale_factor.y)
		back_button.add_theme_font_size_override("font_size", int(24 * min_scale))

func setup_ui_styles():
	var font_color = Color.WHITE
	var hover_color = Color.YELLOW
	var pressed_color = Color.ORANGE
	
	if language_option:
		language_option.add_theme_color_override("font_color", font_color)
		language_option.add_theme_color_override("font_hover_color", hover_color)
	
	if music_checkbox:
		music_checkbox.add_theme_color_override("font_color", font_color)
	
	if sound_checkbox:
		sound_checkbox.add_theme_color_override("font_color", font_color)
	
	if vibration_checkbox:
		vibration_checkbox.add_theme_color_override("font_color", font_color)
	
	if back_button:
		back_button.add_theme_color_override("font_color", font_color)
		back_button.add_theme_color_override("font_hover_color", hover_color)
		back_button.add_theme_color_override("font_pressed_color", pressed_color)

func update_ui_texts():
	var i18n = get_node_or_null("/root/I18N")
	if not i18n:
		return
		
	if title_label:
		title_label.text = i18n.tr("settings_title")
	if music_checkbox:
		music_checkbox.text = i18n.tr("music")
	if sound_checkbox:
		sound_checkbox.text = i18n.tr("sound")
	if vibration_checkbox:
		vibration_checkbox.text = i18n.tr("vibration")
	if back_button:
		back_button.text = i18n.tr("back")

func _on_language_selected(index):
	SettingsManager.set_language(index)
	
	# Аналитика смены языка
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		var lang = "ru" if index == 0 else "en"
		game_api.send_analytics_event("language_changed", {"language": lang})

func _on_music_toggled(toggled):
	SettingsManager.set_music(toggled)

func _on_sound_toggled(toggled):
	SettingsManager.set_sound(toggled)

func _on_vibration_toggled(toggled):
	SettingsManager.set_vibration(toggled)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://mainmenu.tscn")
