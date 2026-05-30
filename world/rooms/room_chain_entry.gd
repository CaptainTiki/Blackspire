extends Resource
class_name RoomChainEntry

@export var room_key: StringName = &""
@export var room_scene: PackedScene
@export var connect_from_room_key: StringName = &""
@export var connect_from_connector_id: StringName = &""
@export var connect_to_connector_id: StringName = &""
@export var required_tags := ""


func has_parent_connection() -> bool:
	return connect_from_room_key != "" or connect_from_connector_id != "" or connect_to_connector_id != ""


func get_required_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	var normalized_tags := required_tags.replace(",", " ")
	for raw_tag in normalized_tags.split(" ", false):
		result.append(StringName(raw_tag))
	return result
