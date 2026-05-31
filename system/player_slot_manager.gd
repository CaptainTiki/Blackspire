class_name PlayerSlotManager
extends Node

## Manages all PlayerSlots for the current game session.
## Lives under the Game node.

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

## Placeholder for future remote player support
func add_remote_slot(_peer_id: int) -> PlayerSlot:
	push_warning("Remote player slots not implemented yet.")
	return null
