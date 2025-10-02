extends Node
class_name PersistenceManager

# Save file settings
const SAVE_FILE_PATH = "user://yokai_save.json"
const BACKUP_FILE_PATH = "user://yokai_save_backup.json"

# Game state data
var current_save_data: Dictionary = {}

# References
var game_manager
var ai_system
var weather_system

func _ready():
	print("PersistenceManager: Initializing persistence system")
	
	# Get system references
	game_manager = get_node("../..")
	ai_system = get_node("../AISystem")
	weather_system = get_node("../../Weather")
	
	# Auto-save every 5 minutes
	var auto_save_timer = Timer.new()
	add_child(auto_save_timer)
	auto_save_timer.wait_time = 300.0  # 5 minutes
	auto_save_timer.timeout.connect(_auto_save)
	auto_save_timer.start()

func save_game_data() -> bool:
	print("PersistenceManager: Saving game data...")
	
	var save_data = _collect_save_data()
	
	# Create backup of existing save
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var existing_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if existing_file:
			var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.WRITE)
			if backup_file:
				backup_file.store_string(existing_file.get_as_text())
				backup_file.close()
			existing_file.close()
	
	# Save new data
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("PersistenceManager: Failed to open save file for writing")
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	save_file.store_string(json_string)
	save_file.close()
	
	current_save_data = save_data
	print("PersistenceManager: Game data saved successfully")
	return true

func load_game_data() -> Dictionary:
	print("PersistenceManager: Loading game data...")
	
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("PersistenceManager: No save file found, returning empty data")
		return {}
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		print("PersistenceManager: Failed to open save file for reading")
		return _try_load_backup()
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("PersistenceManager: Failed to parse save file, trying backup")
		return _try_load_backup()
	
	var save_data = json.data
	current_save_data = save_data
	
	print("PersistenceManager: Game data loaded successfully")
	return save_data

func _try_load_backup() -> Dictionary:
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		print("PersistenceManager: No backup file found")
		return {}
	
	var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	if backup_file == null:
		print("PersistenceManager: Failed to open backup file")
		return {}
	
	var json_string = backup_file.get_as_text()
	backup_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("PersistenceManager: Failed to parse backup file")
		return {}
	
	print("PersistenceManager: Loaded from backup file")
	return json.data

func _collect_save_data() -> Dictionary:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": _generate_session_id(),
		"game_time": 0.0,
		"npcs": {},
		"world_state": {},
		"conversation_history": {}
	}
	
	# Collect game manager data
	if game_manager:
		save_data.game_time = game_manager.game_time
		
		# Collect NPC data
		if game_manager.red_npc:
			save_data.npcs["red_npc"] = _collect_npc_data(game_manager.red_npc)
		
		if game_manager.blue_npc:
			save_data.npcs["blue_npc"] = _collect_npc_data(game_manager.blue_npc)
	
	# Collect weather data
	if weather_system:
		save_data.world_state = {
			"current_weather": weather_system.current_weather,
			"weather_timer": weather_system.weather_timer
		}
	
	# Collect conversation history
	if ai_system:
		save_data.conversation_history = {
			"red_npc": ai_system.get_conversation_history("red_npc"),
			"blue_npc": ai_system.get_conversation_history("blue_npc"),
			"shared_history": ai_system.shared_conversation_history
		}
	
	return save_data

func _collect_npc_data(npc) -> Dictionary:
	var npc_data = {
		"npc_id": npc.npc_id,
		"backstory": npc.backstory,
		"position": {
			"x": npc.position.x,
			"y": npc.position.y,
			"z": npc.position.z
		},
		"current_routine_phase": npc.current_routine_phase,
		"conversation_cooldown": npc.conversation_cooldown
	}
	
	return npc_data

