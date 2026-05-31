extends Node
class_name PlayerEquipment

const StatModifierDefinitionScript := preload("res://data/items/stat_modifier_definition.gd")

signal equipment_changed(slot: int, equipment_definition: Resource)

var equipped_items: Dictionary = {}


func equip(equipment_definition: Resource) -> void:
	equip_and_return_replaced(equipment_definition)


func equip_and_return_replaced(equipment_definition: Resource) -> Resource:
	if not equipment_definition:
		push_error("PlayerEquipment.equip requires an EquipmentDefinition.")
		return null
	if not equipment_definition.has_method("get_stat_modifier_total"):
		push_error("PlayerEquipment.equip requires an equipment definition resource.")
		return null
	if not "equipment_slot" in equipment_definition:
		push_error("PlayerEquipment.equip requires a resource with equipment_slot.")
		return null
	if not "stat_modifiers" in equipment_definition:
		push_error("PlayerEquipment.equip requires a resource with stat_modifiers.")
		return null

	var replaced_item: Resource = equipped_items.get(equipment_definition.equipment_slot)
	equipped_items[equipment_definition.equipment_slot] = equipment_definition
	equipment_changed.emit(equipment_definition.equipment_slot, equipment_definition)
	print("PlayerEquipment: equipped ", equipment_definition.display_name)
	return replaced_item


func unequip(equipment_slot: int) -> Resource:
	var equipped_item: Resource = equipped_items.get(equipment_slot)
	if not equipped_item:
		return null

	equipped_items.erase(equipment_slot)
	equipment_changed.emit(equipment_slot, null)
	print("PlayerEquipment: unequipped ", equipped_item.display_name)
	return equipped_item


func get_equipped(equipment_slot: int) -> Resource:
	return equipped_items.get(equipment_slot)


func get_stat_modifier_total(stat_type: int) -> float:
	var total := 0.0

	for equipment_definition in equipped_items.values():
		total += equipment_definition.get_stat_modifier_total(stat_type)

	return total


func get_attack_damage_modifier() -> float:
	return get_stat_modifier_total(StatModifierDefinitionScript.StatType.ATTACK_DAMAGE)


func get_armor() -> float:
	return get_stat_modifier_total(StatModifierDefinitionScript.StatType.ARMOR)


func get_max_health_modifier() -> float:
	return get_stat_modifier_total(StatModifierDefinitionScript.StatType.MAX_HEALTH)


func get_move_speed_modifier() -> float:
	return get_stat_modifier_total(StatModifierDefinitionScript.StatType.MOVE_SPEED)


func get_backpack_slot_modifier() -> int:
	return maxi(roundi(get_stat_modifier_total(StatModifierDefinitionScript.StatType.BACKPACK_SLOTS)), 0)


func get_hotbar_slot_modifier() -> int:
	return maxi(roundi(get_stat_modifier_total(StatModifierDefinitionScript.StatType.HOTBAR_SLOTS)), 0)


func mitigate_physical_damage(incoming_damage: int) -> int:
	if incoming_damage <= 0:
		return 0

	return maxi(roundi(float(incoming_damage) - get_armor()), 1)
