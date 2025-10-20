# main.gd - Полная переработка с нуля
extends Node2D

const BUBBLE = preload("res://bubble.tscn")
const BASE_RESOLUTION = Vector2(1280, 1136)

var screen_size: Vector2
var scale_factor: Vector2
var BUBBLE_RADIUS: float
var HEX_WIDTH: float
var HEX_HEIGHT: float
var COLS: int = 10
var ROWS: int = 14

var grid = []
var shooter_bubble = null
var next_bubble = null
var score = 0
var is_shooting = false
var game_over = false
var lives = 3
var high_score = 0
var bubbles_shot = 0
var total_matches = 0
var best_combo = 0
var consecutive_hits = 0

var shooter
var score_label
var high_score_label
var game_over_label
var restart_button
var ad_continue_button

@onready var background: TextureRect = $Background

const COLORS = [
	Color.RED, 
	Color.GREEN, 
	Color.YELLOW, 
	Color.MAGENTA, 
	Color.ORANGE, 
	Color(1, 0.5, 0.8)
]

func _ready():
	await get_tree().process_frame
	
	calculate_adaptive_sizes()
	initialize_grid()
	
	var save_data = SaveManager.load_game()
	if save_data:
		load_game_state(save_data)
	else:
		spawn_initial_bubbles()
	
	setup_shooter()
	setup_ui()
	
	spawn_shooter_bubble()
	spawn_next_bubble()
	
	update_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		i18n.language_changed.connect(_on_language_changed)
	
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("game_start", {"score": score})
		game_api.ad_completed.connect(_on_ad_completed)
		game_api.ad_failed.connect(_on_ad_failed)

func calculate_adaptive_sizes():
	screen_size = get_viewport_rect().size
	scale_factor = screen_size / BASE_RESOLUTION
	
	var min_scale = min(scale_factor.x, scale_factor.y)
	BUBBLE_RADIUS = 32 * min_scale
	HEX_HEIGHT = BUBBLE_RADIUS * 2
	HEX_WIDTH = sqrt(3) * BUBBLE_RADIUS
	
	COLS = max(8, int(screen_size.x / HEX_WIDTH))
	ROWS = max(10, int((screen_size.y * 0.6) / (HEX_HEIGHT * 0.75)))
	
	print("Grid size: ", COLS, "x", ROWS)

func _on_viewport_size_changed():
	calculate_adaptive_sizes()
	
	# Обновляем размер фона для адаптивности
	if background:
		background.size = screen_size
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	reposition_all_bubbles()
	reposition_ui()

func initialize_grid():
	grid = []
	for row in range(ROWS):
		grid.append([])
		for col in range(COLS):
			grid[row].append(null)

func spawn_initial_bubbles():
	var rows_to_fill = min(5, ROWS - 1)
	for row in range(rows_to_fill):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if randf() < 0.7:
				spawn_bubble_at(row, col)

func spawn_bubble_at(row: int, col: int, color: Color = Color.WHITE):
	if row < 0 or row >= ROWS or col < 0:
		return null
	
	var cols_in_row = COLS if row % 2 == 0 else COLS - 1
	if col >= cols_in_row:
		return null
	
	var bubble = BUBBLE.instantiate()
	add_child(bubble)
	
	var pos = get_grid_position(row, col)
	bubble.position = pos
	
	if color == Color.WHITE:
		bubble.set_color(COLORS[randi() % COLORS.size()])
	else:
		bubble.set_color(color)
	
	bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0)
	
	if row < grid.size() and col < grid[row].size():
		grid[row][col] = bubble
	
	return bubble

func get_grid_position(row: int, col: int) -> Vector2:
	var x_offset = (HEX_WIDTH / 2) if row % 2 == 1 else 0
	var x = col * HEX_WIDTH + x_offset + HEX_WIDTH / 2 + 20
	var y = row * (HEX_HEIGHT * 0.75) + HEX_HEIGHT / 2 + 100
	return Vector2(x, y)

func grid_position_from_world(world_pos: Vector2) -> Vector2i:
	var adjusted_y = world_pos.y - 100
	var row = int(adjusted_y / (HEX_HEIGHT * 0.75))
	row = clamp(row, 0, ROWS - 1)
	
	var x_offset = (HEX_WIDTH / 2) if row % 2 == 1 else 0
	var adjusted_x = world_pos.x - x_offset - 20
	var col = int(adjusted_x / HEX_WIDTH)
	
	var cols_in_row = COLS if row % 2 == 0 else COLS - 1
	col = clamp(col, 0, cols_in_row - 1)
	
	return Vector2i(row, col)

