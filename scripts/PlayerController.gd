extends CharacterBody3D
class_name PlayerController

# Movement settings
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08

# Camera references
@onready var camera: Camera3D = $Camera3D

# Movement state
var is_running: bool = false
var bob_time: float = 0.0
var camera_base_y: float

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Capture mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Store camera's base Y position for head bobbing
	camera_base_y = camera.position.y
	
	print("PlayerController: First-person controller initialized")

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate player body horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		
		# Clamp vertical rotation
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Handle running
	is_running = Input.is_action_pressed("run")
	var current_speed = run_speed if is_running else walk_speed

	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1

	# Calculate movement direction relative to player rotation
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
		
		# Head bobbing when moving
		bob_time += delta * bob_frequency
		var bob_offset = sin(bob_time) * bob_amplitude
		camera.position.y = camera_base_y + bob_offset
	else:
		# Reset head bob when not moving
		bob_time = 0.0
		camera.position.y = lerp(camera.position.y, camera_base_y, delta * 5.0)

	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _on_area_entered(area):
	# Handle interaction with village objects
	if area.has_method("get_interaction_text"):
		print("Near: ", area.get_interaction_text())

func get_player_position() -> Vector3:
	return global_position

func get_forward_direction() -> Vector3:
	return -camera.global_transform.basis.z
