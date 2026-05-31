@tool
extends "res://world/entities/pickups/pickup.gd"
class_name EquipmentPickup

@export var equipment_definition: Resource


func _ready() -> void:
	_apply_equipment_definition()
	super._ready()


func collect(actor: Node) -> void:
	if is_collected:
		return
	if not equipment_definition:
		push_error("EquipmentPickup requires an EquipmentDefinition.")
		return

	var player := actor as PlayerController
	if not player:
		push_error("EquipmentPickup '%s' can only be collected by a PlayerController." % display_name)
		return

	player.get_equipment().equip(equipment_definition)
	is_collected = true
	collected.emit(actor)
	queue_free()


func _apply_display_state() -> void:
	interactable.prompt = "Equip %s" % display_name


func _apply_equipment_definition() -> void:
	if not equipment_definition:
		return

	pickup_id = equipment_definition.id
	display_name = equipment_definition.display_name
