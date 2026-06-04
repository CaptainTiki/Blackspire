# world/components/player/player_input.gd
#
# Per-player input handler.
#
# This component owns a specific input device (or keyboard+mouse) and provides
# a clean API for gameplay code. It is the foundation for local co-op and
# future networked play.
#
# Key design points:
# - We respect the action names defined in Project Settings (InputMap).
#   This means rebinds will continue to work without code changes.
# - device = -1  → Keyboard + Mouse player (special case)
# - device >= 0  → Specific joypad/controller
# - owns_mouse   → Only one player should normally have this true.
#
# In the future, when we add networking, remote players will NOT use a
# PlayerInput node at all — their commands will come from the network.
# Local input (this node) will only ever exist on the machine that owns
# the physical devices.

class_name PlayerInput
extends Node

signal mouse_motion_captured(relative: Vector2)

@export var player: PlayerController

## -1 means keyboard + mouse (the "KBM player").
## 0, 1, 2... means a specific joypad device index.
@export var device: int = -1

## Only the player who "owns" the mouse should process mouse motion.
## In split-screen this will matter a lot.
@export var owns_mouse: bool = true

## Single-player convenience: keyboard/mouse player can also accept joypad input.
## Local co-op disables this so controller devices can belong to other slots.
@export var accepts_unassigned_joypads: bool = true

## Input inversion settings.
## These are exposed so a future Settings menu can let each player customize
## their controls (very common request for both movement and look).
@export var invert_movement_x := false
@export var invert_movement_y := false
@export var invert_look_x := false
@export var invert_look_y := false

## Deadzone applied to raw joypad axes before they affect movement/look.
## Matches the default action deadzone in the InputMap. Increase if you have
## controller drift.
@export var joy_deadzone := 0.2

# --- Internal analog state (accumulated from events) ---
var _move_left: float = 0.0
var _move_right: float = 0.0
var _move_forward: float = 0.0
var _move_backward: float = 0.0

var _look_left: float = 0.0
var _look_right: float = 0.0
var _look_up: float = 0.0
var _look_down: float = 0.0

# --- Discrete action state (event-driven) ---
var _pressed: Dictionary[StringName, bool] = {}          # action_name -> currently held
var _just_pressed: Dictionary[StringName, bool] = {}     # action_name -> true for one frame

# Actions we care about for gameplay + UI.
# Keeping this list explicit makes the component self-documenting.
const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_forward", &"move_backward",
	&"sprint", &"jump", &"crouch",
	&"interact", &"primary_action", &"secondary_action",
	&"toggle_equipment",
	&"inventory_pick_place", &"inventory_cancel_drag",
	&"hotbar_slot_1", &"hotbar_slot_2", &"hotbar_slot_3", &"hotbar_slot_4",
]

# Look actions are handled as analog, not discrete.
const LOOK_ACTIONS: Array[StringName] = [
	&"look_left", &"look_right", &"look_up", &"look_down",
]


func _ready() -> void:
	if not player:
		push_error("PlayerInput requires a player reference.")

	# Initialize state dictionaries so we never get nulls.
	for action in GAMEPLAY_ACTIONS + LOOK_ACTIONS:
		_pressed[action] = false
		_just_pressed[action] = false


func _input(event: InputEvent) -> void:
	if not owns_input_event(event):
		return

	# Mouse motion is special — only the owner should ever see it.
	if owns_mouse and event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_motion_captured.emit(motion.relative)
		return

	# Analog axes (right stick look + left stick movement on joypad)
	if event is InputEventJoypadMotion:
		_handle_joypad_motion(event as InputEventJoypadMotion)
		return

	# Digital buttons and keys
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		_handle_digital_event(event)


func owns_input_event(event: InputEvent) -> bool:
	if device == -1:
		if event is InputEventKey or event is InputEventMouse:
			return true

		if accepts_unassigned_joypads:
			return event is InputEventJoypadButton or event is InputEventJoypadMotion

		return false
	else:
		# Strict joypad player — only events from our exact device.
		return (
			(event is InputEventJoypadButton or event is InputEventJoypadMotion) and
			event.device == device
		)


func _handle_joypad_motion(motion: InputEventJoypadMotion) -> void:
	# Map known axes to our internal state using the action names.
	# We still go through the action system so that custom rebinds in
	# Project Settings would (in theory) still be respected if someone
	# remapped an axis — though axis remapping is rare.

	var value := motion.axis_value

	# Apply deadzone — very important for Xbox controllers and centering.
	if absf(value) < joy_deadzone:
		value = 0.0

	match motion.axis:
		JOY_AXIS_LEFT_X:
			# Left stick horizontal
			if value < 0:
				_move_left = absf(value)
				_move_right = 0.0
			else:
				_move_right = value
				_move_left = 0.0

		JOY_AXIS_LEFT_Y:
			# Left stick vertical (negative = forward in our mapping)
			if value < 0:
				_move_forward = absf(value)
				_move_backward = 0.0
			else:
				_move_backward = value
				_move_forward = 0.0

		JOY_AXIS_RIGHT_X:
			if value < 0:
				_look_left = absf(value)
				_look_right = 0.0
			else:
				_look_right = value
				_look_left = 0.0

		JOY_AXIS_RIGHT_Y:
			if value < 0:
				_look_up = absf(value)
				_look_down = 0.0
			else:
				_look_down = value
				_look_up = 0.0

		JOY_AXIS_TRIGGER_RIGHT:
			# Right trigger (RT on Xbox) is bound to "primary_action" (attack)
			_update_action_from_analog(&"primary_action", value)

		JOY_AXIS_TRIGGER_LEFT:
			# Left trigger (LT) bound to secondary_action (block / offhand).
			_update_action_from_analog(&"secondary_action", value)


