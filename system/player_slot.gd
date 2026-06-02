class_name PlayerSlot
extends Resource

## Represents one participant in the current game session.
## Local input, camera, viewport, and UI references are present only on the
## machine that owns this participant locally.

var slot_index: int = -1

## Durable identity for this participant within a session.
var session_player_id: int = -1

## Human-readable placeholder until character/session names exist.
var display_name: String = ""

## Network peer that owns this participant. The offline/local placeholder is 1,
## matching Godot's usual server peer id once online play is introduced.
var peer_id: int = 1

## Which local player this participant is on its owning peer.
## This keeps couch co-op compatible with future online sessions.
var local_player_index: int = 0

## True only when this machine owns local presentation/input for this slot.
var is_local: bool = true

## Local input device assignment. -1 means keyboard/mouse, 0+ means joypad.
var input_device: int = -1

## The actual player actor once spawned.
var player: PlayerController = null

## The PlayerInput component assigned to this slot.
## This is how we know which physical device (or keyboard) belongs to this player.
var input: PlayerInput = null

## The player's camera. This becomes the viewport camera once split-screen lands.
var camera: Camera3D = null

## Split-screen viewport plumbing for local players.
var viewport: SubViewport = null
var viewport_camera: Camera3D = null
var split_screen_ui_root: Control = null
var split_screen_hud_label: Label = null
var split_screen_prompt_label: Label = null
var stash_ui: Control = null
var stash_canvas_layer: CanvasLayer = null
