class_name GameSessionConfig
extends Resource

## Describes the type of game session we want to start.
## This is the data that Main will pass to the Game node.

enum SessionType {
	SINGLE_PLAYER,
	LOCAL_COOP,          # 2-player local split-screen for now
	MULTIPLAYER_HOST,
	MULTIPLAYER_CLIENT
}

@export var session_type: SessionType = SessionType.SINGLE_PLAYER

## How many local players to create.
## For SINGLE_PLAYER this should be 1.
## For LOCAL_COOP we will start with 2.
@export var local_player_count: int = 1

## Maximum session participants allowed by the host.
@export_range(1, 4, 1) var max_player_count: int = 4

## Host address used by MULTIPLAYER_CLIENT sessions.
@export var host_address: String = "127.0.0.1"

## ENet port used by host and client sessions.
@export_range(1, 65535, 1) var host_port: int = 24545

## Optional: Which dungeon/level to load (used later when we have multiple).
@export var starting_level_scene: PackedScene
