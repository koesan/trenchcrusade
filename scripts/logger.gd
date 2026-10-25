extends Node

## Professional Logging System for Trench Crusade
## Writes to both console and a local log file: user://game.log

var log_file: FileAccess

func _ready():
	log_file = FileAccess.open("user://game.log", FileAccess.WRITE)
	if not log_file:
		push_error("Logger: Failed to open log file at user://game.log")
	
	log_info("--- GAME STARTING / LOG INITIALIZED ---", "SYSTEM")
	
	if DisplayServer.get_name() != "headless":
		var custom_cursor = load("res://assets/textures/ui/maus_icon.png")
		if custom_cursor:
			Input.set_custom_mouse_cursor(custom_cursor)

func _exit_tree():
	if log_file:
		log_info("--- LOG CLOSED / GAME EXIT ---", "SYSTEM")
		log_file.close()

## Performans: dosya her satırda diske ZORLA yazılmaz (savaşta saniyede onlarca satır) —
## yalnız WARN/ERROR satırları anında flush edilir (çökme anında iz kalsın), gerisi tamponda
## birikir ve kapanışta yazılır. DEBUG satırları yayın sürümünde hiç üretilmez.
var _debug_enabled: bool = OS.is_debug_build()

func _log(message: String, category: String, level: String) -> void:
	if level == "DEBUG" and not _debug_enabled:
		return
	var time = Time.get_datetime_dict_from_system()
	var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [
		time.year, time.month, time.day,
		time.hour, time.minute, time.second
	]
	
	var log_line = "[%s] [%s] [%s] %s" % [time_str, level, category, message]
	
	# Write to console
	if level == "ERROR":
		printerr(log_line)
	else:
		print(log_line)
		
	# Write to file
	if log_file:
		log_file.store_line(log_line)
		if level == "ERROR" or level == "WARN":
			log_file.flush()

func log_info(message: String, category: String = "GAME") -> void:
	_log(message, category, "INFO")

func log_warn(message: String, category: String = "GAME") -> void:
	_log(message, category, "WARN")

func log_error(message: String, category: String = "GAME") -> void:
	_log(message, category, "ERROR")

func log_debug(message: String, category: String = "GAME") -> void:
	_log(message, category, "DEBUG")
