# Handoff Notes

**Last Updated:** 2026-06-07

At the start of a new session, read this file first.

## Current Build

`v0.0.0053` - Room compositor and standard door vocabulary foundation.

## Room Compositor — Active Work

This is the current focus. We are building a vocabulary of reusable room panels and shapes that generate TrenchBroom `.map` files via PowerShell scripts. The goal is to produce the five silver-standard combat rooms required by the Multiplayer Playthrough Slice without hand-authoring every brush.

### Key Files

| File | Purpose |
|---|---|
| `tools/mapgen/lib/Compositor.ps1` | Turtle-walk room compositor. Owns all panel functions and `Build-Room`. |
| `tools/mapgen/lib/Mapkit.ps1` | Low-level Valve-220 brush primitives (`Box`, `QuadPrism`, `TriPrism`, `Connector`, etc.). Do not edit — these are stable. |
| `tools/mapgen/Build-Proto.ps1` | The active proto script. Defines panel presets and room specs; outputs `trenchbroom/maps/proto_room_01.map`. |
| `system/proto_viewer.tscn` | Press F6 in Godot to build the .map at runtime and walk it immediately. No editor bake needed. |
| `trenchbroom/maps/proto_room_01.map` | Generated output — never edit by hand. |

### Panel System Concepts

- A **room** is a turtle walk: an ordered list of `@{ op="bay"; kind="X" }` and `@{ op="corner"; turn=N }` steps.
- The turtle walks counter-clockwise, interior on its left. `inward = LeftOf(heading)`.
- Each panel receives `($origin, $along, $inward, $cfg)` so it works at any heading, including 45° chamfer walls.
- `Panel-<Kind>` returns `@{ b = <brushes>; e = <entities> }`. Adding a kind = adding one function.
- Corner pilasters are only placed for 90° turns. 45° turns (for chamfer walls) skip the pilaster.
- `d=0` is the room-side face of a wall. `d < 0` protrudes INTO the room. `d > 0` goes into the wall material.

### Panel-Size Presets (in Build-Proto.ps1)

```powershell
$Large    = @{ bay=256; thick=16; height=192; doorW=64;  doorH=64;  pilaster=20 }
$Standard = @{ bay=128; thick=8;  height=128; doorW=48;  doorH=64;  pilaster=12 }
```

### Room Specs (in Build-Proto.ps1)

- `Room-LargeOctagon $Large` — 3-bay wide × 4-bay long with 45° chamfered corners. One door on south wall.
- `Room-StandardSquare $Standard` — 3×3 square with corner pilasters. One framed door on south wall.
- To switch the active room: change the `$ActiveRoom = ...` line at the bottom of the script.

### Panel Types Implemented

| Kind | Function | Brushes | Notes |
|---|---|---|---|
| `wall` | `Panel-Wall` | 1 | Blank solid bay, full height. |
| `door` | `Panel-Door` | 3 | Plain door: jambs + lintel + room_connector entity. |
| `doorframed` | `Panel-DoorFramed` | 9 | Ornate door — see below. |

### Panel-DoorFramed — Current Geometry (Standard panel, bay=128)

All constants are hardcoded at the top of the function and are easy to tweak:

```
$pw=8   pilaster width (u)
$fp=4   pilaster & rake protrusion (depth into room)
$ffp=8  capitol & mantle protrusion (fp+4)
$ch=8   capitol height above door top
$ph=16  pilaster height above door top
$cext=4 capitol widens beyond pilaster outer edge each side
$mh=4   mantle cap height
$mext=4 mantle widens beyond capitol each side
$mfp=4  mantle extra protrusion (mantle total = ffp+mfp = 12)
$pedH=16 pediment rise from pilaster top to apex
```

Z stack (with doorH=64, bay height=128):
```
z=96  outer apex
z=92  inner apex (rakes meet, 4-unit solid tip above)
  12  open triangle — negative space, wall visible behind rakes
z=80  rake base = pilaster top
  4   pilasters above mantle (visible above entablature)
z=76  mantle top     (u=24→104, depth=12)
  4   mantle cap
z=72  capitol top    (u=28→100, depth=8)
  8   capitol block
z=64  door top
  64  door void
z=0   floor
```

Rake geometry: each rake is a `QuadPrism` parallelogram. Outer and inner edges are parallel to the slope (same direction vector), so rake width is consistent along the full length. The outer base u = pilaster outer edge; inner base u = pilaster inner edge. Both outer apex corners share the same point (u=64, z=96). Both inner edges converge at u=64, z=92 — the `innerApexZ` is derived from `pilTop + pedH * (1 - pw/slopeU)`.

### What To Work On Next

The vocabulary is missing panel types that give walls character. Priority order:

1. **`Panel-Niche`** — A shallow recessed alcove in a wall bay (no opening). Purely decorative. Gives long plain walls relief without a door. Simplest possible addition.
2. **`Panel-Alcove`** — A deeper recess, doorway height, like a dead-end stub. Could later become a loot niche.
3. **`Panel-WallPilaster`** — A protruding column mid-bay (not a corner). Breaks up long walls.
4. **More room shapes** — Corridor (1-bay wide × N long), L-bend, T-junction. These fall out of the turtle walk naturally; just need perimeter specs.
5. **Move frame constants to `$cfg`** — When door styles need to vary per room, promote the `Panel-DoorFramed` constants into the room config hashtable.

### How to Run

```powershell
# From repo root — regenerates proto_room_01.map
powershell -File tools/mapgen/Build-Proto.ps1

# Then in Godot: open system/proto_viewer.tscn, press F6
```

---

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
