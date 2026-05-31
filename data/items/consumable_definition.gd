extends "res://data/items/item_definition.gd"
class_name ConsumableDefinition

enum ConsumableUseType {
	NONE,
	HEAL,
}

@export var use_type := ConsumableUseType.NONE
@export var heal_amount := 0
@export var replacement_item_definition: Resource


func _init() -> void:
	item_type = ItemType.CONSUMABLE
	stackable = true
	max_stack = 10


func validate_definition() -> bool:
	var is_valid := super.validate_definition()

	if item_type != ItemType.CONSUMABLE:
		push_error("ConsumableDefinition '%s' must use ItemType.CONSUMABLE." % id)
		is_valid = false
	if use_type == ConsumableUseType.HEAL and heal_amount <= 0:
		push_error("ConsumableDefinition '%s' uses HEAL but heal_amount is not positive." % id)
		is_valid = false

	return is_valid
