extends Node
class_name LevelGenerator

@export var chain_entries: Array[RoomChainEntry] = []

var generated_rooms: Dictionary[StringName, Room] = {}
var generated_rooms_container: Node3D


func generate() -> Dictionary[StringName, Room]:
	generated_rooms.clear()

	generated_rooms_container = _get_or_create_generated_rooms_container()
	_clear_generated_rooms_container()

	if chain_entries.is_empty():
		return generated_rooms

	for index in chain_entries.size():
		var entry := chain_entries[index]
		_validate_entry(entry, index)
		var room := _instantiate_room(entry)

		if index == 0:
			if entry.has_parent_connection():
				push_error("First room chain entry '%s' must not define connector attachment fields." % entry.room_key)
			generated_rooms_container.add_child(room)
			room.transform = Transform3D.IDENTITY
		else:
			var parent_room := _get_generated_room(entry.connect_from_room_key)
			var from_connector := parent_room.get_connector(entry.connect_from_connector_id)
			var to_connector := room.get_connector(entry.connect_to_connector_id)
			_validate_connector_compatibility(from_connector, to_connector, entry)

			generated_rooms_container.add_child(room)
			room.transform = Transform3D.IDENTITY
			_align_room_to_connector(room, from_connector, to_connector)

		generated_rooms[entry.room_key] = room

	return generated_rooms


func get_generated_room(room_key: StringName) -> Room:
	return generated_rooms.get(room_key)


func _get_or_create_generated_rooms_container() -> Node3D:
	if get_parent().has_node("GeneratedRooms"):
		return get_parent().get_node("GeneratedRooms") as Node3D

	var container := Node3D.new()
	container.name = "GeneratedRooms"
	get_parent().add_child(container)
	return container


func _clear_generated_rooms_container() -> void:
	for child in generated_rooms_container.get_children():
		child.queue_free()


func _validate_entry(entry: RoomChainEntry, index: int) -> void:
	if not entry:
		push_error("LevelGenerator chain entry %d is null." % index)
		return
	if entry.room_key == "":
		push_error("LevelGenerator chain entry %d requires room_key." % index)
	if not entry.room_scene:
		push_error("LevelGenerator chain entry '%s' requires room_scene." % entry.room_key)
	if index > 0:
		if entry.connect_from_room_key == "":
			push_error("LevelGenerator chain entry '%s' requires connect_from_room_key." % entry.room_key)
		if entry.connect_from_connector_id == "":
			push_error("LevelGenerator chain entry '%s' requires connect_from_connector_id." % entry.room_key)
		if entry.connect_to_connector_id == "":
			push_error("LevelGenerator chain entry '%s' requires connect_to_connector_id." % entry.room_key)


func _instantiate_room(entry: RoomChainEntry) -> Room:
	var room := entry.room_scene.instantiate() as Room
	if not room:
		push_error("LevelGenerator entry '%s' did not instantiate a Room scene." % entry.room_key)
		return null

	room.name = String(entry.room_key)
	return room


func _get_generated_room(room_key: StringName) -> Room:
	var room := get_generated_room(room_key)
	if not room:
		push_error("LevelGenerator could not find generated room '%s'." % room_key)
	return room


func _align_room_to_connector(room: Room, from_connector: RoomConnector, to_connector: RoomConnector) -> void:
	var from_out := _flatten_direction(from_connector.get_outward_direction())
	var to_out := _flatten_direction(to_connector.get_outward_direction())
	var desired_to_out := -from_out

	var yaw := to_out.signed_angle_to(desired_to_out, Vector3.UP)
	room.rotate_y(yaw)

	var translation := from_connector.global_position - to_connector.global_position
	room.global_position += translation


func _validate_connector_compatibility(from_connector: RoomConnector, to_connector: RoomConnector, entry: RoomChainEntry) -> void:
	if not from_connector or not to_connector:
		return

	if from_connector.connector_type != to_connector.connector_type:
		push_error("Connector type mismatch for '%s': '%s' -> '%s'." % [entry.room_key, from_connector.connector_type, to_connector.connector_type])

	for required_tag in entry.get_required_tags():
		if not from_connector.get_tags().has(required_tag):
			push_error("Connector '%s' is missing required tag '%s'." % [from_connector.connector_id, required_tag])
		if not to_connector.get_tags().has(required_tag):
			push_error("Connector '%s' is missing required tag '%s'." % [to_connector.connector_id, required_tag])


func _flatten_direction(direction: Vector3) -> Vector3:
	direction.y = 0.0
	if direction.length() == 0.0:
		push_error("LevelGenerator found a connector with no horizontal facing direction.")
		return Vector3.FORWARD
	return direction.normalized()
