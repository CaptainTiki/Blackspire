extends "res://data/items/item_definition.gd"
class_name EquipmentDefinition

enum EquipmentSlot {
	PRIMARY_WEAPON,
	SECONDARY_WEAPON,
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	ACCESSORY,
	BAG,
}

@export var equipment_slot := EquipmentSlot.PRIMARY_WEAPON
@export var stat_modifiers: Array[Resource] = []
@export var wielded_scene_path: String = ""


func _init() -> void:
	item_type = ItemType.EQUIPMENT
	stackable = false
	max_stack = 1


func get_stat_modifier_total(stat_type: int) -> float:
	var total := 0.0

	for stat_modifier in stat_modifiers:
		if not stat_modifier:
			push_error("EquipmentDefinition '%s' has an empty stat modifier." % id)
			continue
		if not stat_modifier.has_method("applies_to"):
			push_error("EquipmentDefinition '%s' has a non-stat modifier resource." % id)
			continue
		if stat_modifier.applies_to(stat_type):
			total += stat_modifier.value

	return total


func validate_definition() -> bool:
	var is_valid := super.validate_definition()

	if item_type != ItemType.EQUIPMENT:
		push_error("EquipmentDefinition '%s' must use ItemType.EQUIPMENT." % id)
		is_valid = false
	if stackable:
		push_error("EquipmentDefinition '%s' must not be stackable." % id)
		is_valid = false
	if max_stack != 1:
		push_error("EquipmentDefinition '%s' must use max_stack 1." % id)
		is_valid = false

	return is_valid
