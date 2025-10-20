# gameready_api.gd - Обновленная версия с остановкой музыки
extends Node

signal initialized
signal ad_completed
signal ad_failed
signal rewarded_ad_completed
signal rewarded_ad_failed

var is_initialized: bool = false
var is_mobile: bool = false
var ad_in_progress: bool = false

func _ready():
	detect_platform()
	initialize()

func detect_platform():
	var os_name = OS.get_name()
	is_mobile = os_name in ["Android", "iOS"]
	print("GameReady: Platform detected - ", os_name, " (Mobile: ", is_mobile, ")")

func initialize():
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined'"):
			print("GameReady: Initializing web version...")
			JavaScriptBridge.eval("""
				if (typeof GameReady !== 'undefined') {
					GameReady.init({
						onReady: function() {
							console.log('GameReady initialized');
						},
						onError: function(error) {
							console.error('GameReady error:', error);
						}
					});
				}
			""")
			is_initialized = true
		else:
			print("GameReady: Web API not found, using fallback")
			is_initialized = true
	else:
		print("GameReady: Native version (fallback mode)")
		is_initialized = true
	
	initialized.emit()

func show_interstitial_ad():
	if ad_in_progress:
		print("GameReady: Ad already in progress")
		return
	
	if not is_initialized:
		print("GameReady: Not initialized, skipping ad")
		ad_failed.emit()
		return
	
	ad_in_progress = true
	pause_game_audio()
	
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.showAd === 'function'"):
			JavaScriptBridge.eval("""
				GameReady.showAd({
					onComplete: function() {
						console.log('Ad completed');
					},
					onError: function(error) {
						console.error('Ad error:', error);
					}
				});
			""")
			await get_tree().create_timer(3.0).timeout
			_on_ad_complete()
		else:
			print("GameReady: showAd not available")
			_on_ad_fail()
	else:
		print("GameReady: Showing interstitial ad (simulated)")
		await get_tree().create_timer(2.0).timeout
		_on_ad_complete()

func show_rewarded_ad():
	if ad_in_progress:
		print("GameReady: Ad already in progress")
		return
	
	if not is_initialized:
		print("GameReady: Not initialized, skipping rewarded ad")
		rewarded_ad_failed.emit()
		return
	
	ad_in_progress = true
	pause_game_audio()
	
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.showRewardedAd === 'function'"):
			JavaScriptBridge.eval("""
				GameReady.showRewardedAd({
					onComplete: function() {
						console.log('Rewarded ad completed');
					},
					onError: function(error) {
						console.error('Rewarded ad error:', error);
					}
				});
			""")
			await get_tree().create_timer(5.0).timeout
			_on_rewarded_ad_complete()
		else:
			print("GameReady: showRewardedAd not available")
			_on_rewarded_ad_fail()
	else:
		print("GameReady: Showing rewarded ad (simulated)")
		await get_tree().create_timer(3.0).timeout
		_on_rewarded_ad_complete()

func _on_ad_complete():
	ad_in_progress = false
	resume_game_audio()
	ad_completed.emit()

func _on_ad_fail():
	ad_in_progress = false
	resume_game_audio()
	ad_failed.emit()

func _on_rewarded_ad_complete():
	ad_in_progress = false
	resume_game_audio()
	rewarded_ad_completed.emit()

func _on_rewarded_ad_fail():
	ad_in_progress = false
	resume_game_audio()
	rewarded_ad_failed.emit()

func pause_game_audio():
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.stop_music()
	
	# Приглушить все звуки
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)

func resume_game_audio():
	var audio = get_node_or_null("/root/AudioManager")
	if audio and SettingsManager.music_enabled:
		audio.play_music()
	
	# Восстановить звуки
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

func save_cloud_data(data: Dictionary):
	if not is_initialized:
		print("GameReady: Not initialized, saving locally only")
		return
	
	if OS.has_feature("web"):
		var json_data = JSON.stringify(data)
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.saveData === 'function'"):
			var js_code = "GameReady.saveData(" + json_data + ");"
			JavaScriptBridge.eval(js_code)
			print("GameReady: Data saved to cloud")
		else:
			print("GameReady: saveData not available")
	else:
		print("GameReady: Cloud save (simulated)")

func load_cloud_data() -> Dictionary:
	if not is_initialized:
		print("GameReady: Not initialized, loading locally only")
		return {}
	
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.loadData === 'function'"):
			var result = JavaScriptBridge.eval("JSON.stringify(GameReady.loadData());")
			if result:
				var parsed = JSON.parse_string(str(result))
				if parsed:
					print("GameReady: Data loaded from cloud")
					return parsed
	
	print("GameReady: Cloud load failed or not available")
	return {}

func send_analytics_event(event_name: String, params: Dictionary = {}):
	if not is_initialized:
		return
	
	if OS.has_feature("web"):
		var json_params = JSON.stringify(params)
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.logEvent === 'function'"):
			var js_code = "GameReady.logEvent('" + event_name + "', " + json_params + ");"
			JavaScriptBridge.eval(js_code)
			print("GameReady: Analytics event sent - ", event_name)
	else:
		print("GameReady: Analytics event (simulated) - ", event_name, " params: ", params)

func request_review():
	if not is_initialized:
		return
	
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.requestReview === 'function'"):
			JavaScriptBridge.eval("GameReady.requestReview();")
			print("GameReady: Review requested")
	else:
		print("GameReady: Review request (simulated)")

func share_game(text: String = "", url: String = ""):
	if not is_initialized:
		return
	
	var i18n = get_node_or_null("/root/I18nManager")
	var share_text = text if text != "" else (i18n.tr("share_text") if i18n else "Play Bubble Shooter!")
	
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.share === 'function'"):
			var js_code = "GameReady.share({text: '" + share_text + "', url: '" + url + "'});"
			JavaScriptBridge.eval(js_code)
			print("GameReady: Share triggered")
	else:
		print("GameReady: Share (simulated) - ", share_text)

func is_ad_available() -> bool:
	if not is_initialized or ad_in_progress:
		return false
	
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("typeof GameReady !== 'undefined' && typeof GameReady.showAd === 'function'")
	
	return true

func get_platform_language() -> String:
	if OS.has_feature("web"):
		var lang = JavaScriptBridge.eval("navigator.language || navigator.userLanguage")
		if lang:
			return str(lang).split("-")[0]
	
	return OS.get_locale().split("_")[0]

func vibrate(duration_ms: int = 100):
	if not is_mobile:
		return
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (navigator.vibrate) navigator.vibrate(" + str(duration_ms) + ");")
	elif OS.get_name() == "Android":
		if Engine.has_singleton("JavaBridge"):
			var java_bridge = Engine.get_singleton("JavaBridge")
			java_bridge.vibrate(duration_ms)
	
	print("GameReady: Vibration triggered (", duration_ms, "ms)")
