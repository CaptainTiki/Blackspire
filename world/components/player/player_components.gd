extends Node
class_name PlayerComponents

## Central reference holder for all player components.
## Other components can access shared nodes through this.

@export var player: CharacterBody3D
@export var camerarig: CameraRig

# Add more shared references here as needed (e.g. inventory, state machine, etc.)
# @export var inventory: InventoryComponent

func _ready() -> void:
	if not player:
		push_warning("PlayerComponents: No player assigned.")
	if not camerarig:
		push_warning("PlayerComponents: No camerarig assigned.")
