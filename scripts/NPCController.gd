extends CharacterBody3D
class_name NPCController

# NPC Identity
@export var npc_id: String = ""
@export var npc_color: Color = Color.WHITE
@export var npc_name: String = ""

# Movement settings
@export var move_speed: float = 2.0
@export var rotation_speed: float = 3.0

# Routine system
var home_position: Vector3
var current_routine_phase: int = 0
var routine_target: Vector3
var is_moving: bool = false
var move_timer: float = 0.0
var phase_timer: float = 0.0

# AI and conversation
var backstory: Dictionary = {}
var conversation_cooldown: float = 0.0
var last_conversation_time: float = 0.0
var conversation_range: float = 3.0

# Visual components
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

# Routine phases (20-minute cycle)
var routine_phases = [
	{"name": "wake_up", "duration": 120, "location": "home", "activity": "looking_around"},
	{"name": "morning_walk", "duration": 180, "location": "well", "activity": "weather_comment"},
	{"name": "shop_visit", "duration": 180, "location": "shop", "activity": "environment_interaction"},
	{"name": "social_time", "duration": 240, "location": "center", "activity": "seek_conversation"},
	{"name": "rest_time", "duration": 180, "location": "bench", "activity": "observing"},
	{"name": "evening_walk", "duration": 180, "location": "random", "activity": "commenting"},
	{"name": "return_home", "duration": 120, "location": "home", "activity": "end_day"}
]

# Signals
signal conversation_triggered(npc: NPCController, context: Dictionary)
signal routine_phase_changed(npc: NPCController, phase: String)

func _ready():
	_setup_visual()
	_setup_collision()
	routine_target = home_position
	
	# Start with initial movement to make NPCs visible
	call_deferred("_start_initial_routine")
	
	print("NPCController: ", npc_id, " initialized at ", home_position)

func _setup_visual():
	# Create sphere mesh for NPC (floating circle)
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	mesh_instance.mesh = sphere_mesh
	
	# Create material with NPC color and glow effect
	material = StandardMaterial3D.new()
	material.albedo_color = npc_color
	material.emission = npc_color * 0.3  # Add slight glow
	material.metallic = 0.0
	material.roughness = 0.3
	material.rim_enabled = true
	material.rim = 0.5
	material.rim_tint = 0.8
	mesh_instance.material_override = material
	
	# Position sphere slightly above ground for floating effect
	mesh_instance.position.y = 0.5
	
	add_child(mesh_instance)

func _setup_collision():
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	# Position collision shape to match visual sphere
	collision_shape.position.y = 0.5
	add_child(collision_shape)

func _physics_process(delta):
	conversation_cooldown -= delta
	phase_timer += delta
	
	# Handle movement to routine target
	if is_moving and routine_target:
		_move_towards_target(delta)
	
	# Check for nearby NPCs for conversation
	_check_for_conversation_opportunities()
	
	# Enhanced floating animation for circles
	var time = Time.get_ticks_msec() * 0.001
	var base_float_height = 0.5
	
	if velocity.length() > 0.1:
		# More pronounced floating when moving
		var float_offset = sin(time * 3.0) * 0.15 + sin(time * 1.5) * 0.08
		var sway_offset_x = sin(time * 2.0) * 0.05
		var sway_offset_z = cos(time * 2.5) * 0.03
		
		mesh_instance.position.y = base_float_height + float_offset
		mesh_instance.position.x = sway_offset_x
		mesh_instance.position.z = sway_offset_z
		
		# Gentle rotation while moving
		mesh_instance.rotation.y = sin(time * 1.2) * 0.1
	else:
		# Gentle floating when stationary
		var float_offset = sin(time * 2.0) * 0.08 + sin(time * 0.8) * 0.04
		mesh_instance.position.y = base_float_height + float_offset
		
		# Return to center position when not moving
		mesh_instance.position.x = lerp(mesh_instance.position.x, 0.0, delta * 3.0)
		mesh_instance.position.z = lerp(mesh_instance.position.z, 0.0, delta * 3.0)
		mesh_instance.rotation.y = lerp(mesh_instance.rotation.y, 0.0, delta * 2.0)

func update_routine(cycle_progress: float):
	# Determine current phase based on cycle progress
	var total_duration = 0
	var current_phase = 0
	
	for i in range(routine_phases.size()):
		var phase_duration = routine_phases[i].duration
		if cycle_progress <= (total_duration + phase_duration) / 1200.0:  # 1200 = 20 minutes
			current_phase = i
			break
		total_duration += phase_duration
	
	# Change phase if needed
	if current_phase != current_routine_phase:
		_change_routine_phase(current_phase)

func _change_routine_phase(new_phase: int):
	current_routine_phase = new_phase
	var phase_data = routine_phases[current_routine_phase]
	
	print(npc_id, " entering phase: ", phase_data.name)
	routine_phase_changed.emit(self, phase_data.name)
	
	# Set new target based on phase
	routine_target = _get_phase_target(phase_data.location)
	is_moving = true
	phase_timer = 0.0
	
	# Trigger phase-specific behavior
	_handle_phase_activity(phase_data.activity)

