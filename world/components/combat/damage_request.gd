extends RefCounted
class_name DamageRequest

var source: Node
var amount: int
var hit_position: Vector3
var damage_type: StringName


func _init(
		source_node: Node,
		damage_amount: int,
		world_hit_position: Vector3 = Vector3.ZERO,
		request_damage_type: StringName = &"physical") -> void:
	source = source_node
	amount = damage_amount
	hit_position = world_hit_position
	damage_type = request_damage_type
