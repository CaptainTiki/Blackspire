extends Node

## QuickEntry is a debug/testing helper.
## It bypasses the main menu entirely and directly starts a Game session.
##
## Use this for fast iteration and headless testing.
## Set the desired session type in the inspector before running.

@export var session_type: GameSessionConfig.SessionType = GameSessionConfig.SessionType.SINGLE_PLAYER
@export var local_player_count: int = 1
@export_range(1, 4, 1) var max_player_count: int = 4
@export var host_address: String = "127.0.0.1"
@export_range(1, 65535, 1) var host_port: int = 24545

@export var game_scene: PackedScene = preload("res://system/game/game.tscn")

func _ready() -> void:
	var config := GameSessionConfig.new()
	config.session_type = session_type
	config.local_player_count = local_player_count
	config.max_player_count = max_player_count
	config.host_address = host_address
	config.host_port = host_port

	print("QuickEntry: Bypassing menu and starting session directly -> ", 
		GameSessionConfig.SessionType.keys()[session_type])

	var game := game_scene.instantiate() as Game
	add_child(game)
	game.start_session(config)
