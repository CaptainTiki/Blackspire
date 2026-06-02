extends Node
class_name PlayerLook

const PlayerInputScript := preload("res://world/components/player/player_input.gd")

@export var player: Node3D
@export var camera: Camera3D
@export var input_reader: PlayerInputScript
@export var mouse_sensitivity: float = 0.002
@export var controller_look_speed: float = 2.8
@export var pitch_min: float = -1.5
@export var pitch_max: float = 1.5

var _is_enabled := true


func _ready() -> void:
	if not player:
		push_error("PlayerLook requires a player reference.")
	if not camera:
		push_error("PlayerLook requires a camera reference.")
	if not input_reader:
		push_error("PlayerLook requires an input_reader reference.")
	else:
		input_reader.mouse_motion_captured.connect(_on_mouse_motion_captured)


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_look_enabled(is_enabled: bool) -> void:
	_is_enabled = is_enabled


func process_controller_look(delta: float) -> void:
	if not _can_process_look():
		return

	var look_input := input_reader.get_look_vector()
	if look_input.is_zero_approx():
		return

	player.rotate_y(-look_input.x * controller_look_speed * delta)
	camera.rotate_x(-look_input.y * controller_look_speed * delta)
	camera.rotation.x = clampf(camera.rotation.x, pitch_min, pitch_max)


func _on_mouse_motion_captured(relative: Vector2) -> void:
	if not _can_process_look():
		return

	player.rotate_y(-relative.x * mouse_sensitivity)
	camera.rotate_x(-relative.y * mouse_sensitivity)
	camera.rotation.x = clampf(camera.rotation.x, pitch_min, pitch_max)


func _can_process_look() -> bool:
	if not _is_enabled:
		return false
	if not player or not player.has_method("can_act") or not player.can_act():
		return false
	if not input_reader or not input_reader.owns_mouse:
		return false
	return camera != null
