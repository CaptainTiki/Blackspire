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
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var inventory: Node = $Components/PlayerInventory
@onready var life_state: Node = $Components/PlayerLifeState

# --- Internal ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _can_act := true
var _life_state_tween: Tween
var _standing_camera_position := Vector3.ZERO
var _standing_camera_rotation := Vector3.ZERO

func _ready() -> void:
	add_to_group("players")

	# Capture the mouse for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not camera:
		push_error("PlayerController is missing a Camera3D child node!")
	
	# Apply capsule and camera height from exported variables (useful for testing different sizes)
	_apply_player_height()
	_standing_camera_position = camera.position
	_standing_camera_rotation = camera.rotation


func _apply_player_height() -> void:
	# Update collision shape
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = capsule_height
		collision_shape.position.y = capsule_height * 0.5
	
	# Update camera height
	if camera:
		camera.position.y = eye_height


func get_inventory() -> Node:
	return inventory


func get_level_exit_summary() -> String:
	return inventory.get_level_exit_summary()


func can_act() -> bool:
	return _can_act


func is_bleeding_out_or_dead() -> bool:
	return life_state.is_bleeding_out_or_dead()


func enter_bleeding_out_state() -> void:
	_can_act = false
	velocity = Vector3.ZERO
	_play_collapse_pose()


func enter_dead_state() -> void:
	_can_act = false
	velocity = Vector3.ZERO
	_play_collapse_pose()


func exit_bleeding_out_state() -> void:
	_can_act = true
	_restart_life_state_tween()
	_life_state_tween.tween_property(camera, "position", _standing_camera_position, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_life_state_tween.parallel().tween_property(camera, "rotation", _standing_camera_rotation, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if not can_act():
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera:
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func _physics_process(delta: float) -> void:
	if not can_act():
		_process_disabled_movement(delta)
		return

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


func _process_disabled_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = move_toward(velocity.x, 0.0, walk_speed)
	velocity.z = move_toward(velocity.z, 0.0, walk_speed)
	move_and_slide()


func _play_collapse_pose() -> void:
	_restart_life_state_tween()
	var collapsed_position := _standing_camera_position
	collapsed_position.y = 0.28
	var collapsed_rotation := Vector3(0.0, 0.0, deg_to_rad(82.0))
	_life_state_tween.tween_property(camera, "position", collapsed_position, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_life_state_tween.parallel().tween_property(camera, "rotation", collapsed_rotation, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _restart_life_state_tween() -> void:
	if _life_state_tween:
		_life_state_tween.kill()

	_life_state_tween = create_tween()
