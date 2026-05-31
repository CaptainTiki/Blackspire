@tool
extends "res://world/entities/pickups/pickup.gd"
class_name EquipmentPickup

@export var equipment_definition: Resource


func _ready() -> void:
	_apply_equipment_definition()
	super._ready()


func setup_from_item_instance(item_instance: Resource) -> void:
	super.setup_from_item_instance(item_instance)
	equipment_definition = item_instance.item_definition
	_apply_equipment_definition()
	_apply_display_state()


func _apply_display_state() -> void:
	if not interactable:
		return

	interactable.prompt = "Take %s" % display_name


func _apply_to_inventory(inventory: Node) -> bool:
	if not equipment_definition:
		push_error("EquipmentPickup requires an EquipmentDefinition.")
		return false

	return inventory.add_item(equipment_definition)


func _apply_equipment_definition() -> void:
	if not equipment_definition:
		return

	pickup_id = equipment_definition.id
	display_name = equipment_definition.display_name
