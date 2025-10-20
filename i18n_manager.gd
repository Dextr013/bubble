# i18n_manager.gd
extends Node

signal language_changed(new_language: String)

const SUPPORTED_LANGUAGES = ["ru", "en"]
const DEFAULT_LANGUAGE = "ru"

var current_language: String = DEFAULT_LANGUAGE
var translations: Dictionary = {}

func _ready():
	load_translations()
	detect_and_set_language()

func load_translations():
	translations = {
		"ru": {
			# Главное меню
			"main_menu_title": "BUBBLE SHOOTER",
			"play": "Играть",
			"continue": "Продолжить",
			"settings": "Настройки",
			"leaderboard": "Лидеры",
			"achievements": "Достижения",
			"quit": "Выход",
			
			# Игра
			"score": "Счёт",
			"game_over": "ИГРА ОКОНЧЕНА!",
			"game_over_score": "ИГРА ОКОНЧЕНА! Счёт: {score}",
			"continue_question": "ПРОДОЛЖИТЬ?",
			"lives_left": "Осталось попыток: {lives}",
			"restart": "Заново",
			"continue_ad": "Продолжить (реклама)",
			"level_complete": "Уровень пройден!",
			"bonus_score": "Бонус: +{score}",
			
			# Настройки
			"settings_title": "НАСТРОЙКИ",
			"language": "Язык",
			"music": "Музыка",
			"sound": "Звуки",
			"vibration": "Вибрация",
			"back": "Назад",
			"reset_progress": "Сбросить прогресс",
			"confirm_reset": "Вы уверены?",
			"yes": "Да",
			"no": "Нет",
			
			# Языки
			"lang_ru": "Русский",
			"lang_en": "English",
			
			# Достижения
			"achievements_title": "ДОСТИЖЕНИЯ",
			"achievement_first_win": "Первая победа",
			"achievement_first_win_desc": "Пройдите первый уровень",
			"achievement_combo": "Комбо мастер",
			"achievement_combo_desc": "Сделайте комбо из 5+ шаров",
			"achievement_score_1000": "1000 очков",
			"achievement_score_1000_desc": "Наберите 1000 очков",
			"achievement_sharpshooter": "Снайпер",
			"achievement_sharpshooter_desc": "Сделайте 100 выстрелов",
			"achievement_perfect_aim": "Идеальная цель",
			"achievement_perfect_aim_desc": "Уничтожьте 50 шаров без промаха",
			"achievement_score_5000": "5000 очков",
			"achievement_score_5000_desc": "Наберите 5000 очков",
			
			# Лидерборд
			"leaderboard_title": "ТАБЛИЦА ЛИДЕРОВ",
			"rank": "Место",
			"player": "Игрок",
			"your_rank": "Ваше место: {rank}",
			"no_data": "Нет данных",
			"position": "Позиция",
			"name": "Имя",
			"date": "Дата",
			"view_full": "Посмотреть полностью",
			"enter_name": "Введите имя",
			"submit": "Отправить",
			
			# Статистика
			"statistics": "Статистика",
			"total_games": "Всего игр",
			"average_score": "Средний счёт",
			"best_score": "Лучший счёт",
			"completion": "Выполнено",
			
			# Уведомления
			"loading": "Загрузка...",
			"saving": "Сохранение...",
			"ad_loading": "Загрузка рекламы...",
			"ad_reward": "Награда получена!",
			"connection_error": "Ошибка подключения",
			"try_again": "Попробовать снова",
			
			# Обучение
			"tutorial_welcome": "Добро пожаловать!",
			"tutorial_aim": "Прицельтесь мышкой",
			"tutorial_shoot": "Нажмите, чтобы выстрелить",
			"tutorial_match": "Соберите 3+ шара одного цвета",
			"tutorial_complete": "Отлично!",
			"skip": "Пропустить",
			
			# Бустеры
			"booster_bomb": "Бомба",
			"booster_bomb_desc": "Взрывает все шары вокруг",
			"booster_color": "Радуга",
			"booster_color_desc": "Подходит к любому цвету",
			"booster_line": "Линия",
			"booster_line_desc": "Убирает целый ряд",
			
			# Меню паузы
			"pause": "Пауза",
			"resume": "Продолжить",
			"menu": "Меню",
			
			# Поделиться
			"share_text": "Я набрал {score} очков в Bubble Shooter! Можешь побить мой рекорд?",
			"share_button": "Поделиться",
			
			# Прочее
			"new_high_score": "Новый рекорд!",
			"combo": "Комбо х{count}",
			"perfect": "Отлично!",
			"good": "Хорошо!",
			"nice": "Неплохо!"
		},
		
		"en": {
			# Main menu
			"main_menu_title": "BUBBLE SHOOTER",
			"play": "Play",
			"continue": "Continue",
			"settings": "Settings",
			"leaderboard": "Leaderboard",
			"achievements": "Achievements",
			"quit": "Quit",
			
			# Game
			"score": "Score",
			"game_over": "GAME OVER!",
			"game_over_score": "GAME OVER! Score: {score}",
			"continue_question": "CONTINUE?",
			"lives_left": "Lives left: {lives}",
			"restart": "Restart",
			"continue_ad": "Continue (watch ad)",
			"level_complete": "Level Complete!",
			"bonus_score": "Bonus: +{score}",
			
			# Settings
			"settings_title": "SETTINGS",
			"language": "Language",
			"music": "Music",
			"sound": "Sound",
			"vibration": "Vibration",
			"back": "Back",
			"reset_progress": "Reset Progress",
			"confirm_reset": "Are you sure?",
			"yes": "Yes",
			"no": "No",
			
			# Languages
			"lang_ru": "Русский",
			"lang_en": "English",
			
			# Achievements
			"achievements_title": "ACHIEVEMENTS",
			"achievement_first_win": "First Victory",
			"achievement_first_win_desc": "Complete first level",
			"achievement_combo": "Combo Master",
			"achievement_combo_desc": "Make a combo of 5+ bubbles",
			"achievement_score_1000": "1000 Points",
			"achievement_score_1000_desc": "Score 1000 points",
			"achievement_sharpshooter": "Sharpshooter",
			"achievement_sharpshooter_desc": "Make 100 shots",
			"achievement_perfect_aim": "Perfect Aim",
			"achievement_perfect_aim_desc": "Destroy 50 bubbles without missing",
			"achievement_score_5000": "5000 Points",
			"achievement_score_5000_desc": "Score 5000 points",
			
			# Leaderboard
			"leaderboard_title": "LEADERBOARD",
			"rank": "Rank",
			"player": "Player",
			"your_rank": "Your rank: {rank}",
			"no_data": "No data",
			"position": "Position",
			"name": "Name",
			"date": "Date",
			"view_full": "View Full",
			"enter_name": "Enter Name",
			"submit": "Submit",
			
			# Statistics
			"statistics": "Statistics",
			"total_games": "Total Games",
			"average_score": "Average Score",
			"best_score": "Best Score",
			"completion": "Completion",
			
			# Notifications
			"loading": "Loading...",
			"saving": "Saving...",
			"ad_loading": "Loading ad...",
			"ad_reward": "Reward received!",
			"connection_error": "Connection error",
			"try_again": "Try again",
			
			# Tutorial
			"tutorial_welcome": "Welcome!",
			"tutorial_aim": "Aim with mouse",
			"tutorial_shoot": "Click to shoot",
			"tutorial_match": "Match 3+ bubbles of same color",
			"tutorial_complete": "Great!",
			"skip": "Skip",
			
			# Boosters
			"booster_bomb": "Bomb",
			"booster_bomb_desc": "Explodes all nearby bubbles",
			"booster_color": "Rainbow",
			"booster_color_desc": "Matches any color",
			"booster_line": "Line",
			"booster_line_desc": "Removes entire row",
			
			# Pause menu
			"pause": "Pause",
			"resume": "Resume",
			"menu": "Menu",
			
			# Share
			"share_text": "I scored {score} points in Bubble Shooter! Can you beat my record?",
			"share_button": "Share",
			
			# Misc
			"new_high_score": "New High Score!",
			"combo": "Combo х{count}",
			"perfect": "Perfect!",
			"good": "Good!",
			"nice": "Nice!"
		}
	}
	
	print("I18N: Translations loaded for languages: ", SUPPORTED_LANGUAGES)

