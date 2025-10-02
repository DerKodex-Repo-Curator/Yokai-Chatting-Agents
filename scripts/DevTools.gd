extends Control
class_name DevTools

# UI panels
var backstory_panel: Panel
var diagnostics_panel: Panel
var is_visible: bool = false

# UI components
var backstory_text: RichTextLabel
var diagnostics_text: RichTextLabel
var weather_controls: VBoxContainer

# References
var game_manager
var ai_system
var weather_system

func _ready():
	print("DevTools: Initializing development tools")
	
	# Get system references
	game_manager = get_node("/root/Main")
	ai_system = get_node("/root/Main/Systems/AISystem")
	weather_system = get_node("/root/Main/Weather")
	
	# Create UI
	_create_ui()
	
	# Start hidden
	visible = false

func _create_ui():
	# Main container
	var main_container = HBoxContainer.new()
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Backstory panel
	_create_backstory_panel(main_container)
	
	# Diagnostics panel
	_create_diagnostics_panel(main_container)
	
	# Weather controls
	_create_weather_controls(main_container)

func _create_backstory_panel(parent: Control):
	backstory_panel = Panel.new()
	parent.add_child(backstory_panel)
	backstory_panel.custom_minimum_size = Vector2(400, 600)
	
	var vbox = VBoxContainer.new()
	backstory_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "NPC Backstories"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Backstory text
	backstory_text = RichTextLabel.new()
	backstory_text.bbcode_enabled = true
	backstory_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(backstory_text)
	
	# Refresh button
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Backstories"
	refresh_btn.pressed.connect(_refresh_backstories)
	vbox.add_child(refresh_btn)

func _create_diagnostics_panel(parent: Control):
	diagnostics_panel = Panel.new()
	parent.add_child(diagnostics_panel)
	diagnostics_panel.custom_minimum_size = Vector2(400, 600)
	
	var vbox = VBoxContainer.new()
	diagnostics_panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "System Diagnostics"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Diagnostics text
	diagnostics_text = RichTextLabel.new()
	diagnostics_text.bbcode_enabled = true
	diagnostics_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(diagnostics_text)
	
	# Control buttons
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	var refresh_diag_btn = Button.new()
	refresh_diag_btn.text = "Refresh"
	refresh_diag_btn.pressed.connect(_refresh_diagnostics)
	button_container.add_child(refresh_diag_btn)
	
	var clear_history_btn = Button.new()
	clear_history_btn.text = "Clear AI History"
	clear_history_btn.pressed.connect(_clear_ai_history)
	button_container.add_child(clear_history_btn)

func _create_weather_controls(parent: Control):
	var weather_panel = Panel.new()
	parent.add_child(weather_panel)
	weather_panel.custom_minimum_size = Vector2(300, 600)
	
	weather_controls = VBoxContainer.new()
	weather_panel.add_child(weather_controls)
	weather_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weather_controls.add_theme_constant_override("separation", 10)
	
	# Title
	var title = Label.new()
	title.text = "Weather Controls"
	title.add_theme_font_size_override("font_size", 18)
	weather_controls.add_child(title)
	
	# Current weather display
	var current_weather_label = Label.new()
	current_weather_label.name = "CurrentWeatherLabel"
	current_weather_label.text = "Current: Sunny"
	weather_controls.add_child(current_weather_label)
	
	# Weather buttons
	var weather_types = ["sunny", "cloudy", "rainy", "windy"]
	for weather in weather_types:
		var btn = Button.new()
		btn.text = "Set " + weather.capitalize()
		btn.pressed.connect(_set_weather.bind(weather))
		weather_controls.add_child(btn)
	
	# Random weather button
	var random_btn = Button.new()
	random_btn.text = "Random Weather"
	random_btn.pressed.connect(_random_weather)
	weather_controls.add_child(random_btn)
	
	# NPC controls
	var npc_title = Label.new()
	npc_title.text = "NPC Controls"
	npc_title.add_theme_font_size_override("font_size", 16)
	weather_controls.add_child(npc_title)
	
	var trigger_conversation_btn = Button.new()
	trigger_conversation_btn.text = "Trigger Random Conversation"
	trigger_conversation_btn.pressed.connect(_trigger_random_conversation)
	weather_controls.add_child(trigger_conversation_btn)

func _process(delta):
	if is_visible:
		_update_diagnostics()

func toggle_visibility():
	is_visible = not is_visible
	visible = is_visible
	
	if is_visible:
		_refresh_backstories()
		_refresh_diagnostics()
		_update_weather_display()
	
	print("DevTools: ", "Shown" if is_visible else "Hidden")

