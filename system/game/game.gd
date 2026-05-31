class_name Game
extends Node

## The central "session" container.
## Main creates one of these and tells it what kind of game to run.
##
## Game is responsible for:
## - Loading the appropriate starting scene (Hub or directly into a level)
## - Owning the PlayerSlotManager
## - Managing transitions between Hub <-> Dungeon runs
## - Owning the current world content

@onready var player_slot_manager: PlayerSlotManager = $PlayerSlotManager

## Temporary stand-in until we have a real Hub scene.
@export var test_level_scene: PackedScene = preload("res://world/levels/test_level.tscn")
@export var player_scene: PackedScene = preload("res://world/actors/player/Player.tscn")

var current_session: GameSessionConfig
var current_world: Node = null   # Will hold Hub or Level later


func start_session(config: GameSessionConfig) -> void:
	current_session = config
	print("Game: Starting session of type ", GameSessionConfig.SessionType.keys()[config.session_type])

	# Create player slots (even if we don't fully use them yet)
	player_slot_manager.create_local_slots(config.local_player_count)

	_load_starting_world()

func _load_starting_world() -> void:
	if not test_level_scene:
		push_error("Game: No test_level_scene assigned!")
		return

	var level := test_level_scene.instantiate() as Level
	if not level:
		push_error("Game: test_level_scene must instantiate a Level.")
		return

	current_world = level
	add_child(current_world)

	print("Game: Loaded test level as temporary world for session type: ", 
		GameSessionConfig.SessionType.keys()[current_session.session_type])

	# Temporary: Let the Level handle initial player spawning the old way
	# until we fully move spawning responsibility into PlayerSlotManager.
	level.level_ready.connect(_on_level_ready, CONNECT_ONE_SHOT)


func _on_level_ready() -> void:
	if not player_scene:
		push_error("Game: No player_scene assigned!")
		return

	var level := current_world as Level
	var player := level.spawn_player(player_scene) as PlayerController
	if not player:
		push_error("Game: Level did not spawn a player.")
		return

	var slot := player_slot_manager.get_slot(0)
	slot.player = player
	slot.input = player.input_reader

	print("Game: Single-player slot 0 assigned to spawned player.")
