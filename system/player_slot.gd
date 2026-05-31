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

## The actual player actor once spawned.
var player: PlayerController = null

## The PlayerInput component assigned to this slot.
## This is how we know which physical device (or keyboard) belongs to this player.
var input: PlayerInput = null

## The player's camera. This becomes the viewport camera once split-screen lands.
var camera: Camera3D = null

## Future: camera, viewport, hud references will live here too.
