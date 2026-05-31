extends Resource
class_name HotbarBinding

enum SourceType {
	EMPTY,
	ITEM,
}

enum ActionType {
	NONE,
	CONSUMABLE,
	EQUIP,
	CAST,
}

@export var source_type := SourceType.EMPTY
@export var action_type := ActionType.NONE
@export var item_instance: Resource
@export var cached_display_name := ""
@export var cached_icon: Texture2D


func setup_item(source_item_instance: Resource) -> void:
	if not source_item_instance:
		push_error("HotbarBinding.setup_item requires an item instance.")
		return
	if not source_item_instance.item_definition:
		push_error("HotbarBinding.setup_item requires an item definition.")
		return

	source_type = SourceType.ITEM
	item_instance = source_item_instance
	cached_display_name = source_item_instance.get_display_name()
	cached_icon = source_item_instance.item_definition.icon
	action_type = _get_action_type_for_item(source_item_instance.item_definition)


func is_empty() -> bool:
	return source_type == SourceType.EMPTY


func is_valid() -> bool:
	if is_empty():
		return false
	if source_type == SourceType.ITEM:
		return item_instance and item_instance.item_definition

	return false


func get_display_name() -> String:
	if cached_display_name.is_empty():
		return "Empty"

	return cached_display_name


func get_activation_message() -> String:
	if not is_valid():
		return "Hotbar slot is empty"

	match action_type:
		ActionType.CONSUMABLE:
			return "%s use not implemented" % get_display_name()
		ActionType.EQUIP:
			return "%s hotbar equip not implemented" % get_display_name()
		ActionType.CAST:
			return "%s cast not implemented" % get_display_name()
		_:
			return "%s is not usable" % get_display_name()


func _get_action_type_for_item(item_definition: Resource) -> int:
	if not item_definition:
		return ActionType.NONE
	if not "item_type" in item_definition:
		return ActionType.NONE

	match item_definition.item_type:
		1:
			return ActionType.NONE
		2:
			return ActionType.CONSUMABLE
		3:
			return ActionType.EQUIP
		_:
			return ActionType.NONE
