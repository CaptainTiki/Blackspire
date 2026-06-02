extends Node
class_name PlayerMeleeAttack

signal primary_action_started(player: PlayerController)
signal attack_presentation_started(player: PlayerController)
signal attack_finished(player: PlayerController)
signal damage_area_hit(player: PlayerController, area: Area3D, damage_amount: int, hit_position: Vector3)

const DamageRequestScript := preload("res://world/components/combat/damage_request.gd")

@export var player_components: PlayerComponents
@export var attack_damage := 10
@export var active_delay := 0.08
@export var active_duration := 0.16

const COMBAT_HURTBOX_LAYER := 0b000100
const WEAPON_HITBOX_LAYER := 0b001000

@onready var camera: Camera3D = player_components.camerarig.ray_cast_3d.get_parent()
@onready var animation_player: AnimationPlayer = camera.get_node("WeaponRoot/AnimationPlayer")
@onready var hitbox: Area3D = camera.get_node("WeaponRoot/SwordPivot/SwordHitbox")

var _is_attacking := false
var _hit_targets: Array[Node] = []


func _ready() -> void:
	if not player_components:
		push_error("PlayerMeleeAttack requires a PlayerComponents reference.")

	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox.collision_layer = WEAPON_HITBOX_LAYER
	hitbox.collision_mask = COMBAT_HURTBOX_LAYER
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func can_attack() -> bool:
	if _is_attacking:
		return false
	if not player_components.player.can_act():
		return false

	return true


func attack() -> bool:
	if not can_attack():
		return false

	_run_attack()
	return true


func play_attack_presentation() -> void:
	if _is_attacking:
		return

	_is_attacking = true
	animation_player.play("attack")
	attack_presentation_started.emit(player_components.player)
	await animation_player.animation_finished
	_is_attacking = false


func _run_attack() -> void:
	_is_attacking = true
	_hit_targets.clear()
	primary_action_started.emit(player_components.player)
	animation_player.play("attack")
	attack_presentation_started.emit(player_components.player)

	await get_tree().create_timer(active_delay).timeout
	hitbox.monitoring = true
	await get_tree().physics_frame

	for area in hitbox.get_overlapping_areas():
		_try_damage_area(area)

	await get_tree().create_timer(active_duration).timeout
	hitbox.monitoring = false

	await animation_player.animation_finished
	_is_attacking = false
	attack_finished.emit(player_components.player)


func _on_hitbox_area_entered(area: Area3D) -> void:
	_try_damage_area(area)


func _try_damage_area(area: Area3D) -> void:
	if not area.has_method("apply_damage"):
		return

	if _hit_targets.has(area):
		return

	_hit_targets.append(area)
	var hit_position := _get_feedback_hit_position(area)
	var damage_amount := get_attack_damage()
	var damage_request := DamageRequestScript.new(player_components.player, damage_amount, hit_position)
	area.apply_damage(damage_request)
	damage_area_hit.emit(player_components.player, area, damage_amount, hit_position)


func get_attack_damage() -> int:
	var total_damage := float(attack_damage)

	if player_components.equipment:
		total_damage += player_components.equipment.get_attack_damage_modifier()

	return maxi(roundi(total_damage), 0)


func _get_feedback_hit_position(area: Area3D) -> Vector3:
	var hit_position := area.global_position
	var collision_shape := area.find_child("CollisionShape3D", false, false) as CollisionShape3D
	if collision_shape:
		hit_position = collision_shape.global_position

	var from_camera := (camera.global_position - hit_position).normalized()
	return hit_position + (from_camera * 0.35)