func setup_shooter():
	shooter = Node2D.new()
	shooter.name = "Shooter"
	shooter.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	add_child(shooter)

func setup_ui():
	var ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	
	var i18n = get_node_or_null("/root/I18nManager")
	var min_scale = min(scale_factor.x, scale_factor.y)
	
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", int(32 * min_scale))
	score_label.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(score_label)
	
	high_score_label = Label.new()
	high_score_label.name = "HighScoreLabel"
	high_score_label.position = Vector2(20, 60)
	high_score_label.add_theme_font_size_override("font_size", int(24 * min_scale))
	high_score_label.add_theme_color_override("font_color", Color.YELLOW)
	ui.add_child(high_score_label)
	
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	# Исправлено: замена тернарного оператора на if-else
	var game_over_text: String
	if i18n:
		game_over_text = i18n.translate("game_over")
	else:
		game_over_text = "GAME OVER"
	game_over_label.text = game_over_text
	game_over_label.add_theme_font_size_override("font_size", int(48 * min_scale))
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.position = Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 50)
	game_over_label.size = Vector2(400, 100)
	game_over_label.visible = false
	ui.add_child(game_over_label)
	
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	# Исправлено: замена тернарного оператора на if-else
	var restart_text: String
	if i18n:
		restart_text = i18n.translate("restart")
	else:
		restart_text = "Restart"
	restart_button.text = restart_text
	restart_button.position = Vector2(screen_size.x / 2 - 75, screen_size.y / 2 + 150)
	restart_button.size = Vector2(150, 50)
	restart_button.visible = false
	restart_button.add_theme_font_size_override("font_size", int(24 * min_scale))
	restart_button.pressed.connect(_on_restart_pressed)
	ui.add_child(restart_button)
	
	ad_continue_button = Button.new()
	ad_continue_button.name = "AdContinueButton"
	# Исправлено: замена тернарного оператора на if-else
	var continue_text: String
	if i18n:
		continue_text = i18n.translate("continue_ad")
	else:
		continue_text = "Continue (ad)"
	ad_continue_button.text = continue_text
	ad_continue_button.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 2 + 100)
	ad_continue_button.size = Vector2(200, 50)
	ad_continue_button.visible = false
	ad_continue_button.add_theme_font_size_override("font_size", int(20 * min_scale))
	ad_continue_button.pressed.connect(_on_ad_continue_pressed)
	ui.add_child(ad_continue_button)

func spawn_shooter_bubble():
	if shooter_bubble:
		shooter_bubble.queue_free()
	
	shooter_bubble = BUBBLE.instantiate()
	add_child(shooter_bubble)
	shooter_bubble.position = shooter.position
	shooter_bubble.set_color(COLORS[randi() % COLORS.size()])
	shooter_bubble.is_shooter = true
	shooter_bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0)

func spawn_next_bubble():
	if next_bubble:
		next_bubble.queue_free()
	
	next_bubble = BUBBLE.instantiate()
	add_child(next_bubble)
	next_bubble.position = Vector2(shooter.position.x + 80, shooter.position.y)
	next_bubble.set_color(COLORS[randi() % COLORS.size()])
	next_bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0 * 0.8)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_shooting and not game_over and shooter_bubble:
			shoot_bubble()

func shoot_bubble():
	is_shooting = true
	bubbles_shot += 1
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - shooter.position).normalized()
	
	# Ограничиваем угол выстрела, чтобы не стрелять вниз
	if direction.y > 0:
		direction.y = -0.1  # Минимальный угол вверх
	
	shooter_bubble.shoot(direction)
	
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api and SettingsManager.vibration_enabled:
		game_api.vibrate(50)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_bubble_shoot()

func _process(_delta):
	if is_shooting and shooter_bubble:
		check_bubble_collision()
		check_wall_collision()
		
		# Проверяем, не улетел ли пузырь за пределы экрана
		if shooter_bubble.position.y < -100:
			reset_shooter_bubble()

func reset_shooter_bubble():
	# Если пузырь улетел за пределы, сбрасываем его
	if shooter_bubble:
		shooter_bubble.queue_free()
		shooter_bubble = null
	
	is_shooting = false
	spawn_shooter_bubble()

