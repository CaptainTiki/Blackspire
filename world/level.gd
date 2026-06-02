extends Node3D
class_name Level

static var current_level: Level

## Reusable base for all dungeon levels.
## Handles common level concerns (environment, lighting, spawn points, etc.).

@export var level_name: String = "Unnamed Level"
@export var basic_enemy_scene: PackedScene = preload("res://world/actors/enemies/basic_enemy.tscn")
@export var elite_enemy_scene: PackedScene = preload("res://world/actors/enemies/elite_enemy.tscn")
@export var show_run_end_overlays := true
@export var pause_on_run_end := true

var entity_registry: MapEntityRegistry
var spawned_enemies: Array[Node3D] = []
var active_players: Array[PlayerController] = []
var is_run_completed := false
var is_run_failed := false
var is_extraction_in_progress := false
var is_extraction_ready := false
var run_complete_message := ""
var extracting_player: PlayerController
var extraction_remaining_seconds := 0.0
var extraction_duration_seconds := 0.0
var _extraction_label: Label
var _next_enemy_network_id := 0

@onready var level_generator: LevelGenerator = $LevelGenerator

# Called when the level is fully ready (after _ready and children are processed)
signal level_ready
signal extraction_started(player: PlayerController, duration_seconds: float)
signal extraction_ready(player: PlayerController)
signal player_bleeding_out(player: PlayerController)
signal player_died(player: PlayerController)
signal run_completed(actor: Node)
signal run_failed(reason: String)
signal player_exited_level(player: PlayerController)
signal enemy_died(enemy_id: int)

func _enter_tree() -> void:
	Level.current_level = self
	entity_registry = $MapEntityRegistry


func _exit_tree() -> void:
	if Level.current_level == self:
		Level.current_level = null


func _ready() -> void:
	# Emit after everything in the level has initialized
	call_deferred("_emit_level_ready")


func _process(delta: float) -> void:
	_process_extraction_countdown(delta)


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
		var enemy := enemy_scene.instantiate() as BasicEnemy
		var authored_scale := enemy.scale
		add_child(enemy)
		enemy.global_transform = spawn_point.global_transform
		enemy.scale = authored_scale
		enemy.set_network_enemy_id(_next_enemy_network_id)
		_next_enemy_network_id += 1
		enemy.health.died.connect(_on_enemy_health_died.bind(enemy))
		spawned_enemies.append(enemy)
		print("Level: Spawned ", _get_enemy_spawn_label(spawn_point), " enemy at ", enemy.global_position, " using spawn point: ", spawn_point.name)

	return spawned_enemies


func set_enemy_network_authority_enabled(is_enabled: bool) -> void:
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("set_network_authority_enabled"):
			enemy.set_network_authority_enabled(is_enabled)


func get_enemy_for_network_id(enemy_id: int) -> BasicEnemy:
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is BasicEnemy and enemy.network_enemy_id == enemy_id:
			return enemy

	return null


func get_enemy_network_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("get_network_state"):
			snapshot.append(enemy.get_network_state())

	return snapshot


func _on_enemy_health_died(_damage_request: Variant, enemy: BasicEnemy) -> void:
	if not is_instance_valid(enemy):
		return

	enemy_died.emit(enemy.network_enemy_id)


func has_living_enemies() -> bool:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			return true
	return false


func register_player(player: PlayerController) -> void:
	if active_players.has(player):
		return

	active_players.append(player)


func notify_player_bleeding_out(player: PlayerController) -> void:
	register_player(player)
	player_bleeding_out.emit(player)
	print("Level: Player bleeding out - ", player.name)
	_evaluate_player_failure_state()


func notify_player_died(player: PlayerController) -> void:
	register_player(player)
	player_died.emit(player)
	print("Level: Player died - ", player.name)
	_evaluate_player_failure_state()


func interact_with_extraction(player: PlayerController, delay_seconds: float) -> void:
	if is_run_completed or is_run_failed:
		return
	if is_extraction_ready:
		exit_level(player)
		return
	if is_extraction_in_progress:
		print("Level: Extraction charging - %.1f seconds remain." % extraction_remaining_seconds)
		return

	begin_extraction(player, delay_seconds)


func begin_extraction(player: PlayerController, delay_seconds: float) -> void:
	if is_run_completed or is_run_failed:
		return
	if is_extraction_in_progress:
		print("Level: Extraction charging - %.1f seconds remain." % extraction_remaining_seconds)
		return

	extracting_player = player
	extraction_duration_seconds = maxf(delay_seconds, 0.0)
	extraction_remaining_seconds = extraction_duration_seconds
	is_extraction_in_progress = true
	is_extraction_ready = false

	_alert_living_enemies_to_player(player)
	extraction_started.emit(player, extraction_duration_seconds)
	print("Level: Extraction started - %.1f second delay." % extraction_duration_seconds)

	_show_extraction_countdown_overlay()
	if extraction_duration_seconds == 0.0:
		_mark_extraction_ready()


