@tool
extends "res://world/entities/pickups/pickup.gd"
class_name ItemPickup

@export var item_definition: Resource
@export var quantity := 1


func _ready() -> void:
	_apply_item_definition()
	super._ready()


func setup_from_item_instance(item_instance: Resource) -> void:
	super.setup_from_item_instance(item_instance)
	item_definition = item_instance.item_definition
	quantity = item_instance.quantity
	_apply_item_definition()
	_apply_display_state()


func _apply_to_inventory(inventory: Node) -> bool:
	if not item_definition:
		push_error("ItemPickup requires an ItemDefinition.")
		return false

	return inventory.add_item(item_definition, quantity)


func _apply_item_definition() -> void:
	if not item_definition:
		return

	pickup_id = item_definition.id
	display_name = item_definition.display_name
