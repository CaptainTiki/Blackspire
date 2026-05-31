class_name PlayerSlot
extends Resource

## Represents one participant in the current game session.
## For local players this will eventually own:
## - A PlayerInput (device ownership)
## - A PlayerController
## - A Camera3D
## - Viewport / HUD references (when we do split-screen)
##
## For future multiplayer, remote players will also be represented by PlayerSlots
## but without local input/camera/viewport ownership.

var slot_index: int = -1
var is_local: bool = true

## The actual player actor (PlayerController) once spawned.
var player: Node = null

## The PlayerInput component assigned to this slot.
## This is how we know which physical device (or keyboard) belongs to this player.
var input: Node = null   # Will be PlayerInput once we wire it

## Future: camera, viewport, hud references will live here too.
