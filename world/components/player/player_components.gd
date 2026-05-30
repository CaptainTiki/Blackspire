extends Node
class_name PlayerComponents

## Central reference holder for all player components.
## Other components can access shared nodes through this.

@export var player: PlayerController
@export var camerarig: CameraRig
@export var inventory: Node

func _ready() -> void:
	if not player:
		push_error("PlayerComponents: No player assigned. This is a required reference.")
	if not camerarig:
		push_error("PlayerComponents: No camerarig assigned. This is a required reference.")
	if not inventory:
		push_error("PlayerComponents: No inventory assigned. This is a required reference.")
