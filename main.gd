# main_new.gd - Полностью переработанная версия Bubble Shooter
extends Node2D

# Предзагрузка сцены пузыря
const BUBBLE_SCENE = preload("res://bubble.tscn")

# Константы игры
const GRID_ROWS = 12
const GRID_COLS = 9
const BUBBLE_SIZE = 60.0
const HEX_OFFSET = 0.866  # sqrt(3)/2 для гексагональной сетки
const MIN_MATCH = 3
const SHOOT_SPEED = 800.0

# Цвета пузырей
const BUBBLE_COLORS = [
	Color.RED,
	Color.GREEN,
	Color.YELLOW,
	Color.CYAN,
	Color.MAGENTA,
	Color.ORANGE
]

# Игровые переменные
var grid = []  # 2D массив для хранения пузырей
var current_bubble = null  # Текущий пузырь для стрельбы
var next_bubble = null  # Следующий пузырь
var is_shooting = false
var score = 0
var game_over = false

# UI элементы
var shooter_pos: Vector2
var ui_layer: CanvasLayer
var score_label: Label
var game_over_label: Label
@onready var background: TextureRect = $Background

func _ready():
	print("Initializing Bubble Shooter...")
	setup_game()
	create_ui()
	initialize_grid()
	spawn_initial_bubbles()
	create_shooter_bubble()
	
	# Подключаем обработчик изменения размера окна для адаптивности
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func setup_game():
	# Настройка размера окна и позиции стрелка
	var screen_size = get_viewport().get_visible_rect().size
	shooter_pos = Vector2(screen_size.x / 2, screen_size.y - 100)
	
	# Настраиваем фон для адаптивности
	if background:
		background.size = screen_size
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func create_ui():
	# Создаем слой UI
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Счет
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(score_label)
	
	# Game Over текст
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 
									   get_viewport().get_visible_rect().size.y / 2)
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.visible = false
	ui_layer.add_child(game_over_label)

func initialize_grid():
	# Создаем пустую сетку
	grid = []
	for row in range(GRID_ROWS):
		var row_array = []
		var cols = GRID_COLS - (row % 2)  # Четные ряды имеют на 1 пузырь меньше
		for col in range(cols):
			row_array.append(null)
		grid.append(row_array)
	print("Grid initialized: ", GRID_ROWS, "x", GRID_COLS)

func spawn_initial_bubbles():
	# Заполняем первые 5 рядов случайными пузырями
	for row in range(min(5, GRID_ROWS)):
		var cols = GRID_COLS - (row % 2)
		for col in range(cols):
			if randf() > 0.2:  # 80% шанс появления пузыря
				var bubble = create_bubble_at(row, col)
				if bubble:
					bubble.color = BUBBLE_COLORS[randi() % BUBBLE_COLORS.size()]
					bubble.update_appearance()

func create_bubble_at(row: int, col: int) -> Node2D:
	# Проверка границ
	if row < 0 or row >= GRID_ROWS:
		print("ERROR: Row ", row, " out of bounds (0-", GRID_ROWS-1, ")")
		return null
		
	var cols_in_row = GRID_COLS - (row % 2)
	if col < 0 or col >= cols_in_row:
		print("ERROR: Col ", col, " out of bounds for row ", row, " (0-", cols_in_row-1, ")")
		return null
	
	# Создаем пузырь
	var bubble = BUBBLE_SCENE.instantiate()
	add_child(bubble)
	
	# Устанавливаем позицию
	var pos = get_grid_position(row, col)
	bubble.position = pos
	
	# Сохраняем в сетке
	grid[row][col] = bubble
	
	return bubble

func get_grid_position(row: int, col: int) -> Vector2:
	# Вычисляем позицию для гексагональной сетки
	var x_offset = (BUBBLE_SIZE / 2) if (row % 2 == 1) else 0
	var x = col * BUBBLE_SIZE + x_offset + BUBBLE_SIZE
	var y = row * BUBBLE_SIZE * HEX_OFFSET + BUBBLE_SIZE
	return Vector2(x, y)

