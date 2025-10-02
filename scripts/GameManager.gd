extends Node3D
class_name GameManager

# Core game systems
@onready var weather_system = $Weather
@onready var ai_system = $Systems/AISystem
@onready var persistence_manager = $Systems/PersistenceManager
@onready var dev_tools = $UI/DevTools
@onready var conversation_display: RichTextLabel = $UI/ConversationPanel/ConversationContainer/ScrollContainer/ConversationDisplay
@onready var conversation_scroll: ScrollContainer = $UI/ConversationPanel/ConversationContainer/ScrollContainer
@onready var conversation_panel: Panel = $UI/ConversationPanel

# NPCs
var red_npc
var blue_npc

# Game state
var game_time: float = 0.0
var routine_cycle_time: float = 1200.0  # 20 minutes in seconds
var is_paused: bool = false

# Conversation turn system
var conversation_system = {
	"current_speaker": null,
	"awaiting_response": false,
	"target_npc": null,
	"last_speech_time": 0.0,
	"min_speech_interval": 1.0,  # 1 second minimum between any speech
	"response_timeout": 5.0      # Max time to wait for response
}

signal npc_conversation(npc_name: String, message: String)
signal weather_changed(weather_type: String)

func _ready():
	print("GameManager: Initializing Yokai-2.0 AI Village")
	
	# Connect signals
	npc_conversation.connect(_on_npc_conversation)
	weather_changed.connect(_on_weather_changed)
	
	# Initialize systems
	_setup_village()
	_create_npcs()
	_load_or_generate_backstories()
	
	print("GameManager: Initialization complete")
	
	# Display controls in conversation area
	_show_initial_controls()

func _process(delta):
	if not is_paused:
		game_time += delta
		
		# Update routine cycle (20-minute loop)
		var cycle_progress = fmod(game_time, routine_cycle_time) / routine_cycle_time
		_update_npc_routines(cycle_progress)
		
		# Update conversation turn system
		_update_conversation_system(delta)

func _setup_village():
	print("GameManager: Setting up village environment")
	
	# Create village objects
	var environment = $World/Environment
	
	# House A (Red NPC home) - moved to be more visible from player start
	var house_a = _create_placeholder_object("House_A", Vector3(-8, 1, -8), Vector3(4, 3, 4), Color.RED)
	environment.add_child(house_a)
	
	# House B (Blue NPC home) - moved to be more visible from player start  
	var house_b = _create_placeholder_object("House_B", Vector3(8, 1, -8), Vector3(4, 3, 4), Color.BLUE)
	environment.add_child(house_b)
	
	# Central well
	var well = _create_placeholder_object("Well", Vector3(0, 1, 0), Vector3(2, 2, 2), Color.GRAY)
	environment.add_child(well)
	
	# Shop
	var shop = _create_placeholder_object("Shop", Vector3(-10, 1, 10), Vector3(3, 3, 3), Color.YELLOW)
	environment.add_child(shop)
	
	# Benches
	var bench1 = _create_placeholder_object("Bench_1", Vector3(-5, 0.5, 5), Vector3(2, 1, 1), Color.BROWN)
	environment.add_child(bench1)
	
	var bench2 = _create_placeholder_object("Bench_2", Vector3(5, 0.5, -5), Vector3(2, 1, 1), Color.BROWN)
	environment.add_child(bench2)
	
	# Trees
	for i in range(6):
		var tree_pos = Vector3(
			randf_range(-20, 20),
			2,
			randf_range(-20, 20)
		)
		# Avoid placing trees too close to buildings
		if tree_pos.distance_to(Vector3.ZERO) > 5:
			var tree = _create_placeholder_object("Tree_" + str(i), tree_pos, Vector3(1, 4, 1), Color.GREEN)
			environment.add_child(tree)

