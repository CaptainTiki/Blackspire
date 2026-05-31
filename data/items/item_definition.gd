extends Resource
class_name ItemDefinition

enum ItemType {
	MISC,
	CURRENCY,
	CONSUMABLE,
	EQUIPMENT,
	QUEST,
}

@export var id: StringName = &""
@export var display_name := ""
@export var icon: Texture2D
@export_file("*.tscn") var world_pickup_scene_path := ""
@export var stackable := false
@export_range(1, 999, 1) var max_stack := 1
@export var item_type := ItemType.MISC


func validate_definition() -> bool:
	var is_valid := true

	if id == &"":
		push_error("ItemDefinition is missing id.")
		is_valid = false
	if display_name.is_empty():
		push_error("ItemDefinition '%s' is missing display_name." % id)
		is_valid = false
	if world_pickup_scene_path.is_empty():
		push_error("ItemDefinition '%s' is missing world_pickup_scene_path." % id)
		is_valid = false
	elif not ResourceLoader.exists(world_pickup_scene_path):
		push_error("ItemDefinition '%s' references missing world_pickup_scene_path '%s'." % [id, world_pickup_scene_path])
		is_valid = false
	if not stackable and max_stack != 1:
		push_error("ItemDefinition '%s' is not stackable but max_stack is %d." % [id, max_stack])
		is_valid = false

	return is_valid