func check_wall_collision():
	if not shooter_bubble:
		return
	
	if shooter_bubble.position.x - BUBBLE_RADIUS < 20:
		shooter_bubble.velocity.x = abs(shooter_bubble.velocity.x)
		shooter_bubble.position.x = 20 + BUBBLE_RADIUS
	elif shooter_bubble.position.x + BUBBLE_RADIUS > screen_size.x - 20:
		shooter_bubble.velocity.x = -abs(shooter_bubble.velocity.x)
		shooter_bubble.position.x = screen_size.x - 20 - BUBBLE_RADIUS

func check_bubble_collision():
	if not shooter_bubble:
		return
	
	# Проверка столкновения с верхней границей
	if shooter_bubble.position.y - BUBBLE_RADIUS < 100:
		snap_bubble_to_grid()
		return
	
	# Проверка столкновения с другими пузырями
	for row in range(ROWS):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if row < grid.size() and col < grid[row].size() and grid[row][col]:
				var distance = shooter_bubble.position.distance_to(grid[row][col].position)
				if distance < BUBBLE_RADIUS * 1.9:  # Увеличили расстояние для лучшего определения столкновения
					snap_bubble_to_grid()
					return

func snap_bubble_to_grid():
	if not shooter_bubble:
		return
	
	shooter_bubble.stop()
	is_shooting = false
	
	var grid_pos = grid_position_from_world(shooter_bubble.position)
	var row = grid_pos.x
	var col = grid_pos.y
	
	if row >= ROWS:
		end_game()
		return
	
	# Находим ближайшую свободную позицию
	if row < grid.size() and col < grid[row].size() and grid[row][col] != null:
		var neighbors = get_hex_neighbors(row, col)
		var found = false
		for neighbor in neighbors:
			var n_row = neighbor.x
			var n_col = neighbor.y
			if n_row >= 0 and n_row < ROWS:
				var cols_in_row = COLS if n_row % 2 == 0 else COLS - 1
				if n_col >= 0 and n_col < cols_in_row and grid[n_row][n_col] == null:
					row = n_row
					col = n_col
					found = true
					break
		
		if not found:
			# Если не нашли соседей, ищем любую свободную позицию в верхних рядах
			for r in range(ROWS):
				var cols_in_r = COLS if r % 2 == 0 else COLS - 1
				for c in range(cols_in_r):
					if grid[r][c] == null:
						row = r
						col = c
						found = true
						break
				if found:
					break
	
	# Размещаем пузырь в сетке
	if row < grid.size() and col < grid[row].size():
		shooter_bubble.position = get_grid_position(row, col)
		grid[row][col] = shooter_bubble
		
		var matches = find_matches(row, col, shooter_bubble.color)
		if matches.size() >= 3:
			remove_bubbles(matches)
			score += matches.size() * 10
			total_matches += 1
			best_combo = max(best_combo, matches.size())
			consecutive_hits += 1
			
			check_floating_bubbles()
			check_achievements()
			
			var audio = get_node_or_null("/root/AudioManager")
			if audio:
				audio.play_match()
			
			var game_api = get_node_or_null("/root/GameReadyAPI")
			if game_api:
				if SettingsManager.vibration_enabled:
					game_api.vibrate(100)
				if matches.size() >= 5:
					game_api.send_analytics_event("combo", {"size": matches.size()})
		else:
			consecutive_hits = 0
	
	# Переходим к следующему пузырю
	shooter_bubble = next_bubble
	if shooter_bubble:
		shooter_bubble.position = shooter.position
		shooter_bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0)
		shooter_bubble.is_shooter = true
	
	spawn_next_bubble()
	update_ui()
	check_win_condition()
	SaveManager.save_game(get_save_data())

func get_hex_neighbors(row: int, col: int) -> Array:
	var neighbors = []
	var offsets = []
	
	if row % 2 == 0:
		offsets = [
			Vector2i(-1, -1), Vector2i(-1, 0),
			Vector2i(0, -1), Vector2i(0, 1),
			Vector2i(1, -1), Vector2i(1, 0)
		]
	else:
		offsets = [
			Vector2i(-1, 0), Vector2i(-1, 1),
			Vector2i(0, -1), Vector2i(0, 1),
			Vector2i(1, 0), Vector2i(1, 1)
		]
	
	for offset in offsets:
		var new_row = row + offset.x
		var new_col = col + offset.y
		if new_row >= 0 and new_row < ROWS:
			var cols_in_row = COLS if new_row % 2 == 0 else COLS - 1
			if new_col >= 0 and new_col < cols_in_row:
				neighbors.append(Vector2i(new_row, new_col))
	
	return neighbors

