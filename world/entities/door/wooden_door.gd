@tool
extends SwingDoor
class_name WoodenDoor

const FloatingDamageNumber := preload("res://world/components/combat/floating_damage_number_3d.gd")

## Wooden-specific behavior lives here (breakable by combat, different sounds/materials, etc).
## All basic swinging open/close logic is in the SwingDoor parent.

@onready var health: Node = $Components/HealthComponent
@onready var door_collision_shape: CollisionShape3D = $Door_CollisionShape3D
@onready var door_mesh: MeshInstance3D = $Door_CollisionShape3D/Door_Mesh

var is_broken := false


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func _on_interact(interactable: Interactable, actor: Node) -> void:
	if is_broken:
		return

	super(interactable, actor)


func apply_damage(damage_request: Variant) -> void:
	health.apply_damage(damage_request)


func _on_health_damaged(damage_request: Variant, _remaining_health: int) -> void:
	var damage_number := FloatingDamageNumber.new()
	damage_number.setup(damage_request.amount)
	_get_feedback_parent().add_child(damage_number)

	var hit_position: Vector3 = damage_request.hit_position
	if hit_position == Vector3.ZERO:
		hit_position = global_position + Vector3(0.0, 1.35, 0.0)

	var source := damage_request.source as Node3D
	var source_offset := Vector3.ZERO
	if source:
		source_offset = (source.global_position - hit_position).normalized() * 0.5

	damage_number.global_position = hit_position + source_offset + Vector3(0.0, 0.15, 0.0)


func _on_health_died(_damage_request: Variant) -> void:
	is_broken = true
	is_open = true
	is_animating = false
	player_operated = false
	door_collision_shape.disabled = true
	door_mesh.visible = false


func _get_feedback_parent() -> Node:
	if Level.current_level and Level.current_level.has_node("Junk"):
		return Level.current_level.get_node("Junk")

	return get_parent()
