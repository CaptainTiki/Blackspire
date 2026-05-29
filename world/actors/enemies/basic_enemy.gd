extends CharacterBody3D
class_name BasicEnemy

const FloatingDamageNumber := preload("res://world/components/combat/floating_damage_number_3d.gd")

@export var move_speed := 2.4
@export var attack_damage := 10
@export var attack_range := 1.2
@export var attack_cooldown := 1.0
@export var aggro_range := 8.0

@onready var health: Node = $Components/HealthComponent
@onready var behavior: Node = $Components/EnemyBehavior
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

var is_dead := false


func _ready() -> void:
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func apply_damage(damage_request: Variant) -> void:
	health.apply_damage(damage_request)


func die(_damage_request: Variant) -> void:
	if is_dead:
		return

	is_dead = true
	collision_shape.disabled = true
	mesh.visible = false
	behavior.set_dead()


func _on_health_damaged(damage_request: Variant, _remaining_health: int) -> void:
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