func apply_save_data(save_data: Dictionary):
	print("PersistenceManager: Applying loaded save data...")
	
	if not save_data.has("npcs"):
		print("PersistenceManager: No NPC data in save file")
		return
	
	# Apply game time
	if save_data.has("game_time") and game_manager:
		game_manager.game_time = save_data.game_time
	
	# Apply NPC data
	var npc_data = save_data.npcs
	
	if npc_data.has("red_npc") and game_manager and game_manager.red_npc:
		_apply_npc_data(game_manager.red_npc, npc_data.red_npc)
	
	if npc_data.has("blue_npc") and game_manager and game_manager.blue_npc:
		_apply_npc_data(game_manager.blue_npc, npc_data.blue_npc)
	
	# Apply weather data
	if save_data.has("world_state") and weather_system:
		var world_state = save_data.world_state
		if world_state.has("current_weather"):
			weather_system.change_weather(world_state.current_weather)
		if world_state.has("weather_timer"):
			weather_system.weather_timer = world_state.weather_timer
	
	# Apply conversation history
	if save_data.has("conversation_history") and ai_system:
		var history = save_data.conversation_history
		if history.has("red_npc"):
			ai_system.conversation_history["red_npc"] = history.red_npc
		if history.has("blue_npc"):
			ai_system.conversation_history["blue_npc"] = history.blue_npc
		if history.has("shared_history"):
			ai_system.shared_conversation_history = history.shared_history
	
	print("PersistenceManager: Save data applied successfully")

func _apply_npc_data(npc, data: Dictionary):
	if data.has("backstory"):
		npc.backstory = data.backstory
		npc.load_backstory(data.backstory)
	
	if data.has("position"):
		var pos_data = data.position
		npc.position = Vector3(pos_data.x, pos_data.y, pos_data.z)
	
	if data.has("current_routine_phase"):
		npc.current_routine_phase = data.current_routine_phase
	
	if data.has("conversation_cooldown"):
		npc.conversation_cooldown = data.conversation_cooldown

func _generate_session_id() -> String:
	var time = Time.get_unix_time_from_system()
	var random = randi()
	return str(time) + "_" + str(random)

func _auto_save():
	print("PersistenceManager: Auto-saving...")
	save_game_data()

func delete_save_data() -> bool:
	print("PersistenceManager: Deleting save data...")
	
	var success = true
	
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var error = DirAccess.remove_absolute(SAVE_FILE_PATH)
		if error != OK:
			print("PersistenceManager: Failed to delete save file: ", error)
			success = false
	
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		var error = DirAccess.remove_absolute(BACKUP_FILE_PATH)
		if error != OK:
			print("PersistenceManager: Failed to delete backup file: ", error)
			success = false
	
	if success:
		current_save_data.clear()
		print("PersistenceManager: Save data deleted successfully")
	
	return success

func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func get_save_info() -> Dictionary:
	if not has_save_data():
		return {}
	
	var save_data = load_game_data()
	if save_data.is_empty():
		return {}
	
	return {
		"timestamp": save_data.get("timestamp", 0),
		"game_time": save_data.get("game_time", 0.0),
		"version": save_data.get("version", "unknown"),
		"npc_count": save_data.get("npcs", {}).size()
	}

func export_save_data(file_path: String) -> bool:
	"""Export save data to a specific file path for backup purposes"""
	var save_data = _collect_save_data()
	
	var export_file = FileAccess.open(file_path, FileAccess.WRITE)
	if export_file == null:
		print("PersistenceManager: Failed to create export file")
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	export_file.store_string(json_string)
	export_file.close()
	
	print("PersistenceManager: Save data exported to ", file_path)
	return true

func import_save_data(file_path: String) -> bool:
	"""Import save data from a specific file path"""
	if not FileAccess.file_exists(file_path):
		print("PersistenceManager: Import file does not exist")
		return false
	
	var import_file = FileAccess.open(file_path, FileAccess.READ)
	if import_file == null:
		print("PersistenceManager: Failed to open import file")
		return false
	
	var json_string = import_file.get_as_text()
	import_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("PersistenceManager: Failed to parse import file")
		return false
	
	var import_data = json.data
	
	# Save imported data as current save
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("PersistenceManager: Failed to save imported data")
		return false
	
	save_file.store_string(JSON.stringify(import_data, "\t"))
	save_file.close()
	
	print("PersistenceManager: Save data imported from ", file_path)
	return true
