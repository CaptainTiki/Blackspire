class_name Game
extends Node

const CrewStashInventoryScript := preload("res://system/crew_stash_inventory.gd")
const CrewStashUIScript := preload("res://system/ui/crew_stash_ui.gd")
const DamageRequestScript := preload("res://world/components/combat/damage_request.gd")
const NetworkSessionScript := preload("res://system/network/network_session.gd")

const SESSION_WORLD_HUB := "hub"
const SESSION_WORLD_RUN := "run"
const NETWORK_TRANSFORM_SEND_INTERVAL := 0.05
const NETWORK_ENEMY_SEND_INTERVAL := 0.1
const PLAYER_ACTION_PRIMARY := "primary_action"

## The central "session" container.
## Main creates one of these and tells it what kind of game to run.
##
## Game is responsible for:
## - Loading the appropriate starting scene (Hub or directly into a level)
## - Owning the PlayerSlotManager
## - Managing transitions between Hub <-> Dungeon runs
## - Owning the current world content

@onready var player_slot_manager: PlayerSlotManager = $PlayerSlotManager
@onready var network_session: Node = $NetworkSession

@export var hub_scene: PackedScene = preload("res://world/hub/hub.tscn")
@export var test_level_scene: PackedScene = preload("res://world/levels/test_level.tscn")
@export var player_scene: PackedScene = preload("res://world/actors/player/Player.tscn")

var current_session: GameSessionConfig
var current_world: Node = null   # Will hold Hub or Level later
var crew_stash_inventory: Node
var split_screen_layer: CanvasLayer
var split_screen_root: Control
var last_run_summary := "No run completed yet"
var _network_transform_send_elapsed := 0.0
var _network_enemy_send_elapsed := 0.0
var _pending_spawn_assignments: Array = []
var _known_dead_enemy_ids: Array[int] = []


func start_session(config: GameSessionConfig) -> void:
	current_session = config
	print("Game: Starting session of type ", GameSessionConfig.SessionType.keys()[config.session_type])

	_configure_network_session(config)
	player_slot_manager.create_local_session_slots(config.local_player_count)
	_create_crew_stash_inventory()

	_load_hub(last_run_summary)


func _configure_network_session(config: GameSessionConfig) -> void:
	network_session.peer_joined.connect(_on_network_peer_joined)
	network_session.peer_left.connect(_on_network_peer_left)
	network_session.connected_to_host.connect(_on_network_connected_to_host)
	network_session.connection_failed.connect(_on_network_connection_failed)
	network_session.host_disconnected.connect(_on_network_host_disconnected)

	match config.session_type:
		GameSessionConfig.SessionType.MULTIPLAYER_HOST:
			network_session.start_host(config.host_port, config.max_player_count)
		GameSessionConfig.SessionType.MULTIPLAYER_CLIENT:
			network_session.join_host(config.host_address, config.host_port)
		_:
			network_session.close_session()


func _load_hub(summary: String = "No run completed yet") -> void:
	if not hub_scene:
		push_error("Game: No hub_scene assigned!")
		return

	_network_enemy_send_elapsed = 0.0
	_known_dead_enemy_ids.clear()
	_clear_current_world()

	var hub := hub_scene.instantiate()
	if not hub or not hub.has_method("get_player_spawns"):
		push_error("Game: hub_scene must instantiate a Hub.")
		return

	current_world = hub
	add_child(current_world)
	hub.deploy_requested.connect(_on_hub_deploy_requested)
	hub.stash_requested.connect(_on_hub_stash_requested)
	hub.show_run_summary(summary)

	var players := player_slot_manager.spawn_or_move_slot_players(hub, hub.get_player_spawns(), player_scene, null, _pending_spawn_assignments)
	if players.is_empty():
		push_error("Game: PlayerSlotManager did not place any local players in the hub.")
		return

	_restore_players_for_hub()
	_apply_slot_presence_debug_to_all()
	_bind_player_action_events_to_all()
	_ensure_local_coop_viewports()

	print("Game: Loaded hub with %d session player(s)." % players.size())


func _on_network_peer_joined(peer_id: int) -> void:
	print("Game: Network peer joined session: %d" % peer_id)
	if not network_session.is_host:
		return

	var slot := player_slot_manager.add_remote_slot(peer_id)
	_place_joined_remote_slot(slot)
	_broadcast_session_membership()
	_send_session_transition_to_peer(peer_id)


