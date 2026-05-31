extends Node
class_name PlayerInventory

signal coins_changed(coins: int)
signal inventory_changed
signal item_added(item_instance: Resource, amount: int)
signal inventory_toast(message: String)

const ItemInstanceScript := preload("res://data/items/item_instance.gd")
const GoldCoinDefinition := preload("res://data/items/gold_coin.tres")
const StatModifierDefinitionScript := preload("res://data/items/stat_modifier_definition.gd")

@export var equipment: Node
@export_range(1, 64, 1) var base_backpack_slot_count := 5
@export_range(0, 16, 1) var base_hotbar_slot_count := 3

var item_instances: Array[Resource] = []


func add_coins(amount: int) -> bool:
	if amount <= 0:
		push_error("PlayerInventory.add_coins requires a positive amount.")
		return false

	if not add_item(GoldCoinDefinition, amount):
		return false

	coins_changed.emit(get_coin_count())
	return true


func add_item(item_definition: Resource, quantity: int = 1) -> bool:
	if not item_definition:
		push_error("PlayerInventory.add_item requires an item definition.")
		return false
	if quantity <= 0:
		push_error("PlayerInventory.add_item requires a positive quantity.")
		return false
	if not item_definition.validate_definition():
		push_error("PlayerInventory.add_item received an invalid item definition.")
		return false
	if not can_add_item(item_definition, quantity):
		var toast_message := _format_item_full_message(item_definition)
		inventory_toast.emit(toast_message)
		print("PlayerInventory: ", toast_message)
		return false

	if item_definition.stackable:
		_add_stackable_item(item_definition, quantity)
	else:
		_add_non_stackable_item(item_definition, quantity)

	inventory_changed.emit()
	var toast_message := _format_item_added_message(item_definition, quantity)
	inventory_toast.emit(toast_message)
	print("PlayerInventory: ", toast_message)
	return true


func get_items() -> Array[Resource]:
	var items: Array[Resource] = []
	for item_instance in item_instances:
		if item_instance:
			items.append(item_instance)

	return items


func get_backpack_slot_count() -> int:
	if not equipment:
		return base_backpack_slot_count

	return base_backpack_slot_count + equipment.get_backpack_slot_modifier()


func get_hotbar_slot_count() -> int:
	if not equipment:
		return base_hotbar_slot_count

	return base_hotbar_slot_count + equipment.get_hotbar_slot_modifier()


func get_backpack_items() -> Array[Resource]:
	return get_items()


func get_used_backpack_slot_count() -> int:
	return get_items().size()


func get_empty_backpack_slot_count() -> int:
	return maxi(get_backpack_slot_count() - get_used_backpack_slot_count(), 0)


func can_add_item(item_definition: Resource, quantity: int = 1) -> bool:
	if not item_definition:
		return false
	if quantity <= 0:
		return false

	var remaining := quantity
	if item_definition.stackable:
		for item_instance in item_instances:
			if not item_instance:
				continue
			if item_instance.item_definition.id != item_definition.id:
				continue

			remaining -= item_instance.get_available_stack_space()
			if remaining <= 0:
				return true

		var required_new_slots := ceili(float(remaining) / float(item_definition.max_stack))
		return required_new_slots <= get_empty_backpack_slot_count()

	return quantity <= get_empty_backpack_slot_count()


func get_item_at(slot_index: int) -> Resource:
	if slot_index < 0:
		push_error("PlayerInventory.get_item_at requires a non-negative slot index.")
		return null
	if slot_index >= item_instances.size():
		return null

	return item_instances[slot_index]


func take_item_at(slot_index: int) -> Resource:
	if slot_index < 0:
		push_error("PlayerInventory.take_item_at requires a non-negative slot index.")
		return null
	if slot_index >= item_instances.size():
		return null

	var item_instance: Resource = item_instances[slot_index]
	item_instances[slot_index] = null
	_trim_empty_tail_slots()
	inventory_changed.emit()
	return item_instance


func place_item_at(slot_index: int, item_instance: Resource) -> Resource:
	if slot_index < 0:
		push_error("PlayerInventory.place_item_at requires a non-negative slot index.")
		return item_instance
	if slot_index >= get_backpack_slot_count():
		inventory_toast.emit("That backpack slot is not available")
		return item_instance
	if not item_instance:
		push_error("PlayerInventory.place_item_at requires an item instance.")
		return null

	_ensure_slot_index(slot_index)
	var displaced_item: Resource = item_instances[slot_index]
	item_instances[slot_index] = item_instance
	_trim_empty_tail_slots()
	inventory_changed.emit()
	return displaced_item


