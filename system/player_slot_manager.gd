class_name PlayerSlotManager
extends Node

## Manages all PlayerSlots for the current game session.
## Lives under the Game node.

const LOCAL_COOP_SPAWN_SPACING := 1.25

var slots: Array[PlayerSlot] = []

## Creates the requested number of local player slots.
## This is the main entry point when starting a new session.
func create_local_slots(count: int) -> Array[PlayerSlot]:
	slots.clear()

	for i in count:
		var slot := PlayerSlot.new()
		slot.slot_index = i
		slot.is_local = true
		slots.append(slot)

	print("PlayerSlotManager: Created %d local player slot(s)" % count)
	return slots

func get_slot(index: int) -> PlayerSlot:
	if index < 0 or index >= slots.size():
		push_error("PlayerSlotManager: Invalid slot index %d" % index)
		return null
	return slots[index]

func get_local_player_count() -> int:
	return slots.size()


func spawn_local_players(level: Level, player_scene: PackedScene) -> Array[PlayerController]:
	if not level:
		push_error("PlayerSlotManager.spawn_local_players requires a Level.")
		return []
	return spawn_or_move_local_players(level, level.get_player_spawns(), player_scene, level)


func spawn_or_move_local_players(world_root: Node3D, spawns: Array[Marker3D], player_scene: PackedScene, level: Level = null) -> Array[PlayerController]:
	if not world_root:
		push_error("PlayerSlotManager.spawn_or_move_local_players requires a world_root.")
		return []
	if not player_scene:
		push_error("PlayerSlotManager.spawn_or_move_local_players requires a player_scene.")
		return []
	if slots.is_empty():
		push_error("PlayerSlotManager.spawn_or_move_local_players requires local slots first.")
		return []
	if spawns.is_empty():
		push_error("No player spawn points found in '%s'." % world_root.name)
		return []

	var players: Array[PlayerController] = []
	var allow_single_player_controller := slots.size() == 1

	for slot in slots:
		var player := slot.player
		if not is_instance_valid(player):
			player = player_scene.instantiate() as PlayerController
			if not player:
				push_error("PlayerSlotManager: player_scene must instantiate a PlayerController.")
				return players
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
		players.append(player)

		print("PlayerSlotManager: Placed slot %d player at %s" % [slot.slot_index, player.global_position])

	return players


func _assign_slot_player(slot: PlayerSlot, player: PlayerController, allow_single_player_controller: bool) -> void:
	slot.player = player
	slot.input = player.input_reader
	slot.camera = player.camera

	slot.input.device = _get_local_input_device(slot.slot_index)
	slot.input.owns_mouse = slot.slot_index == 0
	slot.input.accepts_unassigned_joypads = allow_single_player_controller
	slot.camera.current = slot.slot_index == 0


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

## Placeholder for future remote player support
func add_remote_slot(_peer_id: int) -> PlayerSlot:
	push_warning("Remote player slots not implemented yet.")
	return null