func _on_network_peer_left(peer_id: int) -> void:
	print("Game: Network peer left session: %d" % peer_id)
	if not network_session.is_host:
		return

	player_slot_manager.remove_remote_slot(peer_id)
	_broadcast_session_membership()


func _on_network_connected_to_host() -> void:
	print("Game: Connected to multiplayer host.")
	player_slot_manager.set_local_peer_id(network_session.local_peer_id)


func _on_network_connection_failed() -> void:
	print("Game: Multiplayer connection failed.")


func _on_network_host_disconnected() -> void:
	print("Game: Multiplayer host disconnected.")


func _place_joined_remote_slot(slot: PlayerSlot) -> void:
	if not slot:
		return
	_place_slot_in_current_world(slot)


func _place_all_slots_in_current_world() -> void:
	for slot in player_slot_manager.slots:
		_place_slot_in_current_world(slot)


func _place_slot_in_current_world(slot: PlayerSlot) -> void:
	if not slot:
		return
	if not current_world:
		return

	var world_root := current_world as Node3D
	if not world_root:
		push_error("Game: Current world must be Node3D to place remote slots.")
		return
	if not world_root.has_method("get_player_spawns"):
		push_error("Game: Current world cannot provide player spawns for remote slots.")
		return

	var level := current_world as Level
	var player := player_slot_manager.spawn_or_move_slot_player(
		slot,
		world_root,
		world_root.get_player_spawns(),
		player_scene,
		level,
		player_slot_manager.get_local_player_count() == 1
	)
	if not player:
		return

	_restore_player_for_session_presence(player)
	_apply_slot_presence_debug(slot, player)
	_bind_player_action_events(slot)
	_ensure_local_coop_viewports()


func _apply_slot_presence_debug(slot: PlayerSlot, player: PlayerController) -> void:
	var label := player.get_node_or_null("SessionDebugLabel") as Label3D
	if not label:
		label = Label3D.new()
		label.name = "SessionDebugLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0.0, 1.85, 0.0)
		label.font_size = 26
		label.modulate = Color(0.65, 0.9, 1.0, 1.0) if slot.is_local else Color(1.0, 0.82, 0.35, 1.0)
		player.add_child(label)

	label.text = "%s\npeer %d" % [slot.display_name, slot.peer_id]


func _apply_slot_presence_debug_to_all() -> void:
	for slot in player_slot_manager.slots:
		if not is_instance_valid(slot.player):
			continue

		_apply_slot_presence_debug(slot, slot.player)


func _restore_player_for_session_presence(player: PlayerController) -> void:
	var life_state := player.life_state as PlayerLifeState
	var health := player.health as HealthComponent
	if life_state and life_state.is_bleeding_out_or_dead():
		life_state.revive(health.max_health if health else -1)
	elif health:
		health.heal(maxi(health.max_health - health.current_health, 1))


func _load_starting_world(spawn_assignments: Array = []) -> void:
	if not test_level_scene:
		push_error("Game: No test_level_scene assigned!")
		return

	_network_enemy_send_elapsed = 0.0
	_known_dead_enemy_ids.clear()
	_pending_spawn_assignments = spawn_assignments
	_clear_current_world()

	var level := test_level_scene.instantiate() as Level
	if not level:
		push_error("Game: test_level_scene must instantiate a Level.")
		return

	current_world = level
	add_child(current_world)
	level.show_run_end_overlays = false
	level.pause_on_run_end = false
	level.run_completed.connect(_on_run_completed)
	level.run_failed.connect(_on_run_failed)

	print("Game: Loaded test level as temporary world for session type: ", 
		GameSessionConfig.SessionType.keys()[current_session.session_type])

	level.level_ready.connect(_on_level_ready, CONNECT_ONE_SHOT)


func _host_load_run() -> void:
	if network_session.is_client():
		push_error("Game: Clients cannot host-load the run.")
		return

	var transition := _build_session_transition(SESSION_WORLD_RUN, last_run_summary)
	_broadcast_session_transition(transition)
	_apply_session_transition_locally(transition)


