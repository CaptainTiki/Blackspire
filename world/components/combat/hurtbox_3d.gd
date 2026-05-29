extends Area3D
class_name Hurtbox3D

@export var damage_target: Node


func _ready() -> void:
	if not damage_target:
		push_error("Hurtbox3D requires a damage_target reference.")

	monitorable = true
	monitoring = false


func apply_damage(damage_request: Variant) -> void:
	damage_target.apply_damage(damage_request)
