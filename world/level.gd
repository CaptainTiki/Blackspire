extends Node3D
class_name Level

static var current_level: Level

## Reusable base for all dungeon levels.
## Handles common level concerns (environment, lighting, spawn points, etc.).

@export var level_name: String = "Unnamed Level"
@export var basic_enemy_scene: PackedScene = preload("res://world/actors/enemies/basic_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://world/actors/enemies/elite_enemy.tscn")

var entity_registry: MapEntityRegistry
var spawned_enemies: Array[Node3D] = []
var is_run_completed := false
var run_complete_message := ""

@onready var level_generator: LevelGenerator = $LevelGenerator

# Called when the level is fully ready (after _ready and children are processed)
signal level_ready
signal run_completed(actor: Node)

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
	level_generator.generate()
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
		var enemy_scene := _get_enemy_scene_for_spawn(spawn_point)
		var enemy := enemy_scene.instantiate() as Node3D
		var authored_scale := enemy.scale
		add_child(enemy)
		enemy.global_transform = spawn_point.global_transform
		enemy.scale = authored_scale
		spawned_enemies.append(enemy)
		print("Level: Spawned ", _get_enemy_spawn_label(spawn_point), " enemy at ", enemy.global_position, " using spawn point: ", spawn_point.name)

	return spawned_enemies


func has_living_enemies() -> bool:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			return true
	return false


func complete_run(actor: Node, message: String = "Run Complete") -> void:
	if is_run_completed:
		return

	is_run_completed = true
	run_complete_message = message
	run_completed.emit(actor)
	print("Level: Run complete - ", message)
	_show_run_complete_overlay(message)
	get_tree().paused = true


func _show_run_complete_overlay(message: String) -> void:
	if has_node("RunCompleteOverlay"):
		get_node("RunCompleteOverlay").queue_free()

	var overlay := CanvasLayer.new()
	overlay.name = "RunCompleteOverlay"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var label := Label.new()
	label.text = "%s\nLoot Secured\nPrototype Loop Closed" % message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 42)
	overlay.add_child(label)


func _get_enemy_scene_for_spawn(spawn_point: Marker3D) -> PackedScene:
	if spawn_point is EnemySpawnMarker and spawn_point.is_elite_spawn():
		return elite_enemy_scene

	return basic_enemy_scene


func _get_enemy_spawn_label(spawn_point: Marker3D) -> String:
	if spawn_point is EnemySpawnMarker and spawn_point.is_elite_spawn():
		return "elite"

	return "basic"


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