func _host_load_hub(summary: String = "No run completed yet") -> void:
	if network_session.is_client():
		push_error("Game: Clients cannot host-load the hub.")
		return

	var transition := _build_session_transition(SESSION_WORLD_HUB, summary)
	_broadcast_session_transition(transition)
	_apply_session_transition_locally(transition)


func _request_host_deploy() -> void:
	if not network_session.is_client():
		push_error("Game: Only multiplayer clients should request host deploy.")
		return

	print("Game: Requesting host deploy.")
	_server_request_deploy.rpc_id(NetworkSessionScript.HOST_PEER_ID)


@rpc("any_peer", "call_remote", "reliable")
func _server_request_deploy() -> void:
	if not network_session.is_host:
		push_error("Game: Non-host received deploy request.")
		return

	var sender_id := multiplayer.get_remote_sender_id()
	if not player_slot_manager.get_slot_for_peer(sender_id):
		push_error("Game: Deploy request from unknown peer %d." % sender_id)
		return
	if _has_any_open_stash_ui():
		push_error("Game: Deploy requested while stash UI is open.")
		return

	print("Game: Host accepted deploy request from peer %d." % sender_id)
	_host_load_run()


func _broadcast_session_transition(transition: Dictionary) -> void:
	if not network_session.is_host:
		return

	_client_apply_session_transition.rpc(transition)


func _send_session_transition_to_peer(peer_id: int) -> void:
	if not network_session.is_host:
		return
	if current_world is Level:
		_client_apply_session_transition.rpc_id(peer_id, _build_session_transition(SESSION_WORLD_RUN, last_run_summary))
	else:
		_client_apply_session_transition.rpc_id(peer_id, _build_session_transition(SESSION_WORLD_HUB, last_run_summary))


func _broadcast_session_membership() -> void:
	if not network_session.is_host:
		return

	_client_apply_session_membership.rpc(player_slot_manager.get_session_snapshot())


@rpc("authority", "call_remote", "reliable")
func _client_apply_session_membership(snapshot: Array) -> void:
	if not network_session.is_client():
		return

	player_slot_manager.apply_session_snapshot(snapshot, network_session.local_peer_id)
	_place_all_slots_in_current_world()


func _build_session_transition(world_key: String, summary: String = "") -> Dictionary:
	return {
		"world_key": world_key,
		"summary": summary,
		"membership": player_slot_manager.get_session_snapshot(),
		"spawn_assignments": player_slot_manager.get_spawn_assignments(),
	}


func _apply_session_transition_locally(transition: Dictionary) -> void:
	var world_key := str(transition["world_key"])
	var summary := str(transition.get("summary", ""))
	var spawn_assignments := transition.get("spawn_assignments", []) as Array

	match world_key:
		SESSION_WORLD_HUB:
			last_run_summary = summary
			_pending_spawn_assignments = spawn_assignments
			_load_hub(summary)
		SESSION_WORLD_RUN:
			_load_starting_world(spawn_assignments)
		_:
			push_error("Game: Unknown session world key '%s'." % world_key)


@rpc("authority", "call_remote", "reliable")
func _client_apply_session_transition(transition: Dictionary) -> void:
	if not network_session.is_client():
		return

	if not transition.has("membership"):
		push_error("Game: Session transition requires a membership snapshot.")
		return
	if not transition.has("spawn_assignments"):
		push_error("Game: Session transition requires spawn assignments.")
		return

	player_slot_manager.apply_session_snapshot(transition["membership"], network_session.local_peer_id)
	_apply_session_transition_locally(transition)


@rpc("authority", "call_remote", "reliable")
func _client_load_session_world(world_key: String, summary: String = "") -> void:
	if not network_session.is_client():
		return

	print("Game: Client loading session world: %s" % world_key)
	match world_key:
		SESSION_WORLD_HUB:
			last_run_summary = summary
			_load_hub(summary)
		SESSION_WORLD_RUN:
			_load_starting_world()
		_:
			push_error("Game: Unknown session world key '%s'." % world_key)


func _on_level_ready() -> void:
	var level := current_world as Level
	var players := player_slot_manager.spawn_slot_players(level, player_scene, _pending_spawn_assignments)
	if players.is_empty():
		push_error("Game: PlayerSlotManager did not spawn any local players.")
		return

	_apply_slot_presence_debug_to_all()
	_bind_player_action_events_to_all()
	_configure_enemy_network_authority()
	_bind_level_enemy_events(level)
	_ensure_local_coop_viewports()

	print("Game: Spawned %d session player(s)." % players.size())