func create_shooter_bubble():
	# Создаем пузырь для стрельбы
	if current_bubble:
		current_bubble.queue_free()
	
	current_bubble = BUBBLE_SCENE.instantiate()
	add_child(current_bubble)
	current_bubble.position = shooter_pos
	current_bubble.color = BUBBLE_COLORS[randi() % BUBBLE_COLORS.size()]
	current_bubble.update_appearance()
	current_bubble.is_shooter = true
	
	# Создаем следующий пузырь
	if next_bubble:
		next_bubble.queue_free()
	
	next_bubble = BUBBLE_SCENE.instantiate()
	add_child(next_bubble)
	next_bubble.position = shooter_pos + Vector2(100, 0)
	next_bubble.color = BUBBLE_COLORS[randi() % BUBBLE_COLORS.size()]
	next_bubble.update_appearance()
	next_bubble.scale = Vector2(0.7, 0.7)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not is_shooting and not game_over:
			shoot_bubble()

func shoot_bubble():
	if not current_bubble:
		return
	
	is_shooting = true
	
	# Вычисляем направление к мыши
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - shooter_pos).normalized()
	
	# Не позволяем стрелять вниз
	if direction.y > -0.1:
		direction.y = -0.1
		direction = direction.normalized()
	
	# Запускаем пузырь
	current_bubble.velocity = direction * SHOOT_SPEED
	current_bubble.is_moving = true
	
	print("Shooting bubble in direction: ", direction)

func _process(delta):
	if not is_shooting or not current_bubble:
		return
	
	# Проверяем столкновения со стенами
	if current_bubble.position.x <= BUBBLE_SIZE / 2:
		current_bubble.position.x = BUBBLE_SIZE / 2
		current_bubble.velocity.x = abs(current_bubble.velocity.x)
		
	if current_bubble.position.x >= get_viewport().get_visible_rect().size.x - BUBBLE_SIZE / 2:
		current_bubble.position.x = get_viewport().get_visible_rect().size.x - BUBBLE_SIZE / 2
		current_bubble.velocity.x = -abs(current_bubble.velocity.x)
	
	# Проверяем достижение верхней границы
	if current_bubble.position.y <= BUBBLE_SIZE:
		attach_bubble()
		return
	
	# Проверяем столкновения с другими пузырями
	for row in range(GRID_ROWS):
		var cols = GRID_COLS - (row % 2)
		for col in range(cols):
			if grid[row][col] != null:
				var distance = current_bubble.position.distance_to(grid[row][col].position)
				if distance < BUBBLE_SIZE * 0.9:
					print("Collision detected at row=", row, " col=", col, " distance=", distance)
					attach_bubble()
					return

func attach_bubble():
	if not current_bubble:
		return
		
	print("Attaching bubble at position: ", current_bubble.position)
	
	# Останавливаем пузырь
	current_bubble.is_moving = false
	current_bubble.velocity = Vector2.ZERO
	is_shooting = false
	
	# Находим ближайшую позицию в сетке
	var best_row = -1
	var best_col = -1
	var min_distance = INF
	
	for row in range(GRID_ROWS):
		var cols = GRID_COLS - (row % 2)
		for col in range(cols):
			if grid[row][col] == null:
				var grid_pos = get_grid_position(row, col)
				var distance = current_bubble.position.distance_to(grid_pos)
				if distance < min_distance:
					min_distance = distance
					best_row = row
					best_col = col
	
	# Проверяем, нашли ли мы валидную позицию
	if best_row == -1 or best_col == -1:
		print("ERROR: Could not find valid grid position!")
		game_over = true
		show_game_over()
		return
	
	print("Placing bubble at grid position: row=", best_row, " col=", best_col)
	
	# Помещаем пузырь в сетку
	current_bubble.position = get_grid_position(best_row, best_col)
	grid[best_row][best_col] = current_bubble
	
	# Проверяем совпадения
	var matches = find_matches(best_row, best_col, current_bubble.color)
	if matches.size() >= MIN_MATCH:
		print("Found ", matches.size(), " matches!")
		remove_matches(matches)
		score += matches.size() * 10
		update_score()
		
		# Проверяем плавающие пузыри
		check_floating_bubbles()
	
	# Проверяем конец игры
	if best_row >= GRID_ROWS - 1:
		game_over = true
		show_game_over()
		return
	
	# Создаем новый пузырь для стрельбы
	current_bubble = next_bubble
	if current_bubble:
		current_bubble.position = shooter_pos
		current_bubble.scale = Vector2(1, 1)
		current_bubble.is_shooter = true
	
	create_shooter_bubble()

