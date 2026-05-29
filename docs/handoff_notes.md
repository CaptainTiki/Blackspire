# Handoff Notes

**Last Updated:** 2026-05-29

---

## Project Memories (Stable Context)

These are durable truths about how we build Blackspire.  
**At the start of every new session, re-read this entire section + the linked documents.**

### Authoring Pipeline
- All maps and placed objects are authored in **TrenchBroom**.
- Everything enters the game through **FuncGodotMap** nodes using our FGD definitions.
- There are currently no hybrid scenes or exceptions to this rule.
- **Trigger:** When working with any placeable object (props, doors, enemies, etc.), check the current FGD entities in `trenchbroom/` and how they map to Godot scenes.

### Architectural Principles
- Short, focused scripts.
- **Parents own references. Siblings own behavior.**
- Prefer direct `@export` references and hardcoded knowledge of scene structure over defensive `if has_node()` checks.
- There is exactly one active dungeon `Level` at runtime. Level-global dungeon context is available through `Level.current_level`.
- **Review the Architecture Document** when starting any significant systems work:  
  `docs/project_blackspire_architecture.md`

### Philosophy - Fail Loudly
- We want to know *immediately* when something is broken so we can fix it.
- Almost no fallbacks, safety nets, or defensive checks in prototype/single-player code.
- Fallbacks are only acceptable for multiplayer timing concerns.
- If a required node or component is missing, the game should fail hard (not silently continue).
- **Trigger:** If you see defensive `has_node()` patterns or broad fallback logic appearing in non-multiplayer code, push back.

### Current Milestone
- Single player **combat slice** (following the Prototype GDD).
- Target: Several TrenchBroom rooms, interactables, basic combat, enemies, manually connected under a test level.
- Review current prototype milestones and scope here:  
  `docs/project_blackspire_prototype_gdd.md`

### How to Work With Me
- Always start a session by re-reading:
  1. This handoff (`docs/handoff_notes.md`)
  2. The Architecture Document
  3. The Prototype GDD
- You are encouraged to be **proactive**. If you have solid context on what we're doing and why, push through multiple steps and report back. You do not need to stop after every small task.
- I am always available for direction or clarification when needed.

---

## Current Session Context

**Last Worked On:**
- Lever-operated door system completed and verified in runtime.
  - `SwingDoor` base uses facing-based side detection + stored `_open_side` for consistent "always push to open" behavior from both sides.
  - Four animations (`open_a/b`, `close_a/b`) + logic to always swing away from the player when opening, and close using the original swing direction.
  - Proper `Interactable` wired into `wooden_door.tscn` (under `Components`).
  - Door mapper property is now `player_operated`: `true` means players can directly open/close; `false` means only external activators can operate it.
  - `Level` replaced `BaseLevel`; it owns an explicit `MapEntityRegistry` child and exposes `Level.current_level.entity_registry`.
  - `MapEntityRegistry` targetname lookup is verified for lever -> door connections.
  - `Lever` entity has collision/visual placeholder mesh, `targetname` / `targets` FGD properties, and `is_active` / `has_been_used` state.
  - FuncGodot property application is handled with `@tool` entity scripts + `_func_godot_apply_properties()` so TrenchBroom values reach runtime instances.

**Current State:**
- Door + lever path is fully functional and verified:
  - Player cannot open/close a door when `player_operated = false`.
  - Lever opens the target door on first pull and closes it on second pull.
  - Door opens away from the player from either side (even diagonally / backface).
  - Door closes correctly even after walking through.
  - Collision blocks when closed.
  - Player can pass through when open.

**Next Steps / Pickup Goals (for tomorrow):**
- Next immediate step: animate the lever so it visibly throws between off/on states when operated.
- After animation, verify the lever still opens the target door on first pull and closes it on second pull.
- Optional variant: add one-shot lever behavior if the room design needs it.
- Decide on "Iron Door" (non-breakable) vs Wooden Door differentiation.
- Move deeper into single-player combat slice: basic enemy actor, health/damage, and a minimal player attack.

---

## North Star (Stable)

Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.  
It should feel like early MMO raiding before everything was known.

---

## Useful References

**Always re-read at session start:**
- `docs/project_blackspire_architecture.md`
- `docs/project_blackspire_prototype_gdd.md`
- This handoff file

**Key Systems (current focus areas):**
- `world/components/interactable/interactable.gd`
- `world/entities/entity.gd`
- `world/level.gd`
- `world/systems/MapEntityRegistry.gd`
- `world/entities/lever/lever.gd`
- `world/entities/door/swing_door.gd`
- TrenchBroom FGD + entity definitions in `trenchbroom/`

**Recent Major Patterns:**
- Thin `Interactable` component + Entity owns real behavior (proven with Breakable Urn).
- TrenchBroom-authored activation uses `targetname` / `targets` and resolves live nodes through the active `Level` registry.
