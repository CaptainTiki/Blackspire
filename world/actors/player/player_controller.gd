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
@export var acceleration: float = 28.0
@export var deceleration: float = 24.0

# --- Stance Camera ---
@export var eye_height: float = 1.30
@export var crouch_eye_height: float = 0.78
@export var stance_camera_lerp_speed: float = 12.0

# --- Camera ---
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var crouch_collision: CollisionShape3D = $CrouchCollision
@onready var crouch_check: ShapeCast3D = $CrouchCheck
@onready var state_chart: StateChart = %StateChart
@onready var inventory: Node = $Components/PlayerInventory
@onready var equipment: Node = $Components/PlayerEquipment
@onready var hotbar: Node = $Components/PlayerHotbar
@onready var health: Node = $Components/HealthComponent
@onready var life_state: Node = $Components/PlayerLifeState
@onready var input_reader: PlayerInputScript = $Components/PlayerInput
@onready var interaction_scanner: InteractionScanner = $Components/InteractionScanner
@onready var player_look: Node = $Components/PlayerLook

# --- Internal ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = 0.0
var _input_dir := Vector2.ZERO
var _can_act := true
var _gameplay_input_enabled := true
var _life_state_tween: Tween
var _standing_camera_position := Vector3.ZERO
var _standing_camera_rotation := Vector3.ZERO
var _uses_replicated_transform := false
var _target_eye_height: float = 0.0
var _is_crouching := false

func _ready() -> void:
	add_to_group("players")

	if not camera:
		push_error("PlayerController is missing a Camera3D child node!")
	
	if not input_reader:
		push_error("PlayerController is missing PlayerInput component!")
	if not player_look:
		push_error("PlayerController is missing PlayerLook component!")
	else:
		player_look.capture_mouse()
	
	current_speed = walk_speed
	_target_eye_height = eye_height
	_apply_camera_height()
	_set_standing_collision_enabled(true)
	_standing_camera_position = camera.position
	_standing_camera_rotation = camera.rotation


func _apply_camera_height() -> void:
	if camera:
		camera.position.y = eye_height


func run() -> void:
	current_speed = walk_speed + equipment.get_move_speed_modifier()


func sprint() -> void:
	current_speed = sprint_speed + equipment.get_move_speed_modifier()


func jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity


func crouch() -> void:
	_is_crouching = true
	_target_eye_height = crouch_eye_height
	_set_standing_collision_enabled(false)


func stand() -> void:
	if not can_stand():
		return

	_is_crouching = false
	_target_eye_height = eye_height
	_set_standing_collision_enabled(true)


func can_stand() -> bool:
	if not crouch_check:
		return true

	crouch_check.force_shapecast_update()
	return not crouch_check.is_colliding()


func is_crouching() -> bool:
	return _is_crouching


func is_head_blocked() -> bool:
	return not can_stand()


func check_fall_speed() -> bool:
	return velocity.y < -8.0


func update_camera_height(delta: float, _direction: float = 0.0) -> void:
	if not camera:
		return

	camera.position.y = move_toward(camera.position.y, _target_eye_height, stance_camera_lerp_speed * delta)


func get_current_interaction_target() -> Node:
	if not interaction_scanner:
		return null
	if interaction_scanner.current_revive_target:
		return interaction_scanner.current_revive_target
	return interaction_scanner.current_interactable


func _set_standing_collision_enabled(is_enabled: bool) -> void:
	if standing_collision:
		standing_collision.disabled = not is_enabled
	if crouch_collision:
		crouch_collision.disabled = is_enabled


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
	if player_look:
		player_look.set_look_enabled(is_enabled)


func capture_mouse() -> void:
	if player_look:
		player_look.capture_mouse()


func release_mouse() -> void:
	if player_look:
		player_look.release_mouse()


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


func _physics_process(delta: float) -> void:
	_update_movement_input()

	if not can_act():
		_process_disabled_movement(delta)
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	var direction := get_movement_direction()

	current_speed = maxf(current_speed, 0.0)

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	if player_look:
		player_look.process_controller_look(delta)
	move_and_slide()


func _update_movement_input() -> void:
	# Movement comes exclusively from the per-player input reader.
	# If this is null the game will error here - that is intentional.
	_input_dir = input_reader.get_movement_vector()


func get_movement_direction() -> Vector3:
	return (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()


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