func detect_and_set_language():
	# Сначала проверяем сохраненный язык
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		var saved_lang = settings.get_language_code()
		if saved_lang in SUPPORTED_LANGUAGES:
			set_language(saved_lang)
			return
	
	# Если нет сохраненного, пробуем определить через GameReady
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		var platform_lang = game_api.get_platform_language()
		if platform_lang in SUPPORTED_LANGUAGES:
			set_language(platform_lang)
			return
	
	# Иначе используем системный язык
	var system_lang = OS.get_locale().split("_")[0]
	if system_lang in SUPPORTED_LANGUAGES:
		set_language(system_lang)
	else:
		set_language(DEFAULT_LANGUAGE)

func set_language(lang_code: String):
	if lang_code not in SUPPORTED_LANGUAGES:
		print("I18N: Unsupported language: ", lang_code, ", using default")
		lang_code = DEFAULT_LANGUAGE
	
	current_language = lang_code
	TranslationServer.set_locale(lang_code)
	language_changed.emit(lang_code)
	print("I18N: Language set to ", lang_code)

func get_language() -> String:
	return current_language

# Переименовано с tr в translate для избежания конфликта с встроенным методом
func translate(key: StringName, params: Dictionary = {}) -> String:
	if current_language not in translations:
		print("I18N: Warning - language not loaded: ", current_language)
		return key
	
	var lang_dict = translations[current_language]
	if key not in lang_dict:
		print("I18N: Warning - translation key not found: ", key)
		return key
	
	var text = lang_dict[key]
	
	# Подстановка параметров {param_name}
	for param_key in params.keys():
		var placeholder = "{" + param_key + "}"
		text = text.replace(placeholder, str(params[param_key]))
	
	return text

func get_available_languages() -> Array:
	return SUPPORTED_LANGUAGES

func get_language_name(lang_code: String) -> String:
	return translate("lang_" + lang_code)

# Добавить новый перевод во время выполнения
func add_translation(lang_code: String, key: String, value: String):
	if lang_code not in translations:
		translations[lang_code] = {}
	
	translations[lang_code][key] = value

# Загрузить переводы из JSON файла
func load_translations_from_file(file_path: String):
	if not FileAccess.file_exists(file_path):
		print("I18N: Translation file not found: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			for lang in data.keys():
				if lang not in translations:
					translations[lang] = {}
				translations[lang].merge(data[lang])
			print("I18N: Loaded translations from file: ", file_path)
	else:
		print("I18N: Error parsing translation file: ", json.get_error_message())
