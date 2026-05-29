extends Area3D
class_name Hurtbox3D

@export var damage_target: Node

const COMBAT_HURTBOX_LAYER := 0b000100
const WEAPON_HITBOX_LAYER := 0b001000


func _ready() -> void:
	if not damage_target:
		push_error("Hurtbox3D requires a damage_target reference.")

	collision_layer = COMBAT_HURTBOX_LAYER
	collision_mask = WEAPON_HITBOX_LAYER
	monitorable = true
	monitoring = false


func apply_damage(damage_request: Variant) -> void:
	damage_target.apply_damage(damage_request)
