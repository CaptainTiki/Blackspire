# Handoff Notes

**Last Updated:** 2026-06-03

At the start of a new session, read this file first.

## Current Build

`v0.0.0052` - Movement Feel pass.

## Current Direction

The project has proven the session foundation:

- Single Player, Local Co-op, Host, and Client sessions all use the same `Game` flow.
- `PlayerSlot` is now a session participant record, not just a local input device.
- Host/client join, membership snapshots, visible remote players, and disconnect cleanup work.
- Player transform, rotation, jump movement, and primary-action presentation replicate.
- Hub -> run -> hub works in a two-instance host/client session.
- Enemy AI/damage/death can be host-owned, and client attacks can be forwarded to host authority.

We are intentionally **not** pushing deeper into temporary networking hooks right now. The immediate baseline is now the refactored player controller/state architecture, and the next milestone remains making the first five minutes fun while preserving the multiplayer-aware architecture.

Active plan:

- `docs/multiplayer_playthrough_slice_plan.md`

Known online bugs/authority gaps:

- `docs/network_known_issues.md`

## Durable Project Rules

### Authoring Pipeline

- All maps and placed objects are authored in **TrenchBroom**.
- Everything enters the game through **FuncGodotMap** nodes using our FGD definitions.
- There are currently no hybrid scenes or exceptions to this rule.
- When working with placeable objects, check the current FGD entities in `trenchbroom/` and how they map to Godot scenes.

### Architecture

- Short, focused scripts.
- Parents own references. Siblings own behavior.
- Prefer direct `@export` references and explicit scene knowledge over broad fallback logic.
- There is exactly one active dungeon `Level` at runtime. Level-global dungeon context is available through `Level.current_level`.
- Re-read `docs/project_blackspire_architecture.md` before significant systems work.

### Fail Loudly

- We want to know immediately when something is broken.
- Avoid fallback/safety-net code in prototype gameplay systems.
- Fallbacks are acceptable only for multiplayer timing/transition concerns.
- If a required node or component is missing, the game should fail loudly.

### Multiplayer Shape

- Host-authoritative remains the target.
- Clients own local input intent and presentation.
- State-machine transitions and semantic gameplay events should become future network hooks.
- Avoid binding future replication to temporary animation names, node paths, or one-off presentation scripts.

## Current Gameplay Pivot

Build the **Multiplayer Playthrough Slice**:

```text
spawn room -> cramped fight -> lock-in panic fight -> elite arena -> locked exit
```

Primary goals:

- build on the new player statechart/state-machine controller with visible mesh, animation states, and tunable feel
- replace the temporary enemy with three state-machine enemies:
  - melee slime
  - ranged spitter
  - elite slime with melee and ranged pressure
- author five silver-standard rooms with more shape than box-with-doors
- add first-pass VFX for hits, death, projectile impact, and attack readability
- add rough SFX so timing and feedback can be judged
- keep single-player, local co-op, and multiplayer sessions in mind while refactoring

This is not a public demo. It is the "is this fun?" pass.

## Current Network Baseline

Things already proven:

- host/client connect on local network
- both peers see remote players
- player movement and action presentation replicate
- client-requested deploy can load both peers into the run
- enemies can move/death-sync from host authority
- client attacks can kill host-owned enemies
- successful extraction returns both peers to hub
- hub summary board can show shared run result text

Known gaps to revisit after the gameplay rebuild:

- player health/life state replication
- downed/revive replication
- enemy damage feedback on clients
- host-owned pickups and inventory snapshots
- host-owned hotbar/potion use
- host-owned shared stash
- door/lever world-state replication
- robust extraction/failure authority

## Current Player Controller Baseline

`Player.tscn` now uses a StateChart plus mirrored StateMachine script tree:

- `Movement`: grounded/idle/moving/running/sprinting/airborne/jumping
- `Posture`: standing/crouching
- `Life`: deploying/alive/downed/dead
- `Action`: ready/primary attack/interact/revive/extract

The chart owns active states and transitions. Mirrored state scripts own entry
points and per-state processing, and call `PlayerController` verbs such as
`run()`, `sprint()`, `jump()`, `request_jump_launch()`, `crouch()`, and
`stand()`.

`PlayerController` remains the shared `CharacterBody3D` motor and gameplay verb
surface. It no longer owns raw look/capture math. `Components/PlayerLook` owns
mouse capture, mouse look, and controller look. `Components/PlayerInput` remains
the per-player input source.

Posture now has one story: `StandingCollision`, `CrouchCollision`, and
`CrouchCheck`. There is no remaining capsule-height resizing path in the
controller. Crouch uses deliberate camera interpolation and a movement
multiplier instead of a fixed crouch speed, so crouch-sprint is possible while
remaining slower than upright movement.

The current movement-feel pass preserves analog controller stick magnitude,
adds sprint wind-up, sprint turn weight, air acceleration weight, and attack
movement drag. `JumpingState` now owns jump launch consumption instead of being
a placeholder, while fall-off-ledge transitions enter Airborne without applying
a jump impulse.

Interaction input now routes through the player `Action` branch; the scanner owns
focus/target classification and execution verbs, but no longer polls input.
Melee attacks cancel on Downed/Dead, the player has an active state debug label,
and `PlayerLifeState` exposes a first snapshot shape for future replicated
health/life state.

## Key Files And Systems

- `system/main.tscn` - app root and menu bootstrap
- `system/game/game.tscn` / `system/game/game.gd` - session owner, world transitions, slot manager, crew stash
- `system/player_slot.gd` / `system/player_slot_manager.gd` - session participant slots and player spawning/moving
- `system/network/network_session.gd` - ENet host/client wrapper
- `world/actors/player/Player.tscn` - current player actor and statechart/state-machine controller
- `world/actors/player/README.md` - current player controller/state architecture notes
- `world/actors/enemies/basic_enemy.tscn` - current temporary enemy actor
- `world/level.gd` - run state, generated level, enemies, extraction/failure
- `world/hub/hub.tscn` - current temporary crew hub
- `.tests/` - ignored local smoke/diagnostic scripts

## Start-Of-Session Reading

1. `docs/handoff_notes.md`
2. `docs/multiplayer_playthrough_slice_plan.md`
3. `docs/project_blackspire_architecture.md`
4. `docs/project_blackspire_prototype_gdd.md`
5. `docs/network_known_issues.md` only when touching online sync

## Verification Habits

- Use `rg` for fast code search.
- Use `apply_patch` for manual file edits.
- Run Godot headless checks after code changes when feasible.
- `git diff --check` before handoff.
- Known headless noise: Windows root certificate warning and occasional shutdown leak/resource messages from diagnostic scripts.