func _create_placeholder_object(obj_name: String, position: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var obj = StaticBody3D.new()
	obj.name = obj_name
	obj.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	
	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	
	obj.add_child(mesh_instance)
	obj.add_child(collision_shape)
	
	return obj

func _create_npcs():
	print("GameManager: Creating NPCs")
	
	# Create Red NPC
	red_npc = CharacterBody3D.new()
	red_npc.set_script(preload("res://scripts/NPCController.gd"))
	red_npc.name = "RedNPC"
	red_npc.npc_id = "red_npc"
	red_npc.npc_name = "Red NPC"
	red_npc.npc_color = Color.RED
	red_npc.home_position = Vector3(-8, 1, -8)
	red_npc.position = red_npc.home_position
	$World/NPCs.add_child(red_npc)
	
	# Create Blue NPC
	blue_npc = CharacterBody3D.new()
	blue_npc.set_script(preload("res://scripts/NPCController.gd"))
	blue_npc.name = "BlueNPC"
	blue_npc.npc_id = "blue_npc"
	blue_npc.npc_name = "Blue NPC"
	blue_npc.npc_color = Color.BLUE
	blue_npc.home_position = Vector3(8, 1, -8)
	blue_npc.position = blue_npc.home_position
	$World/NPCs.add_child(blue_npc)
	
	# Connect NPC signals
	red_npc.conversation_triggered.connect(_on_npc_conversation_triggered)
	blue_npc.conversation_triggered.connect(_on_npc_conversation_triggered)

func _load_or_generate_backstories():
	print("GameManager: Loading or generating backstories")
	
	# Try to load existing backstories
	var save_data = persistence_manager.load_game_data()
	
	if save_data.has("npcs"):
		# Load existing backstories
		red_npc.load_backstory(save_data.npcs.get("red_npc", {}))
		blue_npc.load_backstory(save_data.npcs.get("blue_npc", {}))
	else:
		# Generate new backstories
		var backstory_manager = BackstoryManager.new()
		red_npc.backstory = backstory_manager.generate_backstory("red_npc")
		blue_npc.backstory = backstory_manager.generate_backstory("blue_npc")
		
		# Save the new backstories
		persistence_manager.save_game_data()

func _update_npc_routines(cycle_progress: float):
	if red_npc:
		red_npc.update_routine(cycle_progress)
	if blue_npc:
		blue_npc.update_routine(cycle_progress)

func _on_npc_conversation_triggered(npc, context: Dictionary):
	print("GameManager: NPC conversation triggered - ", npc.npc_id)
	
	# Check if this NPC can speak right now
	if not _can_npc_speak(npc, context):
		return
	
	# Set up conversation turn
	_start_conversation_turn(npc, context)
	
	ai_system.generate_conversation(npc, context)

func _on_npc_conversation(npc_name: String, message: String):
	print("Conversation - ", npc_name, ": ", message)
	
	# Display conversation in UI with enhanced formatting
	var color = "red" if npc_name.contains("Red") else "blue"
	var datetime_parts = Time.get_datetime_string_from_system().split(" ")
	var timestamp = datetime_parts[1].substr(0, 5) if datetime_parts.size() > 1 else Time.get_time_string_from_system().substr(0, 5)
	
	var formatted_message = "[color=gray][" + timestamp + "][/color] [color=" + color + "][b]" + npc_name + ":[/b][/color] " + message
	conversation_display.append_text(formatted_message + "\n")
	
	# Auto-scroll to bottom to show latest message
	call_deferred("_scroll_to_bottom")
	
	# Find which NPC spoke and handle turn completion
	var speaking_npc = red_npc if npc_name.contains("Red") else blue_npc
	if speaking_npc:
		_on_conversation_completed(speaking_npc)

func _on_weather_changed(weather_type: String):
	print("GameManager: Weather changed to ", weather_type)
	
	# Notify NPCs about weather change
	if red_npc:
		red_npc.on_weather_changed(weather_type)
	if blue_npc:
		blue_npc.on_weather_changed(weather_type)

func _input(event):
	if event.is_action_pressed("toggle_dev_tools"):
		dev_tools.toggle_visibility()
	elif event.is_action_pressed("toggle_pause"):
		is_paused = not is_paused
		print("Game ", "paused" if is_paused else "unpaused")
	elif event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_CTRL):
		# Ctrl+Escape to quit and save
		_quit_game()
	elif Input.is_key_pressed(KEY_Q) and Input.is_key_pressed(KEY_CTRL):
		# Ctrl+Q to quit and save
		_quit_game()
	elif event.is_action_pressed("toggle_fullscreen"):
		# F11 to toggle fullscreen
		_toggle_fullscreen()
	elif Input.is_action_just_pressed("ui_cancel") and not Input.is_key_pressed(KEY_CTRL):
		# Escape to toggle conversation panel visibility
		_toggle_conversation_panel()

func get_other_npc(current_npc):
	if current_npc == red_npc:
		return blue_npc
	else:
		return red_npc

