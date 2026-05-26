extends CharacterBody3D
class_name PlayerController

# --- Movement Settings ---
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# --- Player Sizing (Standard) ---
# Locked after testing with 64-unit rooms.
# Capsule: 1.45
# Eye/Camera: 1.30
@export var capsule_height: float = 1.45
@export var eye_height: float = 1.30

# --- Camera ---
@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# --- Internal ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Capture the mouse for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not camera:
		push_error("PlayerController is missing a Camera3D child node!")
	
	# Apply capsule and camera height from exported variables (useful for testing different sizes)
	_apply_player_height()


func _apply_player_height() -> void:
	# Update collision shape
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = capsule_height
		collision_shape.position.y = capsule_height * 0.5
	
	# Update camera height
	if camera:
		camera.position.y = eye_height

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera:
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

	if event.is_action_pressed("ui_cancel"):
		# Allow escaping the mouse for now during development
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
