extends Node

const SAVE_PATH = "user://save.dat"

func save_game(data: Dictionary):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

func load_game():
	if not has_save():
		return null
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return null

func has_save():
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