func _process(_delta: float) -> void:
	_sync_split_screen_cameras()


func _physics_process(delta: float) -> void:
	_process_network_transform_sync(delta)
	_process_network_enemy_sync(delta)


func _process_network_transform_sync(delta: float) -> void:
	if not network_session.is_online_session():
		return

	_network_transform_send_elapsed += delta
	if _network_transform_send_elapsed < NETWORK_TRANSFORM_SEND_INTERVAL:
		return

	_network_transform_send_elapsed = 0.0
	if network_session.is_host:
		_broadcast_player_transform_snapshot()
	else:
		if not network_session.is_connected_to_host():
			return
		_send_local_player_transforms_to_host()


func _process_network_enemy_sync(delta: float) -> void:
	if not network_session.is_online_session():
		return
	if not network_session.is_host:
		return

	var level := current_world as Level
	if not level:
		return

	_network_enemy_send_elapsed += delta
	if _network_enemy_send_elapsed < NETWORK_ENEMY_SEND_INTERVAL:
		return

	_network_enemy_send_elapsed = 0.0
	var snapshot := level.get_enemy_network_snapshot()
	if snapshot.is_empty():
		return

	_client_apply_enemy_snapshot.rpc(snapshot)
	_broadcast_new_enemy_deaths(snapshot)


func _send_local_player_transforms_to_host() -> void:
	for slot in player_slot_manager.slots:
		if not slot.is_local:
			continue
		if not is_instance_valid(slot.player):
			continue

		var state := slot.player.get_network_transform_state()
		_server_receive_player_transform.rpc_id(
			NetworkSessionScript.HOST_PEER_ID,
			slot.session_player_id,
			state["position"],
			state["body_yaw"],
			state["camera_pitch"]
		)


@rpc("any_peer", "call_remote", "unreliable")
func _server_receive_player_transform(session_player_id: int, position: Vector3, body_yaw: float, camera_pitch: float) -> void:
	if not network_session.is_host:
		push_error("Game: Non-host received player transform update.")
		return

	var sender_id := multiplayer.get_remote_sender_id()
	var slot := player_slot_manager.get_slot_for_session_player(session_player_id)
	if not slot:
		push_error("Game: Transform update for unknown session player %d." % session_player_id)
		return
	if slot.peer_id != sender_id:
		push_error("Game: Peer %d tried to update session player %d owned by peer %d." % [sender_id, session_player_id, slot.peer_id])
		return
	if not is_instance_valid(slot.player):
		return

	slot.player.apply_network_transform_state(position, body_yaw, camera_pitch)


func _broadcast_player_transform_snapshot() -> void:
	if not network_session.is_host:
		return

	var snapshot: Array[Dictionary] = []
	for slot in player_slot_manager.slots:
		if not is_instance_valid(slot.player):
			continue

		var state := slot.player.get_network_transform_state()
		snapshot.append({
			"session_player_id": slot.session_player_id,
			"position": state["position"],
			"body_yaw": state["body_yaw"],
			"camera_pitch": state["camera_pitch"],
		})

	if snapshot.is_empty():
		return

	_client_apply_player_transform_snapshot.rpc(snapshot)


@rpc("authority", "call_remote", "unreliable")
func _client_apply_player_transform_snapshot(snapshot: Array) -> void:
	if not network_session.is_client():
		return

	for raw_entry in snapshot:
		if not raw_entry is Dictionary:
			push_error("Game: Player transform snapshot entries must be dictionaries.")
			return

		var entry := raw_entry as Dictionary
		var slot := player_slot_manager.get_slot_for_session_player(int(entry["session_player_id"]))
		if not slot:
			continue
		if slot.is_local:
			continue
		if not is_instance_valid(slot.player):
			continue

		slot.player.apply_network_transform_state(
			entry["position"],
			float(entry["body_yaw"]),
			float(entry["camera_pitch"])
		)


func _configure_enemy_network_authority() -> void:
	var level := current_world as Level
	if not level:
		return

	if not network_session.is_online_session():
		level.set_enemy_network_authority_enabled(true)
		return

	level.set_enemy_network_authority_enabled(network_session.is_host)


