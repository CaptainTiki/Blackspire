# Handoff Notes

**Date:** [Current session]

## Current North Star / Vision
Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape. It recreates the feeling of early MMO raiding before every answer was known: your team enters an unfamiliar dungeon, figures out its routes and puzzles under pressure, gathers as much loot as you dare, and must survive the return trip to keep it.

## Recent Decisions (Locked or Strongly Leaning)

### Sizing & Modules
- Base module: **64 units** (2.0m)
- Subdivision: **16-unit increments**
- Standard room / hallway height: **64 units**
- Player capsule height: **1.45**
- Player camera (eye) height: **1.30**
- Base texture size: **64×64** (power of 2)

### Room & Entity Initialization
- `Room` base class (`world/rooms/room.gd`)
- In `_ready()`, the Room looks at direct children of `$FuncGodotMap` and calls `initialize()` on anything that has the method.
- No recursion for now (performance – avoid walking the huge brush list).
- `initialize()` is a generic method. Entities decide what (if anything) to do when called.
- No automatic guard against multiple `initialize()` calls yet (handle per-entity if needed).
- Future: Rooms will only call `initialize()` when they become active (streaming / room activation system).

### Interaction System (In Progress)
- Player has a `Components` node containing `PlayerComponents` + `InteractionScanner`.
- `InteractionScanner` uses a persistent `RayCast3D` (currently 2m).
- Objects use a `Components` node + `Interactable` component.
- First interactable target: **Breakable Urn**
  - Placeable via `prop_urn` entity in TrenchBroom.
  - On interact: spawns physics debris (RigidBody3D) with random upward impulse.
  - Debris has a lifetime timer then fades + `queue_free()`.
  - In multiplayer: debris is client-side only (server tells clients the urn was destroyed).

### Philosophy
- Assume correct authoring for now ("fail loudly" instead of lots of defensive fallbacks).
- Keep things naive until real pain forces complexity.
- Prefer composition via Components nodes.

## What Was Worked On This Session

- Refined Interaction System architecture (raycast always on, component-based on both player and objects).
- Started `InteractionScanner` + base `Interactable` component.
- Began work on first concrete interactable (`BreakableUrn`).
- Continued discussion on Room/Entity initialization pattern.
- Locked player height + 64-unit standard for testing.
- Created initial biome docs for Crypt + first-pass texture plan.
- Updated `sizing.md` and `texture_guidelines.md` with current standards.

## Open / Next Steps

### High Priority (Next Coding Focus)
- Finish the Breakable Urn as a working interactable (including debris spawning + lifetime).
- Wire the `InteractionScanner` fully to the player (input handling, finding interactables, calling `interact()`).
- Add `initialize()` support to the urn (even if currently empty).
- Make the urn placeable and functional in the test level.

### Art / Content
- Create first-pass crypt textures (base brick, cracked brick, mossy variant, concrete floor, wooden beams, pillar textures, single + double tomb walls).
- Author a 64×128 (or similar) wall texture variant to reduce repetition on 64-unit walls.
- Update the current test room geometry to use the new 64-unit standard height + 48-high doorways.
- Create proper 3D models for the urn + debris (currently using placeholders).

### Architecture / Systems (Future)
- Flesh out proper `Room` base class with initialization pass.
- Begin thinking about room activation / streaming system (only initialize rooms when they become active).
- Decide on first few additional interactables (lever? door? chest? coffin?).
- Start basic enemy work (skeleton melee + ranger) once interaction feels solid.

### Open Questions
- Do we want `initialize()` to be the only entry point, or will some entities need `activate()` / `deactivate()` later for room streaming?
- How strict do we want the "no fallbacks" rule to be as the project grows?
- When do we want to add a proper interaction prompt / UI?

## Useful Files Right Now
- `docs/sizing.md`
- `docs/texture_guidelines.md`
- `docs/biomes/crypt.md`
- `docs/biomes/crypt_first_pass_textures.md`
- `docs/biomes/crypt_starter_kit.md`
- `world/rooms/room.gd` (new base)
- `world/rooms/test/test_room_01.gd`
- `world/components/player/interaction_scanner.gd`
- `world/components/interactable/interactable.gd`
- `world/components/interactable/breakable_urn.gd`

---

**Next session goal:** Get a working breakable urn in the test level that the player can actually interact with and destroy, using the new component + room initialization pattern.
