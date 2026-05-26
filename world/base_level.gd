extends Node3D
class_name BaseLevel

## Reusable base for all levels / "worlds".
## Handles common level concerns (environment, lighting, spawn points, etc.)
## Future levels can extend this or use it as a template.

@export var level_name: String = "Unnamed Level"

# Called when the level is fully ready (after _ready and children are processed)
signal level_ready

func _ready() -> void:
	# Emit after everything in the level has initialized
	call_deferred("_emit_level_ready")

func _emit_level_ready() -> void:
	level_ready.emit()

## Helper to find player spawn points.
## Looks for Marker3D nodes that came from TrenchBroom `info_player_start`.
## Searches recursively because FuncGodot nests entities under the imported map.
func get_player_spawns() -> Array[Marker3D]:
	var spawns: Array[Marker3D] = []
	_find_player_spawns_recursive(self, spawns)
	return spawns


func _find_player_spawns_recursive(node: Node, results: Array[Marker3D]) -> void:
	for child in node.get_children():
		if child is Marker3D and "player_start" in child.name.to_lower():
			results.append(child)
		
		# Recurse into all children (we don't know how deep FuncGodot nests things)
		_find_player_spawns_recursive(child, results)


## Spawns a player at the first available player spawn point.
## Returns the spawned player, or null if no spawn point was found.
func spawn_player(player_scene: PackedScene) -> Node3D:
	var spawns := get_player_spawns()
	
	if spawns.is_empty():
		push_warning("No player spawn points found in level '%s'. Make sure an info_player_start exists in the TrenchBroom map." % level_name)
		return null
	
	var spawn_point := spawns[0]
	var player := player_scene.instantiate()
	
	add_child(player)
	player.global_transform = spawn_point.global_transform
	
	print("BaseLevel: Spawned player at ", player.global_position, " using spawn point: ", spawn_point.name)
	
	return player