func _bind_level_enemy_events(level: Level) -> void:
	var callback := Callable(self, "_on_host_enemy_died")
	if not level.enemy_died.is_connected(callback):
		level.enemy_died.connect(callback)


func _on_host_enemy_died(enemy_id: int) -> void:
	if not network_session.is_online_session():
		return
	if not network_session.is_host:
		return
	if _known_dead_enemy_ids.has(enemy_id):
		return

	_known_dead_enemy_ids.append(enemy_id)
	_client_apply_enemy_death.rpc(enemy_id)


func _broadcast_new_enemy_deaths(snapshot: Array) -> void:
	for raw_entry in snapshot:
		if not raw_entry is Dictionary:
			push_error("Game: Enemy snapshot entries must be dictionaries.")
			return

		var entry := raw_entry as Dictionary
		if not bool(entry["is_dead"]):
			continue

		var enemy_id := int(entry["enemy_id"])
		if _known_dead_enemy_ids.has(enemy_id):
			continue

		_known_dead_enemy_ids.append(enemy_id)
		_client_apply_enemy_death.rpc(enemy_id)


@rpc("authority", "call_remote", "unreliable")
func _client_apply_enemy_snapshot(snapshot: Array) -> void:
	if not network_session.is_client():
		return

	var level := current_world as Level
	if not level:
		return

	for raw_entry in snapshot:
		if not raw_entry is Dictionary:
			push_error("Game: Enemy snapshot entries must be dictionaries.")
			return

		var entry := raw_entry as Dictionary
		var enemy := level.get_enemy_for_network_id(int(entry["enemy_id"]))
		if not enemy:
			continue

		enemy.apply_network_state(
			entry["position"],
			float(entry["body_yaw"]),
			bool(entry["is_dead"])
		)


@rpc("authority", "call_remote", "reliable")
func _client_apply_enemy_death(enemy_id: int) -> void:
	if not network_session.is_client():
		return

	var level := current_world as Level
	if not level:
		return

	var enemy := level.get_enemy_for_network_id(enemy_id)
	if not enemy:
		return

	enemy.apply_network_death()


func _bind_player_action_events_to_all() -> void:
	for slot in player_slot_manager.slots:
		_bind_player_action_events(slot)


func _bind_player_action_events(slot: PlayerSlot) -> void:
	if not slot:
		return
	if not is_instance_valid(slot.player):
		return

	var melee_attack := slot.player.get_node("Components/PlayerMeleeAttack") as PlayerMeleeAttack
	var primary_callback := Callable(self, "_on_player_primary_action_started")
	if not melee_attack.primary_action_started.is_connected(primary_callback):
		melee_attack.primary_action_started.connect(primary_callback)

	var hit_callback := Callable(self, "_on_player_damage_area_hit")
	if not melee_attack.damage_area_hit.is_connected(hit_callback):
		melee_attack.damage_area_hit.connect(hit_callback)


func _on_player_primary_action_started(player: PlayerController) -> void:
	var slot := _get_slot_for_player(player)
	if not slot:
		push_error("Game: Primary action started by a player with no slot.")
		return
	if not network_session.is_online_session():
		return

	if network_session.is_host:
		_broadcast_player_action_event(slot.session_player_id, PLAYER_ACTION_PRIMARY)
		return

	if not network_session.is_connected_to_host():
		return

	_server_receive_player_action.rpc_id(
		NetworkSessionScript.HOST_PEER_ID,
		slot.session_player_id,
		PLAYER_ACTION_PRIMARY
	)


@rpc("any_peer", "call_remote", "reliable")
func _server_receive_player_action(session_player_id: int, action_key: String) -> void:
	if not network_session.is_host:
		push_error("Game: Non-host received player action event.")
		return

	var sender_id := multiplayer.get_remote_sender_id()
	var slot := player_slot_manager.get_slot_for_session_player(session_player_id)
	if not slot:
		push_error("Game: Action event for unknown session player %d." % session_player_id)
		return
	if slot.peer_id != sender_id:
		push_error("Game: Peer %d tried to send action for session player %d owned by peer %d." % [sender_id, session_player_id, slot.peer_id])
		return

	_play_player_action_presentation(slot, action_key)
	_broadcast_player_action_event(session_player_id, action_key)


