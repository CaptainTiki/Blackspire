extends Node
class_name CrewStashInventory

signal stash_changed

@export_range(1, 96, 1) var slot_count := 24

var item_instances: Array[Resource] = []


func _ready() -> void:
	_ensure_slot_index(slot_count - 1)


func get_slot_count() -> int:
	return slot_count


func get_item_at(slot_index: int) -> Resource:
	if slot_index < 0:
		push_error("CrewStashInventory.get_item_at requires a non-negative slot index.")
		return null
	if slot_index >= slot_count:
		return null
	if slot_index >= item_instances.size():
		return null

	return item_instances[slot_index]


func take_item_at(slot_index: int) -> Resource:
	if slot_index < 0:
		push_error("CrewStashInventory.take_item_at requires a non-negative slot index.")
		return null
	if slot_index >= slot_count:
		return null

	_ensure_slot_index(slot_index)
	var item_instance: Resource = item_instances[slot_index]
	item_instances[slot_index] = null
	stash_changed.emit()
	return item_instance


func place_item_at(slot_index: int, item_instance: Resource) -> Resource:
	if slot_index < 0:
		push_error("CrewStashInventory.place_item_at requires a non-negative slot index.")
		return item_instance
	if slot_index >= slot_count:
		return item_instance
	if not item_instance:
		push_error("CrewStashInventory.place_item_at requires an item instance.")
		return null

	_ensure_slot_index(slot_index)
	var displaced_item: Resource = item_instances[slot_index]
	item_instances[slot_index] = item_instance
	stash_changed.emit()
	return displaced_item


func _ensure_slot_index(slot_index: int) -> void:
	while item_instances.size() <= slot_index:
		item_instances.append(null)
