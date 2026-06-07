extends Node3D

## Quick-entry into the experimental compositor proto room.
##
## Bypasses menus / Game / hub / level: builds trenchbroom/maps/proto_room_01.map
## at RUNTIME via FuncGodot, then drops one real local Player in through the same
## PlayerSlotManager path the Game uses -- so input, camera, and mouse are wired
## exactly like a real session. Re-run after regenerating the .map to see changes.
##
## Run directly:  open system/proto_viewer.tscn and press F6 (Run Current Scene).

const MAP_PATH := "res://trenchbroom/maps/proto_room_01.map"
const PlayerScene: PackedScene = preload("res://world/actors/player/Player.tscn")

@onready var map: Node3D = $Map

func _ready() -> void:
	_add_lighting()

	# Build the .map at runtime from an absolute path (no editor bake needed).
	map.global_map_file = ProjectSettings.globalize_path(MAP_PATH)
	map.build()

	# Spawn marker near the room centre, a little above the floor.
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	add_child(spawn)
	spawn.global_position = Vector3(0.0, 2.0, 0.0)

	# Spawn one local player the same way Game does -- the slot manager assigns the
	# keyboard/mouse device, makes the player's camera current, and owns the mouse.
	var slot_manager := PlayerSlotManager.new()
	slot_manager.name = "PlayerSlotManager"
	add_child(slot_manager)
	slot_manager.create_local_session_slots(1)

	var spawns: Array[Marker3D] = [spawn]
	var players := slot_manager.spawn_or_move_slot_players(self, spawns, PlayerScene, null, [])
	if players.is_empty():
		push_error("ProtoViewer: failed to spawn a player into the proto room.")
		return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("ProtoViewer: proto room built and player spawned.")

func _add_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, -35, 0)
	add_child(sun)

	var we := WorldEnvironment.new()
	we.name = "Environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 1.0
	we.environment = env
	add_child(we)
