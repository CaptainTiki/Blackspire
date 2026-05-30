@tool
extends Node3D
class_name RoomConnector

@export var connector_id: StringName = &""
@export var connector_type: StringName = &"doorway"
@export var tags := "crypt standard"
@export var door_width_units := 64
@export var door_height_units := 64


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_validate()


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("connector_id"):
		connector_id = StringName(properties["connector_id"])
	if properties.has("connector_type"):
		connector_type = StringName(properties["connector_type"])
	if properties.has("tags"):
		tags = str(properties["tags"])
	if properties.has("door_width_units"):
		door_width_units = int(properties["door_width_units"])
	if properties.has("door_height_units"):
		door_height_units = int(properties["door_height_units"])


func get_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	var normalized_tags := tags.replace(",", " ")
	for raw_tag in normalized_tags.split(" ", false):
		result.append(StringName(raw_tag))
	return result


func get_outward_direction() -> Vector3:
	return -global_transform.basis.z.normalized()


func _validate() -> void:
	if connector_id == "":
		push_error("RoomConnector %s requires connector_id." % get_path())
	if connector_type == "":
		push_error("RoomConnector %s requires connector_type." % get_path())
	if door_width_units <= 0:
		push_error("RoomConnector %s requires door_width_units > 0." % get_path())
	if door_height_units <= 0:
		push_error("RoomConnector %s requires door_height_units > 0." % get_path())
