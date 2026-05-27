# Handoff Notes

**Date:** [Current session]

## Pickup Tomorrow (Starting Point)
- We finished the Breakable Urn debris system (each piece now manages its own `time_to_live` via Timer + "shrink" animation, then `queue_free()`).
- The urn + debris are fully decoupled from the old Room `initialize()` pattern and use `self.owner` for resource discovery.
- The testing process (`.tests/` + headless diagnostics with goal scorecards) is working well.
- **Next task:** Build a hinged/swing door (`swing_door.gd` base + `wooden_door` concrete implementation). Use the same Entity + thin Interactable pattern. Support open/close via E (90° rotation on an offset hinge). Consider using AnimationPlayer for the rotation.

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
- Some entities (notably the Breakable Urn) now self-discover their owning Room via `self.owner` at the moment they need resources (e.g. junk container), rather than relying on a pushed `initialize()` call from the Room.
- The previous pattern (Room walking FuncGodotMap children and calling `initialize()`) is being de-emphasized for new entities in favor of lighter, pull-based discovery where possible.
- `initialize()` still exists on the base `Entity` but is currently a no-op for the urn and is no longer required for core functionality.

### Interaction System (In Progress)
- Player has a `Components` node containing `PlayerComponents` + `InteractionScanner`.
- `InteractionScanner` uses a persistent `RayCast3D` (currently 2m).
- Objects use a `Components` node + `Interactable` component.
- First interactable target: **Breakable Urn**
  - Placeable via `prop_urn` entity in TrenchBroom.
  - On interact: spawns physics debris (RigidBody3D) with random upward impulse.
  - Debris pieces manage their own lifetime via timer + "shrink" animation, then `queue_free()`.
  - In multiplayer: debris is client-side only (server tells clients the urn was destroyed).

### Philosophy
- Assume correct authoring for now ("fail loudly" instead of lots of defensive fallbacks).
- Keep things naive until real pain forces complexity.
- Prefer composition via Components nodes.
- Use lightweight, goal-oriented diagnostics (`.tests/`) + headless runs for verification before full runtime testing.

## Session Wrap-up (End of Day)
- Completed debris lifetime behavior for the Breakable Urn using AnimationPlayer ("shrink" animation) + self-managed timer on the debris pieces.
- Fully removed dependence on the old Room `initialize()` pattern for the urn.
- Validated that the `self.owner` + on-demand resource discovery pattern works cleanly.
- Established a working lightweight diagnostic testing process (`.tests/` + goal-oriented headless runs).
- Codebase is in a clean, slim state. Ready to pick up with the door next session.

## What Was Worked On This Session

- Refined Interaction System architecture (raycast always on, component-based on both player and objects).
- Started `InteractionScanner` + base `Interactable` component.
- Began work on first concrete interactable (`BreakableUrn`).
- Major iteration on Breakable Urn + entity initialization model: moved to self.owner discovery for resources, removed dependence on Room-pushed `initialize()`.
- Established lightweight goal-oriented testing process using `.tests/` directory + headless Godot runs for surgical verification before runtime testing.
- Locked player height + 64-unit standard for testing.
- Created initial biome docs for Crypt + first-pass texture plan.
- Updated `sizing.md` and `texture_guidelines.md` with current standards.

## Open / Next Steps

### High Priority (Next Coding Focus)
- Finish the Breakable Urn as a working interactable (including debris spawning + lifetime).
- Wire the `InteractionScanner` fully to the player (input handling, finding interactables, calling `interact()`).
- (Done) Remove dependence on Room `initialize()` for the urn; switched to self.owner pattern.
- Make the urn placeable and functional in the test level.

### Art / Content
- Create first-pass crypt textures (base brick, cracked brick, mossy variant, concrete floor, wooden beams, pillar textures, single + double tomb walls).
- Author a 64×128 (or similar) wall texture variant to reduce repetition on 64-unit walls.
- Update the current test room geometry to use the new 64-unit standard height + 48-high doorways.
- Create proper 3D models for the urn + debris (currently using placeholders).

### Architecture / Systems (Future)
- Continue evaluating when to use Room-pushed initialization vs self-discovery patterns (e.g. .owner) for entities.
- Begin thinking about room activation / streaming system (only initialize rooms when they become active).
- Decide on first few additional interactables (lever? door? chest? coffin?).
- Start basic enemy work (skeleton melee + ranger) once interaction feels solid.

### Open Questions
- (Open) What is the long-term role of `initialize()` vs self-discovery patterns (e.g. via .owner) for entities?
- How strict do we want the "no fallbacks" rule to be as the project grows?
- When do we want to add a proper interaction prompt / UI?

## Useful Files Right Now
- `docs/sizing.md`
- `docs/texture_guidelines.md`
- `docs/biomes/crypt.md`
- `docs/biomes/crypt_first_pass_textures.md`
- `docs/biomes/crypt_starter_kit.md`
- `world/rooms/room.gd`
- `world/components/player/interaction_scanner.gd`
- `world/components/interactable/interactable.gd`
- `world/entities/urn/breakable_urn.gd` + `breakable_urn.tscn` (current, working)
- `world/entities/urn/urn_debris_piece.gd` (debris now owns its own lifetime + shrink animation)
- (Next) Door work will likely live under `world/entities/door/` or similar

---

**Next session goal:** 
Build a hinged door system:
- `swing_door.gd` as a reusable base.
- Concrete `wooden_door` (scene + light script) that uses it.
- Press E to open (rotate 90° on an offset pivot so it swings clear of the wall).
- Press E again to close.
- Consider using AnimationPlayer for the rotation (gives editor control over timing/easing).
- Follow the same Entity + thin `Interactable` pattern we landed on with the urn.
