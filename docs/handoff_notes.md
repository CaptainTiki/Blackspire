# Handoff Notes

**Last Updated:** 2026-05-28

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
- **Review the Architecture Document** when starting any significant systems work:  
  `docs/project_blackspire_architecture.md`

### Philosophy — Fail Loudly
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
- Full swinging door system completed and verified in runtime.
  - `SwingDoor` base now uses facing-based side detection + stored `_open_side` for consistent "always push to open" behavior from both sides.
  - Four animations (`open_a/b`, `close_a/b`) + logic to always swing away from the player when opening, and close using the original swing direction.
  - Proper `Interactable` wired into `wooden_door.tscn` (under `Components`).
  - Locked state support (`is_locked`, `unlock()`, `lock()`) with explicit testing print.
  - `MapEntityRegistry` system introduced for clean targetname-based connections (levers → doors, etc.).
  - Basic `Lever` entity started with `is_active` / `has_been_used` state machine and registry lookup.

**Current State:**
- Door is fully functional and verified:
  - Opens away from player from either side (even diagonally / backface).
  - Closes correctly even after walking through.
  - Collision blocks when closed.
  - Lever/door hookup architecture designed and partially implemented via registry + targetnames.

**Next Steps / Pickup Goals (for tomorrow):**
- Continue lever system: finish `MapEntityRegistry` integration, proper FGD properties for `targetname`/`targets`, one-shot lever variant.
- Build first locked door + lever example in a TrenchBroom room.
- Decide on "Iron Door" (non-breakable) vs Wooden Door differentiation.
- Move deeper into single-player combat slice (basic enemies + combat once the locked door + lever milestone is solid).

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
- `world/rooms/room.gd`
- TrenchBroom FGD + entity definitions in `trenchbroom/`

**Recent Major Pattern:**
- Thin `Interactable` component + Entity owns real behavior (proven with Breakable Urn).