func can_change_equipped_item(old_definition: Resource, new_definition: Resource = null) -> bool:
	var future_backpack_slot_count := get_backpack_slot_count()
	future_backpack_slot_count -= _get_backpack_slot_modifier(old_definition)
	future_backpack_slot_count += _get_backpack_slot_modifier(new_definition)

	return get_used_backpack_slot_count() <= future_backpack_slot_count


func get_item_count(item_id: StringName) -> int:
	var total := 0

	for item_instance in item_instances:
		if not item_instance:
			continue
		if item_instance.item_definition.id == item_id:
			total += item_instance.quantity

	return total


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0:
		push_error("PlayerInventory.has_item requires a positive quantity.")
		return false

	return get_item_count(item_id) >= quantity


func has_item_instance(item_instance: Resource) -> bool:
	if not item_instance:
		return false

	return item_instances.has(item_instance)


func consume_item_instance(item_instance: Resource, quantity: int = 1) -> bool:
	if not item_instance:
		push_error("PlayerInventory.consume_item_instance requires an item instance.")
		return false
	if quantity <= 0:
		push_error("PlayerInventory.consume_item_instance requires a positive quantity.")
		return false
	if not has_item_instance(item_instance):
		return false
	if item_instance.quantity < quantity:
		return false

	item_instance.quantity -= quantity
	if item_instance.quantity == 0:
		var item_index := item_instances.find(item_instance)
		if item_index >= 0:
			item_instances[item_index] = null
			_trim_empty_tail_slots()

	inventory_changed.emit()
	return true


func get_coin_count() -> int:
	return get_item_count(GoldCoinDefinition.id)


func get_level_exit_summary() -> String:
	return "Loot Secured: %d gold" % get_coin_count()


func _add_stackable_item(item_definition: Resource, quantity: int) -> void:
	var remaining := quantity

	for item_instance in item_instances:
		if not item_instance:
			continue
		if item_instance.item_definition.id != item_definition.id:
			continue
		if item_instance.get_available_stack_space() == 0:
			continue

		remaining = item_instance.add_quantity(remaining)
		if remaining == 0:
			return

	while remaining > 0:
		var stack_amount := mini(remaining, item_definition.max_stack)
		var item_instance := ItemInstanceScript.new()
		item_instance.setup(item_definition, stack_amount)
		item_instances[_get_first_empty_slot_index()] = item_instance
		item_added.emit(item_instance, stack_amount)
		remaining -= stack_amount


func _add_non_stackable_item(item_definition: Resource, quantity: int) -> void:
	for index in quantity:
		var item_instance := ItemInstanceScript.new()
		item_instance.setup(item_definition, 1)
		item_instances[_get_first_empty_slot_index()] = item_instance
		item_added.emit(item_instance, 1)


func _get_first_empty_slot_index() -> int:
	for index in item_instances.size():
		if not item_instances[index]:
			return index

	var index := item_instances.size()
	_ensure_slot_index(index)
	return index


func _ensure_slot_index(slot_index: int) -> void:
	while item_instances.size() <= slot_index:
		item_instances.append(null)


func _trim_empty_tail_slots() -> void:
	while not item_instances.is_empty() and not item_instances[item_instances.size() - 1]:
		item_instances.pop_back()


func _get_backpack_slot_modifier(equipment_definition: Resource) -> int:
	if not equipment_definition:
		return 0
	if not equipment_definition.has_method("get_stat_modifier_total"):
		return 0

	return maxi(roundi(equipment_definition.get_stat_modifier_total(StatModifierDefinitionScript.StatType.BACKPACK_SLOTS)), 0)


func _format_item_added_message(item_definition: Resource, quantity: int) -> String:
	if item_definition.id == GoldCoinDefinition.id:
		return "Picked up %d gold" % quantity
	if quantity == 1:
		return "Picked up %s" % item_definition.display_name

	return "Picked up %d x %s" % [quantity, item_definition.display_name]


func _format_item_full_message(item_definition: Resource) -> String:
	if item_definition.id == GoldCoinDefinition.id:
		return "Not enough backpack space for gold"

	return "Not enough backpack space for %s" % item_definition.display_name