func _broadcast_player_action_event(session_player_id: int, action_key: String) -> void:
	if not network_session.is_host:
		return

	_client_apply_player_action_event.rpc(session_player_id, action_key)


@rpc("authority", "call_remote", "reliable")
func _client_apply_player_action_event(session_player_id: int, action_key: String) -> void:
	if not network_session.is_client():
		return

	var slot := player_slot_manager.get_slot_for_session_player(session_player_id)
	if not slot:
		return
	if slot.is_local:
		return

	_play_player_action_presentation(slot, action_key)


func _play_player_action_presentation(slot: PlayerSlot, action_key: String) -> void:
	if action_key != PLAYER_ACTION_PRIMARY:
		push_error("Game: Unknown player action key '%s'." % action_key)
		return
	if not is_instance_valid(slot.player):
		return

	var melee_attack := slot.player.get_node("Components/PlayerMeleeAttack") as PlayerMeleeAttack
	melee_attack.play_attack_presentation()


func _on_player_damage_area_hit(player: PlayerController, area: Area3D, damage_amount: int, hit_position: Vector3) -> void:
	if not network_session.is_online_session():
		return
	if network_session.is_host:
		return
	if not network_session.is_connected_to_host():
		return

	var slot := _get_slot_for_player(player)
	if not slot:
		push_error("Game: Damage hit came from a player with no slot.")
		return
	if not slot.is_local:
		return
	if not area is Hurtbox3D:
		return

	var hurtbox := area as Hurtbox3D
	var enemy := hurtbox.damage_target as BasicEnemy
	if not enemy:
		return

	_server_receive_enemy_damage.rpc_id(
		NetworkSessionScript.HOST_PEER_ID,
		slot.session_player_id,
		enemy.network_enemy_id,
		damage_amount,
		hit_position
	)


@rpc("any_peer", "call_remote", "reliable")
func _server_receive_enemy_damage(session_player_id: int, enemy_id: int, damage_amount: int, hit_position: Vector3) -> void:
	if not network_session.is_host:
		push_error("Game: Non-host received enemy damage event.")
		return

	var sender_id := multiplayer.get_remote_sender_id()
	var slot := player_slot_manager.get_slot_for_session_player(session_player_id)
	if not slot:
		push_error("Game: Enemy damage for unknown session player %d." % session_player_id)
		return
	if slot.peer_id != sender_id:
		push_error("Game: Peer %d tried to damage as session player %d owned by peer %d." % [sender_id, session_player_id, slot.peer_id])
		return

	var level := current_world as Level
	if not level:
		return

	var enemy := level.get_enemy_for_network_id(enemy_id)
	if not enemy:
		return
	if enemy.is_dead:
		return

	var bounded_damage := clampi(damage_amount, 0, 1000)
	if bounded_damage <= 0:
		return

	enemy.apply_damage(DamageRequestScript.new(slot.player, bounded_damage, hit_position))


func _on_hub_deploy_requested(_actor: PlayerController) -> void:
	if _has_any_open_stash_ui():
		if _actor and _actor.inventory:
			_actor.inventory.inventory_toast.emit("Close the stash before deploying")
		return

	if network_session.is_client():
		_request_host_deploy()
		return

	_host_load_run()


func _on_hub_stash_requested(actor: PlayerController) -> void:
	var player := actor as PlayerController
	if not player:
		push_error("Game._on_hub_stash_requested requires a PlayerController.")
		return

	_open_stash_ui(player)


func _on_run_completed(actor: Node) -> void:
	last_run_summary = _build_crew_exit_summary(actor)
	call_deferred("_host_load_hub", last_run_summary)


func _on_run_failed(reason: String) -> void:
	last_run_summary = "Failed: %s" % reason
	call_deferred("_host_load_hub", last_run_summary)


func _create_crew_stash_inventory() -> void:
	if crew_stash_inventory:
		crew_stash_inventory.queue_free()

	crew_stash_inventory = CrewStashInventoryScript.new()
	crew_stash_inventory.name = "CrewStashInventory"
	add_child(crew_stash_inventory)


