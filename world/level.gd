extends Node3D
class_name Level

static var current_level: Level

## Reusable base for all dungeon levels.
## Handles common level concerns (environment, lighting, spawn points, etc.).

@export var level_name: String = "Unnamed Level"
@export var basic_enemy_scene: PackedScene = preload("res://world/actors/enemies/basic_enemy.tscn")

var entity_registry: MapEntityRegistry
var spawned_enemies: Array[Node3D] = []

# Called when the level is fully ready (after _ready and children are processed)
signal level_ready

func _enter_tree() -> void:
	Level.current_level = self
	entity_registry = $MapEntityRegistry


func _exit_tree() -> void:
	if Level.current_level == self:
		Level.current_level = null


func _ready() -> void:
	# Emit after everything in the level has initialized
	call_deferred("_emit_level_ready")


func _emit_level_ready() -> void:
	_ensure_junk_container()
	spawn_enemies()
	level_ready.emit()


func get_map_entity_registry() -> MapEntityRegistry:
	return entity_registry


## Ensures a "Junk" container node exists in the level for temporary debris and effects.
func _ensure_junk_container() -> void:
	if not has_node("Junk"):
		var junk := Node3D.new()
		junk.name = "Junk"
		add_child(junk)


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


func get_enemy_spawns() -> Array[Marker3D]:
	var spawns: Array[Marker3D] = []
	_find_enemy_spawns_recursive(self, spawns)
	return spawns


func _find_enemy_spawns_recursive(node: Node, results: Array[Marker3D]) -> void:
	for child in node.get_children():
		if child is Marker3D and "enemy_spawn" in child.name.to_lower():
			results.append(child)

		_find_enemy_spawns_recursive(child, results)


func spawn_enemies() -> Array[Node3D]:
	var spawns := get_enemy_spawns()
	for spawn_point in spawns:
		var enemy := basic_enemy_scene.instantiate() as Node3D
		add_child(enemy)
		enemy.global_transform = spawn_point.global_transform
		spawned_enemies.append(enemy)
		print("Level: Spawned enemy at ", enemy.global_position, " using spawn point: ", spawn_point.name)

	return spawned_enemies


## Spawns a player at the first available player spawn point.
## Returns the spawned player.
## 
## NOTE: This currently does a recursive search because FuncGodot nests entities.
## This is acknowledged as a temporary concession. Long-term we should move to
## explicit registration or groups instead of tree walking.
func spawn_player(player_scene: PackedScene) -> Node3D:
	var spawns := get_player_spawns()
	
	if spawns.is_empty():
		push_error("No player spawn points found in level '%s'. Make sure an info_player_start exists in the TrenchBroom map." % level_name)
		# In prototype we still try to continue rather than hard crash the whole level
		return null
	
	var spawn_point := spawns[0]
	var player := player_scene.instantiate()
	
	add_child(player)
	player.global_transform = spawn_point.global_transform
	
	print("Level: Spawned player at ", player.global_position, " using spawn point: ", spawn_point.name)
	
	return player