func get_village_objects() -> Array:
	var objects = []
	for child in $World/Environment.get_children():
		objects.append({
			"name": child.name,
			"position": child.position,
			"type": _get_object_type(child.name)
		})
	return objects

func _get_object_type(obj_name: String) -> String:
	if obj_name.contains("House"):
		return "house"
	elif obj_name.contains("Well"):
		return "well"
	elif obj_name.contains("Shop"):
		return "shop"
	elif obj_name.contains("Bench"):
		return "bench"
	elif obj_name.contains("Tree"):
		return "tree"
	else:
		return "unknown"

# Conversation Turn System Functions

func _update_conversation_system(delta: float):
	# Check if we're waiting for a response and it's timed out
	if conversation_system.awaiting_response:
		conversation_system.response_timeout -= delta
		if conversation_system.response_timeout <= 0:
			print("GameManager: Response timeout, releasing conversation turn")
			_end_conversation_turn()

func _can_npc_speak(npc, context: Dictionary) -> bool:
	var current_time = Time.get_unix_time_from_system()
	
	# Check minimum time between any speech
	if current_time - conversation_system.last_speech_time < conversation_system.min_speech_interval:
		return false
	
	# If someone else is speaking, only allow if this is a response
	if conversation_system.current_speaker != null and conversation_system.current_speaker != npc:
		# Allow response if this NPC is the target and we're awaiting response
		if conversation_system.awaiting_response and conversation_system.target_npc == npc:
			return true
		else:
			return false
	
	# If this NPC is already speaking, don't allow overlapping
	if conversation_system.current_speaker == npc:
		return false
	
	return true

func _start_conversation_turn(npc, context: Dictionary):
	conversation_system.current_speaker = npc
	conversation_system.last_speech_time = Time.get_unix_time_from_system()
	
	# Check if this is directed at another NPC
	if context.has("type") and context.type == "npc_conversation":
		var other_npc = get_other_npc(npc)
		if other_npc:
			conversation_system.awaiting_response = true
			conversation_system.target_npc = other_npc
			conversation_system.response_timeout = 5.0
			print("GameManager: ", npc.npc_id, " speaking to ", other_npc.npc_id, " - awaiting response")
	else:
		conversation_system.awaiting_response = false
		conversation_system.target_npc = null

func _end_conversation_turn():
	conversation_system.current_speaker = null
	conversation_system.awaiting_response = false
	conversation_system.target_npc = null
	conversation_system.response_timeout = 5.0

func _on_conversation_completed(npc):
	# Called when a conversation is fully processed
	if conversation_system.current_speaker == npc:
		if not conversation_system.awaiting_response:
			_end_conversation_turn()
		# If awaiting response, keep the turn system active

func _show_initial_controls():
	# Show controls in the conversation display with better formatting
	var controls_text = "[center][color=yellow][b]Yokai Village - Floating Spirits[/b][/color][/center]\n"
	controls_text += "[color=gray]Controls: F1=Dev Tools | P=Pause | F11=Fullscreen | Ctrl+Q=Save & Quit[/color]\n"
	controls_text += "[color=gray]Mouse Wheel: Scroll chat | Escape: Toggle chat panel[/color]\n"
	controls_text += "[color=white]Watching floating spirits in the village...[/color]\n\n"
	conversation_display.text = controls_text

func _scroll_to_bottom():
	# Auto-scroll to show the latest conversation
	if conversation_scroll:
		conversation_scroll.scroll_vertical = conversation_scroll.get_v_scroll_bar().max_value

func _toggle_fullscreen():
	var window = get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
		print("GameManager: Switched to windowed mode")
	else:
		window.mode = Window.MODE_FULLSCREEN
		print("GameManager: Switched to fullscreen mode")

func _toggle_conversation_panel():
	if conversation_panel:
		conversation_panel.visible = not conversation_panel.visible
		var status = "shown" if conversation_panel.visible else "hidden"
		print("GameManager: Conversation panel ", status)

func _quit_game():
	print("GameManager: Saving game state before quit...")
	
	# Show saving message
	conversation_display.append_text("[color=yellow]Saving game state...[/color]\n")
	
	# Save current game state
	persistence_manager.save_game_data()
	
	print("GameManager: Game saved successfully. Goodbye!")
	conversation_display.append_text("[color=green]Game saved! Goodbye![/color]\n")
	
	# Wait a moment for the save to complete, then quit
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
