extends Node
class_name PlayerEquipment

signal equipment_changed(slot: int, equipment_definition: Resource)

var equipped_items: Dictionary = {}


func equip(equipment_definition: Resource) -> void:
	if not equipment_definition:
		push_error("PlayerEquipment.equip requires an EquipmentDefinition.")
		return
	if not equipment_definition.has_method("get_stat_modifier_total"):
		push_error("PlayerEquipment.equip requires an equipment definition resource.")
		return

	equipped_items[equipment_definition.equipment_slot] = equipment_definition
	equipment_changed.emit(equipment_definition.equipment_slot, equipment_definition)
	print("PlayerEquipment: equipped ", equipment_definition.display_name)


func get_equipped(equipment_slot: int) -> Resource:
	return equipped_items.get(equipment_slot)


func get_stat_modifier_total(stat_type: int) -> float:
	var total := 0.0

	for equipment_definition in equipped_items.values():
		total += equipment_definition.get_stat_modifier_total(stat_type)

	return total
