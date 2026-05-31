extends Node

## QuickEntry is a debug/testing helper.
## It bypasses the main menu entirely and directly starts a Game session.
##
## Use this for fast iteration and headless testing.
## Set the desired session type in the inspector before running.

@export var session_type: GameSessionConfig.SessionType = GameSessionConfig.SessionType.SINGLE_PLAYER
@export var local_player_count: int = 1

@export var game_scene: PackedScene = preload("res://system/game/game.tscn")

func _ready() -> void:
	var config := GameSessionConfig.new()
	config.session_type = session_type
	config.local_player_count = local_player_count

	print("QuickEntry: Bypassing menu and starting session directly -> ", 
		GameSessionConfig.SessionType.keys()[session_type])

	var game := game_scene.instantiate() as Game
	add_child(game)
	game.start_session(config)
