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
- `Components/InteractionScanner` owns per-player interaction focus and interact calls.
- `Components/PlayerLifeState` bridges health/death/revive events into the Life chart.

## Controller Contract

State scripts should request intent through `PlayerController` methods instead of
editing body details directly:

- `run()` / `sprint()` set the active movement speed.
- `jump()` applies jump velocity.
- `crouch()` / `stand()` swap `StandingCollision` and `CrouchCollision`.
- `can_stand()` checks `CrouchCheck` before returning to standing.
- `capture_mouse()` / `release_mouse()` route through `PlayerLook`.
- `set_controller_look_enabled()` enables/disables `PlayerLook`.

`PlayerController._physics_process()` remains the shared motor: it reads cached
movement input, applies gravity, moves toward the current speed, delegates look
processing to `PlayerLook`, and calls `move_and_slide()`.

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

`Deploying` currently auto-completes to `Alive`. It exists as the future hook for
spawn setup, networking handshakes, and ready checks.

## Current Runtime Coverage

Manual runtime testing has verified:

- WASD movement
- sprint
- crouch / stand collider swapping
- jump
- primary attack
- interact pickup
- urn breaking
- extraction back to hub

## Near-Term Follow-Ups

- Replace placeholder `JumpingState` with useful airborne/jump behavior.
- Add debug display for active Movement/Posture/Life states.
- Expand `Life` replication hooks when player health/downed/dead sync becomes the active networking slice.
