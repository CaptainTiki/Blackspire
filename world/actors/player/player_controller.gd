extends CharacterBody3D
class_name PlayerController

const DamageRequestScript := preload("res://world/components/combat/damage_request.gd")
const PlayerInputScript := preload("res://world/components/player/player_input.gd")

const DROP_IMPULSE := 3.25
const DROP_UP_IMPULSE := 1.4
const DROP_FORWARD_OFFSET := 1.35
const DROP_DOWN_OFFSET := 0.35

# --- Movement Settings ---
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var controller_look_speed: float = 2.8

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
@onready var equipment: Node = $Components/PlayerEquipment
@onready var hotbar: Node = $Components/PlayerHotbar
@onready var health: Node = $Components/HealthComponent
@onready var life_state: Node = $Components/PlayerLifeState
@onready var input_reader: PlayerInputScript = $Components/PlayerInput

# --- Internal ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _can_act := true
var _gameplay_input_enabled := true
var _life_state_tween: Tween
var _standing_camera_position := Vector3.ZERO
var _standing_camera_rotation := Vector3.ZERO
var _controller_look_enabled := true
var _uses_replicated_transform := false

func _ready() -> void:
	add_to_group("players")

	# Capture the mouse for first-person control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not camera:
		push_error("PlayerController is missing a Camera3D child node!")
	
	if not input_reader:
		push_error("PlayerController is missing PlayerInput component!")
	else:
		input_reader.mouse_motion_captured.connect(_on_mouse_motion_captured)
	
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


func get_equipment() -> Node:
	return equipment


func get_hotbar() -> Node:
	return hotbar


func heal(amount: int) -> int:
	return health.heal(amount)


func drop_item_instance(item_instance: Resource) -> Node3D:
	if not item_instance:
		push_error("PlayerController.drop_item_instance requires an item instance.")
		return null
	if not item_instance.item_definition:
		push_error("PlayerController.drop_item_instance requires an item definition.")
		return null
	if item_instance.item_definition.world_pickup_scene_path.is_empty():
		push_error("ItemDefinition '%s' is missing world_pickup_scene_path." % item_instance.item_definition.id)
		return null

	var pickup_scene := load(item_instance.item_definition.world_pickup_scene_path) as PackedScene
	if not pickup_scene:
		push_error("Could not load world pickup scene '%s'." % item_instance.item_definition.world_pickup_scene_path)
		return null

	var pickup: Node3D = pickup_scene.instantiate()
	if pickup.has_method("setup_from_item_instance"):
		pickup.setup_from_item_instance(item_instance)

	var camera_transform := camera.global_transform
	var forward := -camera_transform.basis.z.normalized()
	var spawn_position := camera_transform.origin + forward * DROP_FORWARD_OFFSET - Vector3.UP * DROP_DOWN_OFFSET
	get_parent().add_child(pickup)
	pickup.global_position = spawn_position
	pickup.global_rotation = global_rotation

	if pickup is RigidBody3D:
		var body := pickup as RigidBody3D
		body.freeze = false
		body.apply_central_impulse(forward * DROP_IMPULSE + Vector3.UP * DROP_UP_IMPULSE)

	return pickup


func apply_damage(damage_request: Variant) -> void:
	if damage_request.damage_type != &"physical":
		health.apply_damage(damage_request)
		return

	var mitigated_amount: int = equipment.mitigate_physical_damage(damage_request.amount)
	var mitigated_request := DamageRequestScript.new(
			damage_request.source,
			mitigated_amount,
			damage_request.hit_position,
			damage_request.damage_type)
	health.apply_damage(mitigated_request)


func get_level_exit_summary() -> String:
	return inventory.get_level_exit_summary()


func can_act() -> bool:
	return _can_act and _gameplay_input_enabled


func set_gameplay_input_enabled(is_enabled: bool) -> void:
	_gameplay_input_enabled = is_enabled


func set_controller_look_enabled(is_enabled: bool) -> void:
	_controller_look_enabled = is_enabled


func set_uses_replicated_transform(is_enabled: bool) -> void:
	_uses_replicated_transform = is_enabled
	if is_enabled:
		velocity = Vector3.ZERO
		set_physics_process(false)
	else:
		set_physics_process(true)


func get_network_transform_state() -> Dictionary:
	return {
		"position": global_position,
		"body_yaw": rotation.y,
		"camera_pitch": camera.rotation.x,
	}


func apply_network_transform_state(position: Vector3, body_yaw: float, camera_pitch: float) -> void:
	global_position = position
	rotation.y = body_yaw
	if camera:
		camera.rotation.x = clampf(camera_pitch, -1.5, 1.5)
	velocity = Vector3.ZERO


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
	# Mouse motion is now delivered via signal from PlayerInput.
	# We keep this stub in case other one-off input is needed later.
	pass


func _on_mouse_motion_captured(relative: Vector2) -> void:
	if not can_act():
		return
	if not input_reader.owns_mouse:
		return

	rotate_y(-relative.x * mouse_sensitivity)
	if camera:
		camera.rotate_x(-relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func _physics_process(delta: float) -> void:
	if not can_act():
		_process_disabled_movement(delta)
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump via PlayerInput (required — fail loudly if missing)
	if input_reader.is_jump_just_pressed() and is_on_floor():
		velocity.y = jump_velocity

	# Movement comes exclusively from the per-player input reader.
	# If this is null the game will error here — that is intentional.
	var input_dir := input_reader.get_movement_vector()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var sprinting := input_reader.is_sprint_pressed()
	var current_speed = sprint_speed if sprinting else walk_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	_process_controller_look(delta)
	move_and_slide()


func _process_disabled_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = move_toward(velocity.x, 0.0, walk_speed)
	velocity.z = move_toward(velocity.z, 0.0, walk_speed)
	move_and_slide()


func _process_controller_look(delta: float) -> void:
	if not _controller_look_enabled:
		return

	# Direct access — missing input_reader will error loudly (desired).
	var look_input := input_reader.get_look_vector()
	if look_input.is_zero_approx():
		return

	rotate_y(-look_input.x * controller_look_speed * delta)
	if camera:
		camera.rotate_x(-look_input.y * controller_look_speed * delta)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)


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
