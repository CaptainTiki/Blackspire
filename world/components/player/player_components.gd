extends Node
class_name PlayerComponents

## Central reference holder for all player components.
## Other components can access shared nodes through this.

@export var player: PlayerController
@export var camerarig: CameraRig

# Add more shared references here as needed (e.g. inventory, state machine, etc.)
# @export var inventory: InventoryComponent

func _ready() -> void:
	if not player:
		push_error("PlayerComponents: No player assigned. This is a required reference.")
	if not camerarig:
		push_error("PlayerComponents: No camerarig assigned. This is a required reference.")