func _open_stash_ui(player: PlayerController) -> void:
	var slot := _get_slot_for_player(player)
	if not slot:
		push_error("Game._open_stash_ui could not find a PlayerSlot for %s." % player.name)
		return

	_close_stash_ui_for_slot(slot)

	var ui: Control = CrewStashUIScript.new()
	ui.name = "CrewStashUI"
	ui.closed.connect(_on_stash_ui_closed.bind(slot))
	slot.stash_ui = ui

	if slot.split_screen_ui_root:
		slot.split_screen_ui_root.add_child(ui)
	else:
		slot.stash_canvas_layer = CanvasLayer.new()
		slot.stash_canvas_layer.name = "Player%dCrewStashLayer" % (slot.slot_index + 1)
		add_child(slot.stash_canvas_layer)
		slot.stash_canvas_layer.add_child(ui)

	ui.configure(player, crew_stash_inventory, not player.input_reader.owns_mouse)


func _close_stash_ui_for_slot(slot: PlayerSlot) -> void:
	if slot.stash_ui and is_instance_valid(slot.stash_ui):
		slot.stash_ui.queue_free()
	slot.stash_ui = null
	if slot.stash_canvas_layer and is_instance_valid(slot.stash_canvas_layer):
		slot.stash_canvas_layer.queue_free()
	slot.stash_canvas_layer = null


func _on_stash_ui_closed(slot: PlayerSlot) -> void:
	slot.stash_ui = null
	if slot.stash_canvas_layer and is_instance_valid(slot.stash_canvas_layer):
		slot.stash_canvas_layer.queue_free()
	slot.stash_canvas_layer = null


func _has_any_open_stash_ui() -> bool:
	for slot in player_slot_manager.slots:
		if slot.stash_ui and is_instance_valid(slot.stash_ui):
			return true

	return false


func _close_all_stash_ui() -> void:
	for slot in player_slot_manager.slots:
		_close_stash_ui_for_slot(slot)


func _get_slot_for_player(player: PlayerController) -> PlayerSlot:
	for slot in player_slot_manager.slots:
		if slot.player == player:
			return slot

	return null


func _build_crew_exit_summary(actor: Node) -> String:
	var crew_gold := 0
	var player_lines: Array[String] = []

	for slot in player_slot_manager.slots:
		var player := slot.player
		if not is_instance_valid(player):
			continue

		var inventory := player.inventory as PlayerInventory
		if not inventory:
			continue

		var player_gold := inventory.get_coin_count()
		crew_gold += player_gold
		player_lines.append("P%d: %d gold" % [slot.slot_index + 1, player_gold])

	if not player_lines.is_empty():
		return "Crew Loot: %d gold\n%s" % [crew_gold, "\n".join(player_lines)]

	if actor is PlayerController:
		return (actor as PlayerController).get_level_exit_summary()

	return "Extracted"


func _clear_current_world() -> void:
	_close_all_stash_ui()
	_detach_slot_players_from_current_world()
	if current_world:
		current_world.queue_free()
		current_world = null


func _detach_slot_players_from_current_world() -> void:
	if not current_world:
		return

	for slot in player_slot_manager.slots:
		var player := slot.player
		if not is_instance_valid(player):
			continue
		if player.get_parent() != current_world:
			continue

		current_world.remove_child(player)
		add_child(player)


func _restore_players_for_hub() -> void:
	for slot in player_slot_manager.slots:
		var player := slot.player
		if not is_instance_valid(player):
			continue

		_restore_player_for_session_presence(player)


func _ensure_local_coop_viewports() -> void:
	if current_session.session_type != GameSessionConfig.SessionType.LOCAL_COOP:
		return
	if split_screen_layer:
		return

	_create_local_coop_viewports()


