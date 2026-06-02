class_name PlayerSlotManager
extends Node

## Manages all PlayerSlots for the current game session.
## Lives under the Game node.

const LOCAL_COOP_SPAWN_SPACING := 1.25
const OFFLINE_PEER_ID := 1

var slots: Array[PlayerSlot] = []

## Creates the requested number of local player slots.
## This is the main entry point when starting a new session.
func create_local_slots(count: int) -> Array[PlayerSlot]:
	return create_local_session_slots(count)


## Creates locally controlled session participants for single-player/local co-op.
func create_local_session_slots(count: int, peer_id: int = OFFLINE_PEER_ID) -> Array[PlayerSlot]:
	slots.clear()

	for i in count:
		var slot := _create_slot(i, peer_id, i, true)
		slots.append(slot)

	print("PlayerSlotManager: Created %d local session slot(s)" % count)
	return slots


func _create_slot(slot_index: int, peer_id: int, local_player_index: int, is_local: bool) -> PlayerSlot:
	var slot := PlayerSlot.new()
	slot.slot_index = slot_index
	slot.session_player_id = slot_index
	slot.peer_id = peer_id
	slot.local_player_index = local_player_index
	slot.is_local = is_local
	slot.input_device = _get_local_input_device(local_player_index) if is_local else -1
	return slot


func get_slot(index: int) -> PlayerSlot:
	if index < 0 or index >= slots.size():
		push_error("PlayerSlotManager: Invalid slot index %d" % index)
		return null
	return slots[index]

func get_local_player_count() -> int:
	var count := 0
	for slot in slots:
		if slot.is_local:
			count += 1
	return count


func get_slot_count() -> int:
	return slots.size()


func get_slot_for_peer(peer_id: int, local_player_index: int = 0) -> PlayerSlot:
	for slot in slots:
		if slot.peer_id == peer_id and slot.local_player_index == local_player_index:
			return slot

	return null


func spawn_local_players(level: Level, player_scene: PackedScene) -> Array[PlayerController]:
	return spawn_slot_players(level, player_scene)


func spawn_slot_players(level: Level, player_scene: PackedScene) -> Array[PlayerController]:
	if not level:
		push_error("PlayerSlotManager.spawn_slot_players requires a Level.")
		return []
	return spawn_or_move_slot_players(level, level.get_player_spawns(), player_scene, level)


func spawn_or_move_local_players(world_root: Node3D, spawns: Array[Marker3D], player_scene: PackedScene, level: Level = null) -> Array[PlayerController]:
	return spawn_or_move_slot_players(world_root, spawns, player_scene, level)


func spawn_or_move_slot_players(world_root: Node3D, spawns: Array[Marker3D], player_scene: PackedScene, level: Level = null) -> Array[PlayerController]:
	if not world_root:
		push_error("PlayerSlotManager.spawn_or_move_slot_players requires a world_root.")
		return []
	if not player_scene:
		push_error("PlayerSlotManager.spawn_or_move_slot_players requires a player_scene.")
		return []
	if slots.is_empty():
		push_error("PlayerSlotManager.spawn_or_move_slot_players requires slots first.")
		return []
	if spawns.is_empty():
		push_error("No player spawn points found in '%s'." % world_root.name)
		return []

	var players: Array[PlayerController] = []
	var allow_single_player_controller := get_local_player_count() == 1

	for slot in slots:
		var player := spawn_or_move_slot_player(slot, world_root, spawns, player_scene, level, allow_single_player_controller)
		if not player:
			return players
		players.append(player)

	return players


func spawn_or_move_slot_player(
	slot: PlayerSlot,
	world_root: Node3D,
	spawns: Array[Marker3D],
	player_scene: PackedScene,
	level: Level = null,
	allow_single_player_controller: bool = false
) -> PlayerController:
	if not slot:
		push_error("PlayerSlotManager.spawn_or_move_slot_player requires a slot.")
		return null
	if not world_root:
		push_error("PlayerSlotManager.spawn_or_move_slot_player requires a world_root.")
		return null
	if not player_scene:
		push_error("PlayerSlotManager.spawn_or_move_slot_player requires a player_scene.")
		return null
	if spawns.is_empty():
		push_error("No player spawn points found in '%s'." % world_root.name)
		return null

	var player := slot.player
	if not is_instance_valid(player):
		player = player_scene.instantiate() as PlayerController
		if not player:
			push_error("PlayerSlotManager: player_scene must instantiate a PlayerController.")
			return null
		player.name = "Player%d" % (slot.slot_index + 1)
		world_root.add_child(player)
	elif player.get_parent() != world_root:
		var previous_parent := player.get_parent()
		if previous_parent:
			previous_parent.remove_child(player)
		world_root.add_child(player)

	player.global_transform = _get_spawn_transform(spawns, slot.slot_index)
	if level:
		level.register_player(player)

	_assign_slot_player(slot, player, allow_single_player_controller)
	print("PlayerSlotManager: Placed slot %d player at %s" % [slot.slot_index, player.global_position])
	return player


func _assign_slot_player(slot: PlayerSlot, player: PlayerController, allow_single_player_controller: bool) -> void:
	slot.player = player
	slot.input = player.input_reader
	slot.camera = player.camera

	slot.input.device = slot.input_device
	slot.input.owns_mouse = slot.is_local and slot.local_player_index == 0
	slot.input.accepts_unassigned_joypads = slot.is_local and allow_single_player_controller
	slot.input.set_process_input(slot.is_local)
	slot.camera.current = slot.is_local and slot.local_player_index == 0


func _get_local_input_device(slot_index: int) -> int:
	if slot_index == 0:
		return -1

	return slot_index - 1


func _get_spawn_transform(spawns: Array[Marker3D], slot_index: int) -> Transform3D:
	var spawn_point := spawns[min(slot_index, spawns.size() - 1)]
	var spawn_transform := spawn_point.global_transform

	if slot_index >= spawns.size():
		var side_offset := ((slot_index + 1) / 2) * LOCAL_COOP_SPAWN_SPACING
		if slot_index % 2 == 0:
			side_offset *= -1.0

		spawn_transform.origin += spawn_transform.basis.x.normalized() * side_offset

	return spawn_transform

## Placeholder shape for future remote player support.
func add_remote_slot(peer_id: int) -> PlayerSlot:
	var existing_slot := get_slot_for_peer(peer_id)
	if existing_slot:
		push_error("PlayerSlotManager: Remote slot already exists for peer %d." % peer_id)
		return existing_slot

	var slot := _create_slot(slots.size(), peer_id, 0, false)
	slots.append(slot)
	print("PlayerSlotManager: Added remote session slot %d for peer %d" % [slot.slot_index, peer_id])
	return slot


func remove_remote_slot(peer_id: int) -> bool:
	for i in slots.size():
		var slot := slots[i]
		if slot.is_local or slot.peer_id != peer_id:
			continue

		if is_instance_valid(slot.player):
			slot.player.queue_free()
		slots.remove_at(i)
		print("PlayerSlotManager: Removed remote session slot for peer %d" % peer_id)
		return true

	push_error("PlayerSlotManager: No remote slot found for peer %d." % peer_id)
	return false
