extends Resource
class_name ItemInstance

@export var item_definition: Resource
@export var quantity := 1
@export var instance_id: StringName = &""


func setup(definition: Resource, amount: int = 1) -> void:
	if not definition:
		push_error("ItemInstance.setup requires an item definition.")
		return
	if amount <= 0:
		push_error("ItemInstance.setup requires a positive amount.")
		return

	item_definition = definition
	quantity = amount
	if not is_stackable() and instance_id == &"":
		instance_id = _make_instance_id()


func is_stackable() -> bool:
	return item_definition and item_definition.stackable


func can_stack_with(other: Resource) -> bool:
	if not other:
		return false
	if not is_stackable():
		return false
	if not other.item_definition:
		return false

	return item_definition.id == other.item_definition.id


func get_available_stack_space() -> int:
	if not is_stackable():
		return 0

	return maxi(item_definition.max_stack - quantity, 0)


func add_quantity(amount: int) -> int:
	if amount <= 0:
		push_error("ItemInstance.add_quantity requires a positive amount.")
		return amount
	if not is_stackable():
		push_error("ItemInstance.add_quantity can only be used on stackable items.")
		return amount

	var accepted_amount := mini(amount, get_available_stack_space())
	quantity += accepted_amount
	return amount - accepted_amount


func split(amount: int) -> Resource:
	if amount <= 0:
		push_error("ItemInstance.split requires a positive amount.")
		return null
	if amount >= quantity:
		push_error("ItemInstance.split amount must be smaller than quantity.")
		return null

	quantity -= amount
	var split_instance: Resource = load("res://data/items/item_instance.gd").new()
	split_instance.setup(item_definition, amount)
	return split_instance


func get_display_name() -> String:
	if not item_definition:
		return "Unknown Item"

	return item_definition.display_name


func _make_instance_id() -> StringName:
	return StringName("%s_%d" % [item_definition.id, Time.get_ticks_usec()])
