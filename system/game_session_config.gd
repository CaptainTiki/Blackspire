class_name GameSessionConfig
extends Resource

## Describes the type of game session we want to start.
## This is the data that Main will pass to the Game node.

enum SessionType {
	SINGLE_PLAYER,
	LOCAL_COOP,          # 2-player local split-screen for now
	# MULTIPLAYER_HOST,  # future
	# MULTIPLAYER_CLIENT # future
}

@export var session_type: SessionType = SessionType.SINGLE_PLAYER

## How many local players to create.
## For SINGLE_PLAYER this should be 1.
## For LOCAL_COOP we will start with 2.
@export var local_player_count: int = 1

## Optional: Which dungeon/level to load (used later when we have multiple).
@export var starting_level_scene: PackedScene