func _handle_digital_event(event: InputEvent) -> void:
	# Check every action we care about.
	# Using event.is_action(...) respects the InputMap definitions.
	for action in GAMEPLAY_ACTIONS + LOOK_ACTIONS:
		if event.is_action(action):
			var was_pressed: bool = _pressed.get(action, false)
			var is_now_pressed: bool = event.is_pressed()

			_pressed[action] = is_now_pressed

			if is_now_pressed and not was_pressed:
				_just_pressed[action] = true

			# Update analog state for both movement and look actions when using digital keys.
			# This is what allows WASD (and keyboard look bindings) to feed get_movement_vector() / get_look_vector().
			var strength := 1.0 if is_now_pressed else 0.0

			match action:
				&"move_left":     _move_left = strength
				&"move_right":    _move_right = strength
				&"move_forward":  _move_forward = strength
				&"move_backward": _move_backward = strength
				&"look_left":     _look_left = strength
				&"look_right":    _look_right = strength
				&"look_up":       _look_up = strength
				&"look_down":     _look_down = strength

			# We don't need to consume the event here — let other systems
			# decide if they want to mark it handled.


func _update_action_from_analog(action: StringName, analog_value: float) -> void:
	# Treat analog triggers as digital buttons for "just pressed" purposes.
	var is_pressed := analog_value > joy_deadzone

	var was_pressed: bool = _pressed.get(action, false)
	_pressed[action] = is_pressed

	if is_pressed and not was_pressed:
		_just_pressed[action] = true


func _physics_process(_delta: float) -> void:
	# Clear after this physics frame so state-chart signal handlers later in the tree
	# can still consume one-frame input.
	_clear_just_pressed.call_deferred()


func _clear_just_pressed() -> void:
	for action in _just_pressed.keys():
		_just_pressed[action] = false


# ---------------------------------------------------------------------------
# Public API — the rest of the player systems should use these methods.
# ---------------------------------------------------------------------------

func get_movement_vector() -> Vector2:
	# Returns a normalized-style vector in the -1..1 range.
	# X = right, Y = forward (Godot convention for top-down style, but we use it for 3D too).
	var x := _move_right - _move_left
	var y := _move_forward - _move_backward

	if invert_movement_x:
		x = -x
	if invert_movement_y:
		y = -y

	var vec := Vector2(x, y)

	# Final deadzone on the combined vector (catches any small leakage).
	if vec.length() < joy_deadzone:
		return Vector2.ZERO

	# Clamp length so diagonal isn't faster.
	if vec.length() > 1.0:
		vec = vec.normalized()

	return vec


func get_look_vector() -> Vector2:
	# Right stick look input.
	# X = right, Y = down (standard for look).
	var x := _look_right - _look_left
	var y := _look_down - _look_up

	if invert_look_x:
		x = -x
	if invert_look_y:
		y = -y

	var vec := Vector2(x, y)

	if vec.length() < joy_deadzone:
		return Vector2.ZERO

	return vec


func is_action_pressed(action: StringName) -> bool:
	return _pressed.get(action, false) as bool


func is_action_just_pressed(action: StringName) -> bool:
	return _just_pressed.get(action, false) as bool


## Convenience helpers for the most common actions.
## These make the calling code in PlayerController etc. very readable.

func is_jump_just_pressed() -> bool:
	return is_action_just_pressed(&"jump")

func is_sprint_pressed() -> bool:
	return is_action_pressed(&"sprint")

func is_crouch_pressed() -> bool:
	return is_action_pressed(&"crouch")

func is_interact_just_pressed() -> bool:
	return is_action_just_pressed(&"interact")

func is_primary_action_just_pressed() -> bool:
	return is_action_just_pressed(&"primary_action")

func is_secondary_action_pressed() -> bool:
	return is_action_pressed(&"secondary_action")

func is_secondary_action_just_pressed() -> bool:
	return is_action_just_pressed(&"secondary_action")

func is_toggle_equipment_just_pressed() -> bool:
	return is_action_just_pressed(&"toggle_equipment")

func is_inventory_pick_place_pressed() -> bool:
	return is_action_pressed(&"inventory_pick_place")

func is_inventory_cancel_drag_just_pressed() -> bool:
	return is_action_just_pressed(&"inventory_cancel_drag")


func get_hotbar_slot_just_pressed() -> int:
	# Returns 0-3 if one of the hotbar slots was just pressed, otherwise -1.
	for i in 4:
		if is_action_just_pressed("hotbar_slot_%d" % (i + 1)):
			return i
	return -1


## For the keyboard/mouse player, mouse motion is delivered via signal
## instead of polling. This keeps things event-driven and avoids
## reading global mouse state from multiple places.
func has_mouse_motion() -> bool:
	# Currently we deliver via signal. This can be expanded later if needed.
	return false