func find_matches(row: int, col: int, color: Color) -> Array:
	var matches = []
	var visited = {}
	var queue = [Vector2i(row, col)]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var key = str(current)
		
		if visited.has(key):
			continue
		visited[key] = true
		
		var r = current.x
		var c = current.y
		
		if r < 0 or r >= ROWS:
			continue
		
		var cols_in_row = COLS if r % 2 == 0 else COLS - 1
		if c < 0 or c >= cols_in_row or grid[r][c] == null:
			continue
		
		if grid[r][c].color.is_equal_approx(color):
			matches.append(Vector2i(r, c))
			for neighbor in get_hex_neighbors(r, c):
				queue.append(neighbor)
	
	return matches

func remove_bubbles(positions: Array):
	for pos in positions:
		var row = pos.x
		var col = pos.y
		if row < ROWS:
			var cols_in_row = COLS if row % 2 == 0 else COLS - 1
			if col < cols_in_row and grid[row][col]:
				grid[row][col].queue_free()
				grid[row][col] = null

func check_floating_bubbles():
	var connected = {}
	var queue = []
	
	for col in range(COLS):
		if grid[0][col] != null:
			queue.append(Vector2i(0, col))
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var key = str(current)
		
		if connected.has(key):
			continue
		connected[key] = true
		
		for neighbor in get_hex_neighbors(current.x, current.y):
			var n_row = neighbor.x
			var n_col = neighbor.y
			if n_row >= 0 and n_row < ROWS:
				var cols_in_row = COLS if n_row % 2 == 0 else COLS - 1
				if n_col >= 0 and n_col < cols_in_row and grid[n_row][n_col] != null:
					queue.append(Vector2i(n_row, n_col))
	
	var floating = []
	for row in range(ROWS):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if grid[row][col] != null and not connected.has(str(Vector2i(row, col))):
				floating.append(Vector2i(row, col))
	
	if floating.size() > 0:
		remove_bubbles(floating)
		score += floating.size() * 20

func check_win_condition():
	var has_bubbles = false
	for row in range(ROWS):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if grid[row][col] != null:
				has_bubbles = true
				break
		if has_bubbles:
			break
	
	if not has_bubbles:
		spawn_initial_bubbles()
		score += 100
		
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_win()
		
		var game_api = get_node_or_null("/root/GameReadyAPI")
		if game_api:
			game_api.send_analytics_event("level_complete", {"score": score})

func check_achievements():
	var achievement_mgr = get_node_or_null("/root/AchievementManager")
	if not achievement_mgr:
		return
	
	if score >= 1000 and not achievement_mgr.is_unlocked("score_1000"):
		achievement_mgr.unlock("score_1000")
	if score >= 5000 and not achievement_mgr.is_unlocked("score_5000"):
		achievement_mgr.unlock("score_5000")
	
	if total_matches >= 1 and not achievement_mgr.is_unlocked("first_win"):
		achievement_mgr.unlock("first_win")
	
	if best_combo >= 5 and not achievement_mgr.is_unlocked("combo_master"):
		achievement_mgr.unlock("combo_master")
	
	if bubbles_shot >= 100 and not achievement_mgr.is_unlocked("sharpshooter"):
		achievement_mgr.unlock("sharpshooter")
	
	if consecutive_hits >= 50 and not achievement_mgr.is_unlocked("perfect_aim"):
		achievement_mgr.unlock("perfect_aim")

func update_leaderboard():
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr:
		leaderboard_mgr.submit_score(score)

func end_game():
	var i18n = get_node_or_null("/root/I18nManager")
	
	if lives > 0:
		var continue_text: String
		var lives_text: String
		
		if i18n:
			continue_text = i18n.translate("continue_question")
			lives_text = i18n.translate("lives_left")
		else:
			continue_text = "CONTINUE?"
			lives_text = "Lives left: "
			
		game_over_label.text = continue_text + "\n" + lives_text + str(lives)
		game_over_label.visible = true
		ad_continue_button.visible = true
		restart_button.visible = true
	else:
		game_over = true
		var game_over_text: String
		if i18n:
			game_over_text = i18n.translate("game_over_score")
		else:
			game_over_text = "GAME OVER! Score: "
			
		game_over_label.text = game_over_text + str(score)
		game_over_label.visible = true
		restart_button.visible = true
		ad_continue_button.visible = false
		
		if score > high_score:
			high_score = score
			update_leaderboard()
		
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_lose()
		
		var game_api = get_node_or_null("/root/GameReadyAPI")
		if game_api:
			game_api.send_analytics_event("game_over", {"score": score, "lives": lives})

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_ad_continue_pressed():
	var game_api = get_node_or_null("/root/GameReadyAPI")
	var audio = get_node_or_null("/root/AudioManager")
	var i18n = get_node_or_null("/root/I18nManager")
	
	if audio:
		audio.stop_music()
	
	if game_api:
		ad_continue_button.disabled = true
		if i18n:
			ad_continue_button.text = i18n.translate("ad_loading")
		else:
			ad_continue_button.text = "Loading ad..."
		
		game_api.show_rewarded_ad()
	else:
		_on_rewarded_ad_completed()