func exit_level(player: PlayerController) -> void:
	if is_run_completed or is_run_failed:
		return

	is_run_completed = true
	is_extraction_in_progress = false
	is_extraction_ready = false
	run_complete_message = player.get_level_exit_summary()
	_remove_extraction_countdown_overlay()
	player_exited_level.emit(player)
	run_completed.emit(player)
	print("Level: Player exited level - ", run_complete_message)
	if show_run_end_overlays:
		_show_run_complete_overlay(run_complete_message)
	if pause_on_run_end:
		get_tree().paused = true


func fail_level(reason: String = "All Players Are Down") -> void:
	if is_run_completed or is_run_failed:
		return

	is_run_failed = true
	is_extraction_in_progress = false
	is_extraction_ready = false
	_remove_extraction_countdown_overlay()
	run_failed.emit(reason)
	print("Level: Run failed - ", reason)
	if show_run_end_overlays:
		_show_run_failed_overlay(reason)
	if pause_on_run_end:
		get_tree().paused = true


func complete_run(actor: Node, _message: String = "Run Complete") -> void:
	var player := actor as PlayerController
	if not player:
		push_error("Level.complete_run now requires a PlayerController actor.")
		return

	exit_level(player)


func _show_run_complete_overlay(exit_summary: String) -> void:
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
	label.text = "Run Complete\n%s\nPrototype Loop Closed" % exit_summary
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 42)
	overlay.add_child(label)


func _show_run_failed_overlay(reason: String) -> void:
	if has_node("RunFailedOverlay"):
		get_node("RunFailedOverlay").queue_free()

	var overlay := CanvasLayer.new()
	overlay.name = "RunFailedOverlay"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var label := Label.new()
	label.text = "%s\nRun Failed" % reason
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 42)
	overlay.add_child(label)


func _process_extraction_countdown(delta: float) -> void:
	if not is_extraction_in_progress:
		return
	if is_run_completed:
		return
	if not is_instance_valid(extracting_player):
		push_error("Level extraction failed because the extracting player no longer exists.")
		is_extraction_in_progress = false
		_remove_extraction_countdown_overlay()
		return

	extraction_remaining_seconds = maxf(extraction_remaining_seconds - delta, 0.0)
	_update_extraction_countdown_overlay()

	if extraction_remaining_seconds == 0.0 and not is_extraction_ready:
		_mark_extraction_ready()


func _evaluate_player_failure_state() -> void:
	if is_run_completed or is_run_failed:
		return
	if active_players.is_empty():
		return

	for player in active_players:
		if not is_instance_valid(player):
			continue
		if not player.is_bleeding_out_or_dead():
			return

	fail_level("All Players Are Down")


func _alert_living_enemies_to_player(player: PlayerController) -> void:
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue

		enemy.alert_to_player(player)


func _show_extraction_countdown_overlay() -> void:
	_remove_extraction_countdown_overlay()

	var overlay := CanvasLayer.new()
	overlay.name = "ExtractionCountdownOverlay"
	add_child(overlay)

	_extraction_label = Label.new()
	_extraction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_extraction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_extraction_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_extraction_label.offset_top = 24.0
	_extraction_label.offset_bottom = 84.0
	_extraction_label.add_theme_font_size_override("font_size", 34)
	overlay.add_child(_extraction_label)
	_update_extraction_countdown_overlay()


func _mark_extraction_ready() -> void:
	is_extraction_ready = true
	extraction_ready.emit(extracting_player)
	print("Level: Extraction ready. Interact with the portal to exit.")
	_update_extraction_countdown_overlay()


func _update_extraction_countdown_overlay() -> void:
	if not _extraction_label:
		return

	if is_extraction_ready:
		_extraction_label.text = "Extraction Ready"
	else:
		_extraction_label.text = "Extraction in %d" % ceili(extraction_remaining_seconds)


func _remove_extraction_countdown_overlay() -> void:
	if has_node("ExtractionCountdownOverlay"):
		get_node("ExtractionCountdownOverlay").queue_free()

	_extraction_label = null


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
	register_player(player)
	
	print("Level: Spawned player at ", player.global_position, " using spawn point: ", spawn_point.name)
	
	return player
