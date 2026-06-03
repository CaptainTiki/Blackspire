# Player Controller

`Player.tscn` is the current first-person player actor for Blackspire.

The controller is now authored around a Godot State Charts tree plus mirrored
state-machine script nodes. The chart owns active states and legal transitions.
The mirrored scripts own state entry points, per-state physics checks, and calls
into `PlayerController` verbs.

## Scene Shape

- `PlayerController` is the `CharacterBody3D` root and owns shared motor state.
- `StateChart` owns parallel branches for `Movement`, `Posture`, `Life`, and `Action`.
- `StateMachine` mirrors the chart with script nodes such as `RunningState`,
  `CrouchingState`, and `DownedState`.
- `Components/PlayerInput` owns per-player input device state.
- `Components/PlayerLook` owns mouse capture, mouse look, and controller look.
- `Components/InteractionScanner` owns per-player interaction focus, target routing, and interaction execution.
- `Components/PlayerLifeState` bridges health/death/revive events into the Life chart.
- `PlayerStateDebugLabel` shows the active Movement, Posture, Life, and Action leaf states.

## Controller Contract

State scripts should request intent through `PlayerController` methods instead of
editing body details directly:

- `run()` / `sprint()` set movement intent and target speed.
- `request_jump_launch()` queues an intentional grounded jump transition.
- `jump()` applies jump velocity when `JumpingState` consumes that launch request.
- `crouch()` / `stand()` swap `StandingCollision` and `CrouchCollision`.
- `can_stand()` checks `CrouchCheck` before returning to standing.
- `capture_mouse()` / `release_mouse()` route through `PlayerLook`.
- `set_controller_look_enabled()` enables/disables `PlayerLook`.
- `get_life_snapshot(session_player_id)` returns the current player health/life snapshot shape.
- `cancel_primary_attack()` stops active melee attacks when Life enters Downed or Dead.

`PlayerController._physics_process()` remains the shared motor: it reads cached
movement input, preserves analog stick magnitude, applies gravity, ramps toward
the current target speed, delegates look processing to `PlayerLook`, and calls
`move_and_slide()`.

## Movement Feel

Current tunables:

- `walk_speed`
- `sprint_speed_multiplier`
- `crouch_speed_multiplier`
- `acceleration` / `deceleration`
- `sprint_windup_rate`
- `speed_drop_rate`
- `sprint_turn_acceleration_multiplier`
- `air_acceleration_multiplier`
- `attack_movement_multiplier`
- `stance_camera_lerp_speed`

Controller stick throw now affects movement magnitude instead of normalizing all
movement to full speed. Sprint ramps in, sprint direction changes carry extra
weight, airborne control uses reduced acceleration, attacks slow movement
slightly, and crouch lowers the camera deliberately instead of snapping.

## Current State Branches

Movement:

- `Grounded`
- `Idle`
- `Moving`
- `Running`
- `Sprinting`
- `Airborne`
- `Jumping`

Posture:

- `Standing`
- `Crouching`

Life:

- `Deploying`
- `Alive`
- `Downed`
- `Dead`

Action:

- `Ready`
- `PrimaryAttack`
- `Interact`
- `Revive`
- `Extract`

`Deploying` currently auto-completes to `Alive`. It exists as the future hook for
spawn setup, networking handshakes, and ready checks.

## Current Runtime Coverage

Manual runtime testing after the StateMachine refactor verified:

- WASD movement
- sprint
- crouch / stand collider swapping
- jump
- primary attack
- interact pickup
- urn breaking
- extraction back to hub

## Near-Term Follow-Ups

- Live-play tune movement feel values with controller in hand.
- Add first visible player mesh and animation-state presentation.
- Start the Slime enemy state machine.
- Expand `Life` replication hooks when player health/downed/dead sync becomes the active networking slice.
