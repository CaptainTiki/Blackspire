@tool
extends Marker3D
class_name EnemySpawnMarker

@export var elite := false


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("elite"):
		elite = _parse_bool(properties["elite"])


func is_elite_spawn() -> bool:
	return elite


func _parse_bool(value: Variant) -> bool:
	if value is bool:
		return value

	var text := str(value).to_lower()
	return text == "true" or text == "1" or text == "yes"
