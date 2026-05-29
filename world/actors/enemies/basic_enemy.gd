extends CharacterBody3D
class_name BasicEnemy

const FloatingDamageNumber := preload("res://world/components/combat/floating_damage_number_3d.gd")

@export var move_speed := 2.4
@export var attack_damage := 10
@export var attack_range := 2.75
@export var attack_cooldown := 1.0
@export var attack_windup := 0.35
@export var attack_lunge_distance := 3.25
@export var attack_lunge_duration := 0.35
@export var attack_lunge_jump_velocity := 2.2
@export var attack_hit_range := 1.65
@export var attack_hit_cone_degrees := 70.0
@export var aggro_range := 8.0

@onready var health: Node = $Components/HealthComponent
@onready var behavior: Node = $Components/EnemyBehavior
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var debug_label: Label3D = $DebugStateLabel
@onready var attack_range_debug_collision: CollisionShape3D = $AttackRangeDebug/CollisionShape3D
@onready var attack_range_debug_mesh: MeshInstance3D = $AttackRangeDebug/AttackRangeMesh

var is_dead := false
var _feedback_tween: Tween
var _base_mesh_position := Vector3.ZERO
var _base_mesh_scale := Vector3.ONE
var _base_mesh_rotation := Vector3.ZERO
var _mesh_material := StandardMaterial3D.new()


func _ready() -> void:
	_base_mesh_position = mesh.position
	_base_mesh_scale = mesh.scale
	_base_mesh_rotation = mesh.rotation
	_setup_material()
	_sync_attack_range_debug()
	set_debug_state("IDLE")
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func apply_damage(damage_request: Variant) -> void:
	health.apply_damage(damage_request)


func play_attack_tell(target: Node3D) -> void:
	_restart_feedback_tween()
	var backward := (global_position - target.global_position).normalized() * 0.12
	backward.y = 0.0

	_feedback_tween.tween_property(mesh, "position", _base_mesh_position + backward + Vector3(0.0, -0.05, 0.0), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "scale", Vector3(1.12, 0.75, 1.12), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "rotation", _base_mesh_rotation + Vector3(deg_to_rad(-14.0), 0.0, 0.0), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_material(Color(0.95, 0.58, 0.18, 1.0), attack_windup)


func play_attack_lunge(_target: Node3D) -> void:
	_restart_feedback_tween()
	_feedback_tween.tween_property(mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "rotation", _base_mesh_rotation, attack_lunge_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(mesh, "position", _base_mesh_position, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "scale", _base_mesh_scale, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func set_debug_state(state_name: String) -> void:
	debug_label.text = state_name


func _sync_attack_range_debug() -> void:
	var shape := attack_range_debug_collision.shape as CylinderShape3D
	shape.radius = attack_range
	attack_range_debug_mesh.scale = Vector3(attack_range, 1.0, attack_range)


func die(_damage_request: Variant) -> void:
	if is_dead:
		return

	is_dead = true
	collision_shape.disabled = true
	mesh.visible = false
	debug_label.visible = false
	behavior.set_dead()


func _on_health_damaged(damage_request: Variant, _remaining_health: int) -> void:
	_play_hit_reaction()

	var damage_number := FloatingDamageNumber.new()
	damage_number.setup(damage_request.amount)
	_get_feedback_parent().add_child(damage_number)

	var hit_position: Vector3 = damage_request.hit_position
	if hit_position == Vector3.ZERO:
		hit_position = global_position + Vector3.UP

	damage_number.global_position = hit_position + Vector3(0.0, 0.3, 0.0)


func _on_health_died(damage_request: Variant) -> void:
	die(damage_request)


func _get_feedback_parent() -> Node:
	if Level.current_level and Level.current_level.has_node("Junk"):
		return Level.current_level.get_node("Junk")

	return get_parent()


func _setup_material() -> void:
	var current_material := mesh.material_override as StandardMaterial3D
	_mesh_material = current_material.duplicate()
	mesh.material_override = _mesh_material


func _play_hit_reaction() -> void:
	if is_dead:
		return

	_restart_feedback_tween()
	_feedback_tween.tween_property(mesh, "scale", Vector3(1.22, 0.75, 1.22), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(mesh, "scale", _base_mesh_scale, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_material(Color(1.0, 0.16, 0.1, 1.0), 0.16)


func _restart_feedback_tween() -> void:
	if _feedback_tween:
		_feedback_tween.kill()

	mesh.position = _base_mesh_position
	mesh.scale = _base_mesh_scale
	mesh.rotation = _base_mesh_rotation
	_feedback_tween = create_tween()


func _flash_material(color: Color, duration: float) -> void:
	var base_color := Color(0.42, 0.08, 0.07, 1.0)
	_mesh_material.albedo_color = color
	_feedback_tween.parallel().tween_property(_mesh_material, "albedo_color", base_color, duration)
