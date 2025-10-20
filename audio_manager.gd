# audio_manager.gd (обновленная версия)
extends Node

var music_player: AudioStreamPlayer
var sound_player: AudioStreamPlayer
var sound_enabled: bool = true

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	sound_player = AudioStreamPlayer.new()
	sound_player.name = "SoundPlayer"
	sound_player.bus = "SFX"
	add_child(sound_player)
	
	var music_stream = load("res://assets/audio/music.mp3")
	if music_stream:
		music_player.stream = music_stream
		music_player.volume_db = -10
	
	# Ждем инициализации всех синглтонов
	await get_tree().process_frame
	
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		if settings.music_enabled:
			play_music()
		sound_enabled = settings.sound_enabled
	else:
		play_music()

func play_music():
	if music_player and not music_player.playing:
		music_player.play()

func stop_music():
	if music_player and music_player.playing:
		music_player.stop()

func set_volume(volume: float):
	if music_player:
		music_player.volume_db = linear_to_db(volume)

func get_volume() -> float:
	if music_player:
		return db_to_linear(music_player.volume_db)
	return 1.0

func set_sound_enabled(enabled: bool):
	sound_enabled = enabled

func play_sound(sound_name: String):
	if not sound_enabled or not sound_player:
		return
	
	var sound_path = "res://assets/audio/" + sound_name + ".wav"
	if FileAccess.file_exists(sound_path):
		var sound_stream = load(sound_path)
		if sound_stream:
			sound_player.stream = sound_stream
			sound_player.play()
	else:
		print("AudioManager: Sound not found - ", sound_path)

# Предустановленные звуки игры
func play_bubble_pop():
	play_sound("bubble_pop")

func play_bubble_shoot():
	play_sound("bubble_shoot")

func play_match():
	play_sound("match")

func play_win():
	play_sound("win")

func play_lose():
	play_sound("lose")

func play_button_click():
	play_sound("button_click")
