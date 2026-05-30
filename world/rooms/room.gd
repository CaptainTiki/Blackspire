extends Node3D
class_name Room

## Base class for all rooms.

@export var room_id: StringName = &""
@export var room_type: StringName = &"combat_small"
@export var footprint_modules := Vector2i.ONE
@export var preferred_tags := ""

## Per-room junk container for temporary debris, particles, etc.
## Created on demand so we don't force every room to have one in the scene.
var _junk_container: Node3D = null


func get_junk_container() -> Node3D:
	if not _junk_container:
		_junk_container = Node3D.new()
		_junk_container.name = "Junk"
		add_child(_junk_container)
	return _junk_container


func get_connector(connector_id: StringName) -> RoomConnector:
	for connector in get_connectors():
		if connector.connector_id == connector_id:
			return connector

	push_error("Room '%s' could not find connector '%s'." % [room_id, connector_id])
	return null


func get_connectors() -> Array[RoomConnector]:
	var results: Array[RoomConnector] = []
	_find_connectors_recursive(self, results)
	return results


func get_preferred_tags() -> Array[StringName]:
	return _parse_tags(preferred_tags)


func _find_connectors_recursive(node: Node, results: Array[RoomConnector]) -> void:
	for child in node.get_children():
		if child is RoomConnector:
			results.append(child)

		_find_connectors_recursive(child, results)


func _parse_tags(raw_tags: String) -> Array[StringName]:
	var result: Array[StringName] = []
	var normalized_tags := raw_tags.replace(",", " ")
	for raw_tag in normalized_tags.split(" ", false):
		result.append(StringName(raw_tag))
	return result