func _get_phase_target(location: String) -> Vector3:
	match location:
		"home":
			return home_position
		"well":
			return Vector3(0, 1, 0)  # Well position
		"shop":
			return Vector3(-10, 1, 10)  # Shop position
		"center":
			return Vector3(0, 1, 0)  # Village center
		"bench":
			# Choose random bench
			var benches = [Vector3(-5, 0.5, 5), Vector3(5, 0.5, -5)]
			return benches[randi() % benches.size()]
		"random":
			# Random position in village
			return Vector3(
				randf_range(-15, 15),
				1,
				randf_range(-15, 15)
			)
		_:
			return position

func _move_towards_target(delta):
	var direction = (routine_target - position).normalized()
	var distance = position.distance_to(routine_target)
	
	if distance > 1.0:
		# Move towards target
		velocity = direction * move_speed
		
		# Rotate to face movement direction
		if direction.length() > 0.1:
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		move_and_slide()
	else:
		# Reached target
		is_moving = false
		velocity = Vector3.ZERO

func _handle_phase_activity(activity: String):
	match activity:
		"weather_comment":
			_trigger_weather_comment()
		"environment_interaction":
			_trigger_environment_comment()
		"seek_conversation":
			_seek_conversation()
		"observing":
			_trigger_observation_comment()
		"commenting":
			_trigger_random_comment()

func _trigger_weather_comment():
	if conversation_cooldown <= 0:
		var context = {
			"type": "weather_comment",
			"weather": _get_current_weather(),
			"location": _get_current_location()
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 10.0  # Increased cooldown for turn system

func _trigger_environment_comment():
	if conversation_cooldown <= 0:
		var nearby_objects = _get_nearby_objects()
		var context = {
			"type": "environment_comment",
			"objects": nearby_objects,
			"location": _get_current_location()
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 15.0  # Increased cooldown for turn system

func _seek_conversation():
	var other_npc = _find_nearby_npc()
	if other_npc and conversation_cooldown <= 0:
		var context = {
			"type": "npc_conversation",
			"other_npc": other_npc.npc_id,
			"location": _get_current_location(),
			"relationship": _get_relationship_with(other_npc)
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 8.0  # Shorter cooldown for conversations

func _trigger_observation_comment():
	if conversation_cooldown <= 0 and randf() < 0.3:  # 30% chance
		var context = {
			"type": "observation",
			"location": _get_current_location(),
			"mood": _get_current_mood()
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 15.0

func _trigger_random_comment():
	if conversation_cooldown <= 0 and randf() < 0.2:  # 20% chance
		var context = {
			"type": "self_talk",
			"location": _get_current_location(),
			"thoughts": _get_current_thoughts()
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 12.0

func _check_for_conversation_opportunities():
	var other_npc = _find_nearby_npc()
	if other_npc and conversation_cooldown <= 0:
		# Reduced chance for spontaneous conversation to work with turn system
		if randf() < 0.01:  # 1% chance per frame when near
			_seek_conversation()

func _find_nearby_npc():
	var game_manager = get_node("/root/Main")
	if game_manager:
		var other_npc = game_manager.get_other_npc(self)
		if other_npc and position.distance_to(other_npc.position) <= conversation_range:
			return other_npc
	return null

func _get_nearby_objects() -> Array:
	var objects = []
	var game_manager = get_node("/root/Main")
	if game_manager:
		var village_objects = game_manager.get_village_objects()
		for obj in village_objects:
			if position.distance_to(obj.position) <= 5.0:
				objects.append(obj)
	return objects

func _get_current_weather() -> String:
	var weather_system = get_node("/root/Main/Weather")
	if weather_system:
		return weather_system.current_weather
	return "sunny"

func _get_current_location() -> String:
	# Determine location based on position
	if position.distance_to(home_position) < 3.0:
		return "home"
	elif position.distance_to(Vector3(0, 1, 0)) < 3.0:
		return "well"
	elif position.distance_to(Vector3(-10, 1, 10)) < 3.0:
		return "shop"
	else:
		return "village"

func _get_relationship_with(_other_npc: NPCController) -> String:
	if backstory.has("relationship"):
		return backstory.relationship
	return "acquaintance"

func _get_current_mood() -> String:
	# Simple mood based on weather and time
	var weather = _get_current_weather()
	if weather == "rainy":
		return "contemplative"
	elif weather == "sunny":
		return "cheerful"
	else:
		return "neutral"

func _get_current_thoughts() -> String:
	if backstory.has("secret"):
		return "thinking about their secret"
	return "pondering life"

func _start_initial_routine():
	# Start NPCs with some initial movement to make them visible
	print(npc_id, " starting initial routine")
	routine_target = Vector3(0, 1, 0)  # Move toward well initially
	is_moving = true
	
	# Trigger initial weather comment after a short delay, staggered by NPC
	var delay = 3.0 if npc_id == "red_npc" else 5.0  # Stagger initial comments
	await get_tree().create_timer(delay).timeout
	_trigger_weather_comment()

func load_backstory(data: Dictionary):
	backstory = data
	if data.has("name"):
		npc_name = data.name

func on_weather_changed(weather_type: String):
	# React to weather changes
	if conversation_cooldown <= 0:
		var context = {
			"type": "weather_reaction",
			"weather": weather_type,
			"location": _get_current_location()
		}
		conversation_triggered.emit(self, context)
		conversation_cooldown = 3.0
