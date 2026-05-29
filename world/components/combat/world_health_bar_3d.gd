extends Node3D
class_name WorldHealthBar3D

@export var health_component: Node
@export var visible_after_damage_duration := 10.0
@export var fade_duration := 10.0
@export var camera_offset := 0.08

@onready var background: MeshInstance3D = $Background
@onready var fill: MeshInstance3D = $Fill

var _background_material := StandardMaterial3D.new()
var _fill_material := StandardMaterial3D.new()
var _alpha := 0.0
var _is_damaged := false
var _visible_after_damage_timer := 0.0
var _base_local_position := Vector3.ZERO


func _ready() -> void:
	_base_local_position = position
	_setup_materials()
	_set_alpha(0.0)

	health_component.damaged.connect(_on_health_damaged)
	health_component.died.connect(_on_health_died)

	_update_fill()


func _process(delta: float) -> void:
	_face_camera()

	_visible_after_damage_timer = maxf(_visible_after_damage_timer - delta, 0.0)

	var target_alpha := 1.0 if _is_damaged and _visible_after_damage_timer > 0.0 else 0.0
	if target_alpha == 1.0:
		_set_alpha(1.0)
	else:
		var fade_step := delta / fade_duration
		_set_alpha(move_toward(_alpha, 0.0, fade_step))


func _setup_materials() -> void:
	_background_material.albedo_color = Color(0.02, 0.02, 0.02, 0.75)
	_background_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_background_material.no_depth_test = true
	_background_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_fill_material.albedo_color = Color(0.88, 0.12, 0.08, 1.0)
	_fill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_material.no_depth_test = true
	_fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	background.material_override = _background_material
	fill.material_override = _fill_material


func _on_health_damaged(_damage_request: Variant, _remaining_health: int) -> void:
	_is_damaged = health_component.current_health < health_component.max_health
	_visible_after_damage_timer = visible_after_damage_duration
	_update_fill()
	if _is_damaged:
		_set_alpha(1.0)


func _on_health_died(_damage_request: Variant) -> void:
	_is_damaged = false
	_set_alpha(0.0)


func _update_fill() -> void:
	var ratio: float = float(health_component.current_health) / float(health_component.max_health)
	ratio = clamp(ratio, 0.0, 1.0)
	fill.scale.x = ratio
	fill.position.x = -0.39 + (0.39 * ratio)


func _set_alpha(value: float) -> void:
	_alpha = clamp(value, 0.0, 1.0)
	visible = _alpha > 0.0

	var background_color := _background_material.albedo_color
	background_color.a = 0.75 * _alpha
	_background_material.albedo_color = background_color

	var fill_color := _fill_material.albedo_color
	fill_color.a = _alpha
	_fill_material.albedo_color = fill_color


func _face_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	position = _base_local_position
	global_basis = camera.global_basis
	global_position += (camera.global_position - global_position).normalized() * camera_offset