func _refresh_backstories():
	if not backstory_text or not game_manager:
		return
	
	var content = "[color=yellow]NPC Backstories[/color]\n\n"
	
	# Red NPC
	if game_manager.red_npc and game_manager.red_npc.backstory:
		var backstory = game_manager.red_npc.backstory
		content += "[color=red]Red NPC - " + backstory.get("name", "Unknown") + "[/color]\n"
		content += "Personality: " + backstory.get("personality", "Unknown") + "\n"
		content += "Secret: " + backstory.get("secret", "Unknown") + "\n"
		content += "Relationship: " + backstory.get("relationship", "Unknown") + "\n"
		content += "Weather Preference: " + backstory.get("weather_preference", "Unknown") + "\n"
		content += "Favorite Location: " + backstory.get("favorite_location", "Unknown") + "\n\n"
	
	# Blue NPC
	if game_manager.blue_npc and game_manager.blue_npc.backstory:
		var backstory = game_manager.blue_npc.backstory
		content += "[color=blue]Blue NPC - " + backstory.get("name", "Unknown") + "[/color]\n"
		content += "Personality: " + backstory.get("personality", "Unknown") + "\n"
		content += "Secret: " + backstory.get("secret", "Unknown") + "\n"
		content += "Relationship: " + backstory.get("relationship", "Unknown") + "\n"
		content += "Weather Preference: " + backstory.get("weather_preference", "Unknown") + "\n"
		content += "Favorite Location: " + backstory.get("favorite_location", "Unknown") + "\n\n"
	
	# Recent conversations
	if ai_system:
		content += "[color=yellow]Recent Conversations[/color]\n"
		
		var red_history = ai_system.get_conversation_history("red_npc")
		if red_history.size() > 0:
			content += "[color=red]Red NPC Recent:[/color]\n"
			for entry in red_history.slice(-3):
				content += "- " + entry.message + "\n"
			content += "\n"
		
		var blue_history = ai_system.get_conversation_history("blue_npc")
		if blue_history.size() > 0:
			content += "[color=blue]Blue NPC Recent:[/color]\n"
			for entry in blue_history.slice(-3):
				content += "- " + entry.message + "\n"
	
	backstory_text.text = content

func _refresh_diagnostics():
	if not diagnostics_text:
		return
	
	var content = "[color=yellow]System Status[/color]\n\n"
	
	# Game time
	if game_manager:
		var game_time = game_manager.game_time
		var cycle_progress = fmod(game_time, 1200.0) / 1200.0 * 100.0
		content += "Game Time: " + str(int(game_time)) + "s\n"
		content += "Routine Cycle: " + str(int(cycle_progress)) + "%\n\n"
	
	# AI System status
	if ai_system:
		content += "[color=cyan]AI System[/color]\n"
		content += "Active Requests: " + str(ai_system.active_requests) + "\n"
		content += "Queued Requests: " + str(ai_system.request_queue.size()) + "\n"
		content += "Pending Requests: " + str(ai_system.pending_requests.size()) + "\n\n"
	
	# Weather system
	if weather_system:
		content += "[color=green]Weather System[/color]\n"
		content += "Current Weather: " + weather_system.current_weather.capitalize() + "\n"
		content += "Next Change In: " + str(int(weather_system.weather_timer)) + "s\n"
		content += "Wind Strength: " + str(weather_system.wind_strength) + "\n\n"
	
	# NPC status
	if game_manager:
		content += "[color=orange]NPC Status[/color]\n"
		
		if game_manager.red_npc:
			var npc = game_manager.red_npc
			var phase = npc.routine_phases[npc.current_routine_phase]
			content += "Red NPC: " + phase.name + " (" + str(npc.current_routine_phase) + "/6)\n"
			content += "Position: " + str(npc.position) + "\n"
			content += "Moving: " + str(npc.is_moving) + "\n"
		
		if game_manager.blue_npc:
			var npc = game_manager.blue_npc
			var phase = npc.routine_phases[npc.current_routine_phase]
			content += "Blue NPC: " + phase.name + " (" + str(npc.current_routine_phase) + "/6)\n"
			content += "Position: " + str(npc.position) + "\n"
			content += "Moving: " + str(npc.is_moving) + "\n"
	
	# Performance
	content += "\n[color=yellow]Performance[/color]\n"
	content += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	content += "Memory Usage: " + str(OS.get_static_memory_usage() / 1024 / 1024) + " MB\n"
	
	diagnostics_text.text = content

func _update_diagnostics():
	# Update diagnostics every few frames when visible
	if Engine.get_process_frames() % 30 == 0:  # Update every 30 frames
		_refresh_diagnostics()

func _update_weather_display():
	if weather_system and weather_controls:
		var label = weather_controls.get_node("CurrentWeatherLabel") as Label
		if label:
			label.text = "Current: " + weather_system.current_weather.capitalize()

func _set_weather(weather_type: String):
	if weather_system:
		weather_system.force_weather(weather_type)
		_update_weather_display()
		print("DevTools: Set weather to ", weather_type)

func _random_weather():
	if weather_system:
		var weather_types = ["sunny", "cloudy", "rainy", "windy"]
		var random_weather = weather_types[randi() % weather_types.size()]
		weather_system.force_weather(random_weather)
		_update_weather_display()
		print("DevTools: Random weather set to ", random_weather)

func _clear_ai_history():
	if ai_system:
		ai_system.clear_conversation_history()
		_refresh_backstories()
		print("DevTools: Cleared AI conversation history")

func _trigger_random_conversation():
	if not game_manager:
		return
	
	var npcs = [game_manager.red_npc, game_manager.blue_npc]
	var random_npc = npcs[randi() % npcs.size()]
	
	if random_npc:
		var context = {
			"type": "self_talk",
			"location": random_npc._get_current_location(),
			"thoughts": "random developer trigger"
		}
		random_npc.conversation_triggered.emit(random_npc, context)
		print("DevTools: Triggered conversation for ", random_npc.npc_id)

func _input(event):
	if event.is_action_pressed("toggle_dev_tools"):
		toggle_visibility()
	elif event.is_action_pressed("refresh_backstories") and is_visible:
		_refresh_backstories()
	elif event.is_action_pressed("refresh_diagnostics") and is_visible:
		_refresh_diagnostics()