func find_matches(start_row: int, start_col: int, color: Color) -> Array:
	var matches = []
	var checked = {}
	var to_check = [[start_row, start_col]]
	
	while to_check.size() > 0:
		var current = to_check.pop_back()
		var row = current[0]
		var col = current[1]
		
		var key = str(row) + "," + str(col)
		if checked.has(key):
			continue
			
		checked[key] = true
		
		# Проверяем границы
		if row < 0 or row >= GRID_ROWS:
			continue
			
		var cols_in_row = GRID_COLS - (row % 2)
		if col < 0 or col >= cols_in_row:
			continue
			
		# Проверяем существование и цвет пузыря
		if grid[row][col] == null:
			continue
			
		if not grid[row][col].color.is_equal_approx(color):
			continue
		
		matches.append([row, col])
		
		# Добавляем соседей для проверки
		var neighbors = get_neighbors(row, col)
		for neighbor in neighbors:
			to_check.append(neighbor)
	
	return matches

func get_neighbors(row: int, col: int) -> Array:
	var neighbors = []
	
	# Для гексагональной сетки соседи зависят от четности ряда
	if row % 2 == 0:
		# Четный ряд
		neighbors.append([row - 1, col - 1])
		neighbors.append([row - 1, col])
		neighbors.append([row, col - 1])
		neighbors.append([row, col + 1])
		neighbors.append([row + 1, col - 1])
		neighbors.append([row + 1, col])
	else:
		# Нечетный ряд
		neighbors.append([row - 1, col])
		neighbors.append([row - 1, col + 1])
		neighbors.append([row, col - 1])
		neighbors.append([row, col + 1])
		neighbors.append([row + 1, col])
		neighbors.append([row + 1, col + 1])
	
	return neighbors

func remove_matches(matches: Array):
	for match in matches:
		var row = match[0]
		var col = match[1]
		if grid[row][col] != null:
			grid[row][col].queue_free()
			grid[row][col] = null

func check_floating_bubbles():
	# Помечаем все пузыри, соединенные с верхним рядом
	var connected = {}
	
	# Начинаем с верхнего ряда
	for col in range(GRID_COLS):
		if grid[0][col] != null:
			mark_connected(0, col, connected)
	
	# Удаляем все несоединенные пузыри
	var floating_count = 0
	for row in range(GRID_ROWS):
		var cols = GRID_COLS - (row % 2)
		for col in range(cols):
			if grid[row][col] != null:
				var key = str(row) + "," + str(col)
				if not connected.has(key):
					grid[row][col].queue_free()
					grid[row][col] = null
					floating_count += 1
	
	if floating_count > 0:
		print("Removed ", floating_count, " floating bubbles")
		score += floating_count * 20
		update_score()

func mark_connected(row: int, col: int, connected: Dictionary):
	var key = str(row) + "," + str(col)
	if connected.has(key):
		return
		
	if row < 0 or row >= GRID_ROWS:
		return
		
	var cols_in_row = GRID_COLS - (row % 2)
	if col < 0 or col >= cols_in_row:
		return
		
	if grid[row][col] == null:
		return
	
	connected[key] = true
	
	# Рекурсивно помечаем всех соседей
	var neighbors = get_neighbors(row, col)
	for neighbor in neighbors:
		mark_connected(neighbor[0], neighbor[1], connected)

func update_score():
	if score_label:
		score_label.text = "Score: " + str(score)

func show_game_over():
	if game_over_label:
		game_over_label.visible = true
	print("Game Over! Final score: ", score)

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_viewport_size_changed():
	# Обновляем размер фона при изменении размера окна
	var screen_size = get_viewport().get_visible_rect().size
	if background:
		background.size = screen_size
	
	# Обновляем позицию стрелка
	shooter_pos = Vector2(screen_size.x / 2, screen_size.y - 100)
	if current_bubble and not is_shooting:
		current_bubble.position = shooter_pos
	if next_bubble:
		next_bubble.position = shooter_pos + Vector2(100, 0)