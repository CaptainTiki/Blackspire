extends Node
class_name PlayerHotbar

signal hotbar_changed
signal hotbar_toast(message: String)

const HotbarBindingScript := preload("res://data/items/hotbar_binding.gd")
const ItemInstanceScript := preload("res://data/items/item_instance.gd")

@export var inventory: Node
@export var player: PlayerController

var bindings: Array[Resource] = []


func _ready() -> void:
	if not inventory:
		push_error("PlayerHotbar requires an inventory reference.")
		return
	if not player:
		push_error("PlayerHotbar requires a player reference.")
		return

	inventory.inventory_changed.connect(_on_inventory_changed)
	_sync_slot_count()


func get_slot_count() -> int:
	if not inventory:
		return 0

	return inventory.get_hotbar_slot_count()


func get_binding(slot_index: int) -> Resource:
	_sync_slot_count()
	if slot_index < 0:
		push_error("PlayerHotbar.get_binding requires a non-negative slot index.")
		return null
	if slot_index >= bindings.size():
		return null

	return bindings[slot_index]


func bind_item(slot_index: int, item_instance: Resource) -> bool:
	if not item_instance:
		push_error("PlayerHotbar.bind_item requires an item instance.")
		return false
	if not inventory:
		push_error("PlayerHotbar.bind_item requires an inventory reference.")
		return false
	if not inventory.has_item_instance(item_instance):
		hotbar_toast.emit("Hotbar item must be in backpack")
		return false
	if slot_index < 0 or slot_index >= get_slot_count():
		hotbar_toast.emit("That hotbar slot is not available")
		return false

	_sync_slot_count()
	var binding := HotbarBindingScript.new()
	binding.setup_item(item_instance)
	bindings[slot_index] = binding
	hotbar_changed.emit()
	hotbar_toast.emit("Bound %s to hotbar %d" % [binding.get_display_name(), slot_index + 1])
	return true


func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= bindings.size():
		return

	bindings[slot_index] = null
	hotbar_changed.emit()


func clear_bindings_for_item(item_instance: Resource) -> void:
	if not item_instance:
		return

	var changed := false
	for index in bindings.size():
		var binding: Resource = bindings[index]
		if not binding:
			continue
		if binding.source_type == HotbarBindingScript.SourceType.ITEM and binding.item_instance == item_instance:
			bindings[index] = null
			changed = true

	if changed:
		hotbar_changed.emit()


func activate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= get_slot_count():
		return

	_sync_slot_count()
	var binding: Resource = get_binding(slot_index)
	if not binding:
		hotbar_toast.emit("Hotbar %d is empty" % (slot_index + 1))
		return

	_activate_binding(binding)


func _activate_binding(binding: Resource) -> void:
	if not binding.is_valid():
		hotbar_toast.emit("Hotbar slot is empty")
		return

	if binding.action_type != HotbarBindingScript.ActionType.CONSUMABLE:
		hotbar_toast.emit(binding.get_activation_message())
		return

	var item_instance: Resource = binding.item_instance
	if not inventory.has_item_instance(item_instance):
		clear_bindings_for_item(item_instance)
		hotbar_toast.emit("%s is no longer in backpack" % binding.get_display_name())
		return

	var consumable_definition: Resource = item_instance.item_definition
	if not consumable_definition or not "use_type" in consumable_definition:
		hotbar_toast.emit("%s use not implemented" % binding.get_display_name())
		return

	match consumable_definition.use_type:
		1:
			_use_heal_consumable(item_instance, consumable_definition)
		_:
			hotbar_toast.emit("%s use not implemented" % binding.get_display_name())


func _use_heal_consumable(item_instance: Resource, consumable_definition: Resource) -> void:
	var healed_amount := player.heal(consumable_definition.heal_amount)
	if healed_amount <= 0:
		hotbar_toast.emit("Already at full health")
		return
	if not inventory.consume_item_instance(item_instance, 1):
		hotbar_toast.emit("%s is no longer in backpack" % consumable_definition.display_name)
		return
	if item_instance.quantity == 0:
		clear_bindings_for_item(item_instance)

	if consumable_definition.replacement_item_definition:
		_add_or_drop_replacement(consumable_definition.replacement_item_definition)

	hotbar_toast.emit("Used %s: +%d HP" % [consumable_definition.display_name, healed_amount])


func _add_or_drop_replacement(item_definition: Resource) -> void:
	if inventory.add_item(item_definition):
		return

	var item_instance := ItemInstanceScript.new()
	item_instance.setup(item_definition, 1)
	player.drop_item_instance(item_instance)
	hotbar_toast.emit("Dropped %s" % item_definition.display_name)


func _sync_slot_count() -> void:
	var slot_count := get_slot_count()

	while bindings.size() < slot_count:
		bindings.append(null)
	while bindings.size() > slot_count:
		bindings.pop_back()


func _on_inventory_changed() -> void:
	_sync_slot_count()
	hotbar_changed.emit()