func _create_local_coop_viewports() -> void:
	if player_slot_manager.get_local_player_count() != 2:
		push_error("Game: First local co-op viewport pass requires exactly 2 local players.")
		return

	if split_screen_layer:
		split_screen_layer.queue_free()

	split_screen_layer = CanvasLayer.new()
	split_screen_layer.name = "LocalCoopSplitScreen"
	split_screen_layer.layer = 0
	add_child(split_screen_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "SplitScreenBackdrop"
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_screen_layer.add_child(backdrop)

	split_screen_root = VBoxContainer.new()
	split_screen_root.name = "SplitScreenRoot"
	split_screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_screen_root.add_theme_constant_override("separation", 4)
	split_screen_layer.add_child(split_screen_root)

	var shared_world := get_viewport().world_3d
	for slot in player_slot_manager.slots:
		if not slot.is_local:
			continue
		_create_slot_viewport(slot, shared_world)

	print("Game: Created 2-player local co-op split-screen viewports.")


func _create_slot_viewport(slot: PlayerSlot, shared_world: World3D) -> void:
	var slot_root := Control.new()
	slot_root.name = "Player%dSplitScreenPane" % (slot.slot_index + 1)
	slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_screen_root.add_child(slot_root)

	var container := SubViewportContainer.new()
	container.name = "Player%dViewportContainer" % (slot.slot_index + 1)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_root.add_child(container)

	var viewport := SubViewport.new()
	viewport.name = "Player%dViewport" % (slot.slot_index + 1)
	viewport.world_3d = shared_world
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var camera := Camera3D.new()
	camera.name = "Player%dViewportCamera" % (slot.slot_index + 1)
	camera.current = true
	viewport.add_child(camera)

	slot.viewport = viewport
	slot.viewport_camera = camera
	_bind_slot_canvas_layers(slot)
	_create_slot_ui_host(slot, slot_root)


func _sync_split_screen_cameras() -> void:
	if not split_screen_layer:
		return

	for slot in player_slot_manager.slots:
		if not slot.is_local:
			continue
		if not slot.camera or not slot.viewport_camera:
			continue

		slot.viewport_camera.global_transform = slot.camera.global_transform
		slot.viewport_camera.fov = slot.camera.fov
		slot.viewport_camera.near = slot.camera.near
		slot.viewport_camera.far = slot.camera.far


func _bind_slot_canvas_layers(slot: PlayerSlot) -> void:
	if not slot.player:
		push_error("Game: Cannot bind UI without a slot player.")
		return
	if not slot.viewport:
		push_error("Game: Cannot bind UI without a slot viewport.")
		return

	for child in slot.player.get_children():
		if child is CanvasLayer:
			var canvas_layer := child as CanvasLayer
			if canvas_layer is PlayerHUD:
				canvas_layer.visible = false
			canvas_layer.custom_viewport = slot.viewport
			if canvas_layer.has_method("configure_for_split_screen"):
				canvas_layer.configure_for_split_screen()


func _create_slot_ui_host(slot: PlayerSlot, slot_root: Control) -> void:
	var ui_root := Control.new()
	ui_root.name = "Player%dUIHost" % (slot.slot_index + 1)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_root.add_child(ui_root)
	slot.split_screen_ui_root = ui_root

	_create_slot_hud(slot, ui_root)
	_create_slot_prompt(slot, ui_root)


func _create_slot_hud(slot: PlayerSlot, ui_root: Control) -> void:
	var label := Label.new()
	label.name = "Player%dHPLabel" % (slot.slot_index + 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.offset_left = 12.0
	label.offset_top = -34.0
	label.offset_right = 170.0
	label.offset_bottom = -8.0
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
	ui_root.add_child(label)
	slot.split_screen_hud_label = label

	var health := slot.player.health as HealthComponent
	_update_slot_hud(health.current_health, health.max_health, slot)
	health.health_changed.connect(_update_slot_hud.bind(slot))


func _create_slot_prompt(slot: PlayerSlot, ui_root: Control) -> void:
	var label := Label.new()
	label.name = "Player%dPromptLabel" % (slot.slot_index + 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 0.0
	label.offset_top = -70.0
	label.offset_right = 0.0
	label.offset_bottom = -42.0
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
	ui_root.add_child(label)
	slot.split_screen_prompt_label = label

	var scanner := slot.player.get_node("Components/InteractionScanner") as InteractionScanner
	scanner.focus_changed.connect(_update_slot_prompt.bind(slot))


func _update_slot_hud(current_health: int, max_health: int, slot: PlayerSlot) -> void:
	if not slot.split_screen_hud_label:
		return

	slot.split_screen_hud_label.text = "P%d HP %d/%d" % [slot.slot_index + 1, current_health, max_health]


func _update_slot_prompt(prompt: String, slot: PlayerSlot) -> void:
	if not slot.split_screen_prompt_label:
		return

	slot.split_screen_prompt_label.text = prompt
	slot.split_screen_prompt_label.visible = not prompt.is_empty()
