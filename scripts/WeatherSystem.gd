extends Node3D
class_name WeatherSystem

# Weather types
enum WeatherType {
	SUNNY,
	CLOUDY,
	RAINY,
	WINDY
}

# Current weather state
var current_weather: String = "sunny"
var weather_timer: float = 0.0
var weather_change_interval: float = 300.0  # 5 minutes
var weather_transition_time: float = 10.0

# Weather components
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

# Weather effects
var rain_particles: GPUParticles3D
var wind_strength: float = 0.0
var target_wind_strength: float = 0.0

# Lighting settings for different weather
var weather_lighting = {
	"sunny": {
		"light_energy": 1.0,
		"light_color": Color(1.0, 0.95, 0.8),
		"ambient_energy": 0.3,
		"sky_color": Color(0.5, 0.7, 1.0)
	},
	"cloudy": {
		"light_energy": 0.6,
		"light_color": Color(0.8, 0.8, 0.9),
		"ambient_energy": 0.5,
		"sky_color": Color(0.6, 0.6, 0.7)
	},
	"rainy": {
		"light_energy": 0.4,
		"light_color": Color(0.7, 0.7, 0.8),
		"ambient_energy": 0.6,
		"sky_color": Color(0.4, 0.4, 0.5)
	},
	"windy": {
		"light_energy": 0.8,
		"light_color": Color(0.9, 0.9, 1.0),
		"ambient_energy": 0.4,
		"sky_color": Color(0.6, 0.7, 0.9)
	}
}

signal weather_changed(weather_type: String)

func _ready():
	print("WeatherSystem: Initializing weather system")
	
	# Set initial weather
	_setup_rain_particles()
	change_weather("sunny")
	
	# Random weather changes
	weather_timer = randf_range(60.0, weather_change_interval)

func _process(delta):
	weather_timer -= delta
	
	# Check for weather change
	if weather_timer <= 0.0:
		_random_weather_change()
		weather_timer = randf_range(weather_change_interval * 0.5, weather_change_interval * 1.5)
	
	# Update wind effects
	wind_strength = lerp(wind_strength, target_wind_strength, delta * 2.0)
	_update_wind_effects()

func _setup_rain_particles():
	rain_particles = GPUParticles3D.new()
	add_child(rain_particles)
	
	# Configure rain particles
	rain_particles.emitting = false
	rain_particles.amount = 1000
	rain_particles.lifetime = 2.0
	rain_particles.visibility_aabb = AABB(Vector3(-25, 0, -25), Vector3(50, 30, 50))
	
	# Create particle material
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.1
	material.scale_max = 0.2
	
	rain_particles.process_material = material
	
	# Create rain mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.1, 1.0)
	rain_particles.draw_pass_1 = quad_mesh
	
	# Position above the village
	rain_particles.position = Vector3(0, 20, 0)

func change_weather(new_weather: String):
	if new_weather == current_weather:
		return
	
	print("WeatherSystem: Changing weather from ", current_weather, " to ", new_weather)
	
	var old_weather = current_weather
	current_weather = new_weather
	
	# Apply weather effects
	_apply_weather_effects(new_weather)
	
	# Emit signal
	weather_changed.emit(new_weather)

func _random_weather_change():
	var weather_types = ["sunny", "cloudy", "rainy", "windy"]
	var new_weather = weather_types[randi() % weather_types.size()]
	
	# Avoid immediate repeat of same weather
	while new_weather == current_weather:
		new_weather = weather_types[randi() % weather_types.size()]
	
	change_weather(new_weather)

func _apply_weather_effects(weather: String):
	var settings = weather_lighting.get(weather, weather_lighting["sunny"])
	
	# Create tween for smooth transitions
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animate lighting changes
	if directional_light:
		tween.tween_property(directional_light, "light_energy", settings.light_energy, weather_transition_time)
		tween.tween_property(directional_light, "light_color", settings.light_color, weather_transition_time)
	
	# Animate environment changes
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		tween.tween_property(env, "ambient_light_energy", settings.ambient_energy, weather_transition_time)
		tween.tween_property(env, "background_color", settings.sky_color, weather_transition_time)
	
	# Handle specific weather effects
	match weather:
		"rainy":
			_start_rain()
			target_wind_strength = 0.3
		"windy":
			_stop_rain()
			target_wind_strength = 1.0
		"cloudy":
			_stop_rain()
			target_wind_strength = 0.2
		"sunny":
			_stop_rain()
			target_wind_strength = 0.1

func _start_rain():
	if rain_particles:
		rain_particles.emitting = true
		print("WeatherSystem: Started rain effects")

func _stop_rain():
	if rain_particles:
		rain_particles.emitting = false
		print("WeatherSystem: Stopped rain effects")

func _update_wind_effects():
	# Apply wind effects to trees and other objects
	var environment = get_node_or_null("/root/Main/World/Environment")
	if environment:
		for child in environment.get_children():
			if child.name.contains("Tree"):
				_apply_wind_to_object(child)

func _apply_wind_to_object(obj: Node3D):
	if not obj.has_method("get_child") or obj.get_child_count() == 0:
		return
	
	var mesh_instance = obj.get_child(0) as MeshInstance3D
	if mesh_instance:
		# Simple wind sway effect
		var sway_amount = sin(Time.get_ticks_msec() * 0.002 + obj.position.x) * wind_strength * 0.1
		mesh_instance.rotation.z = sway_amount

func get_weather_description() -> String:
	match current_weather:
		"sunny":
			return "The sun is shining brightly with clear skies"
		"cloudy":
			return "Gray clouds cover the sky, creating a soft, diffused light"
		"rainy":
			return "Rain is falling steadily from the overcast sky"
		"windy":
			return "A strong breeze is blowing through the village"
		_:
			return "The weather is pleasant"

func get_weather_mood() -> String:
	match current_weather:
		"sunny":
			return "cheerful"
		"cloudy":
			return "contemplative"
		"rainy":
			return "melancholic"
		"windy":
			return "energetic"
		_:
			return "neutral"

func force_weather(weather_type: String):
	"""Force a specific weather type for testing purposes"""
	change_weather(weather_type)
	weather_timer = weather_change_interval  # Reset timer

func get_current_weather() -> String:
	return current_weather