func _on_ad_completed():
	var audio = get_node_or_null("/root/AudioManager")
	if audio and SettingsManager.music_enabled:
		audio.play_music()

func _on_ad_failed():
	var audio = get_node_or_null("/root/AudioManager")
	if audio and SettingsManager.music_enabled:
		audio.play_music()
	
	ad_continue_button.disabled = false
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		ad_continue_button.text = i18n.translate("continue_ad")
	else:
		ad_continue_button.text = "Continue (ad)"

func _on_rewarded_ad_completed():
	lives -= 1
	game_over_label.visible = false
	ad_continue_button.visible = false
	restart_button.visible = false
	ad_continue_button.disabled = false
	
	var i18n = get_node_or_null("/root/I18nManager")
	if i18n:
		ad_continue_button.text = i18n.translate("continue_ad")
	else:
		ad_continue_button.text = "Continue (ad)"
	
	for row in range(max(0, ROWS - 3), ROWS):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if row < grid.size() and col < grid[row].size() and grid[row][col]:
				grid[row][col].queue_free()
				grid[row][col] = null
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio and SettingsManager.music_enabled:
		audio.play_music()
	
	update_ui()

func update_ui():
	var i18n = get_node_or_null("/root/I18nManager")
	if score_label:
		var score_text: String
		if i18n:
			score_text = i18n.translate("score")
		else:
			score_text = "Score"
		score_label.text = score_text + ": " + str(score)
	if high_score_label:
		high_score_label.text = "Best: " + str(high_score)

func _on_language_changed(_new_language: String):
	update_ui()

func reposition_all_bubbles():
	for row in range(ROWS):
		var cols_in_row = COLS if row % 2 == 0 else COLS - 1
		for col in range(cols_in_row):
			if row < grid.size() and col < grid[row].size() and grid[row][col]:
				grid[row][col].position = get_grid_position(row, col)
				grid[row][col].set_bubble_scale(BUBBLE_RADIUS / 64.0)
	
	if shooter:
		shooter.position = Vector2(screen_size.x / 2, screen_size.y - 100)
	
	if shooter_bubble:
		shooter_bubble.position = shooter.position
		shooter_bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0)
	
	if next_bubble:
		next_bubble.position = Vector2(shooter.position.x + 80, shooter.position.y)
		next_bubble.set_bubble_scale(BUBBLE_RADIUS / 64.0 * 0.8)

func reposition_ui():
	if score_label:
		score_label.position = Vector2(20, 20)
	if high_score_label:
		high_score_label.position = Vector2(20, 60)
	if game_over_label:
		game_over_label.position = Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 50)
	if restart_button:
		restart_button.position = Vector2(screen_size.x / 2 - 75, screen_size.y / 2 + 150)
	if ad_continue_button:
		ad_continue_button.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 2 + 100)

func get_save_data() -> Dictionary:
	return {
		"score": score,
		"high_score": high_score,
		"lives": lives,
		"bubbles_shot": bubbles_shot,
		"total_matches": total_matches,
		"best_combo": best_combo,
		"consecutive_hits": consecutive_hits
	}

func load_game_state(save_data: Dictionary):
	score = save_data.get("score", 0)
	high_score = save_data.get("high_score", 0)
	lives = save_data.get("lives", 3)
	bubbles_shot = save_data.get("bubbles_shot", 0)
	total_matches = save_data.get("total_matches", 0)
	best_combo = save_data.get("best_combo", 0)
	consecutive_hits = save_data.get("consecutive_hits", 0)

func _on_leaderboard_pressed():
	get_tree().change_scene_to_file("res://leaderboard.tscn")
	
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("leaderboard_opened")

func _on_achievements_pressed():
	get_tree().change_scene_to_file("res://achievements.tscn")
	
	var game_api = get_node_or_null("/root/GameReadyAPI")
	if game_api:
		game_api.send_analytics_event("achievements_opened")
