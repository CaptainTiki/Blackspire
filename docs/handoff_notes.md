# Handoff Notes

**Last Updated:** 2026-05-30

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
- Single player **closed prototype loop** (following the Prototype GDD).
- Current loop: spawn -> hallway-separated combat rooms -> treasure side branch -> elite room -> exit room / extraction portal.
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
- Closed the first run loop with a mapper-authored exit room and extraction portal.
  - `exit_portal` is a scene-backed FGD point entity with mapper-facing prompt, completion message, and `requires_all_enemies_defeated` properties.
  - `room_exit_01.map` / `room_exit_01.tscn` adds a small crypt exit room with a visible portal plinth/glow/label.
  - `test_level` now connects elite room -> hallway -> exit room, preserving the current hallway-between-rooms convention.
  - `Level.complete_run()` emits `run_completed`, shows a temporary run-complete overlay, and pauses the tree.
  - `Level.has_living_enemies()` lets the portal block extraction until spawned enemies have been cleared.

**Current State:**
- The deterministic generated dungeon now supports the full rough loop:
  - Player spawns in the authored spawn room.
  - Combat rooms spawn basic enemies from `info_enemy_spawn`.
  - Treasure side room contains breakable urns.
  - Final elite room spawns the elite enemy from the same marker type with `elite = true`.
  - Exit room contains the extraction portal.
  - Extraction is smoke-verified to refuse while enemies remain and complete once `Level.spawned_enemies` is clear.
- Validation completed:
  - Targeted exit-loop smoke script passed.
  - Godot check-only exited 0.
  - Short headless boot exited 0.
  - Remaining Godot shutdown output is the known cleanup/leak-warning noise.

**Next Steps / Pickup Goals (for tomorrow):**
- Manual play-test the full chain and confirm the portal room reads well after the elite fight.
- Decide the next slice:
  - Real loot pickup / carry / extract storage.
  - Exit transition target: menu, next biome placeholder, or run summary screen.
  - Enemy architecture cleanup toward state charts/state machines.
  - Mapper workflow cleanup for enemy spawn types and room metadata.

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
- `world/components/combat/health_component.gd`
- `world/components/combat/damage_request.gd`
- `world/components/combat/hurtbox_3d.gd`
- `world/components/combat/player_melee_attack.gd`
- `world/components/combat/floating_damage_number_3d.gd`
- `world/components/combat/world_health_bar_3d.gd`
- `world/components/combat/player_hit_feedback.gd`
- `world/entities/entity.gd`
- `world/level.gd`
- `world/systems/MapEntityRegistry.gd`
- `world/entities/lever/lever.gd`
- `world/entities/door/swing_door.gd`
- `world/entities/door/wooden_door.gd`
- `world/entities/door/iron_door.gd`
- `world/actors/enemies/basic_enemy.gd`
- `world/actors/enemies/enemy_behavior.gd`
- TrenchBroom FGD + entity definitions in `trenchbroom/`

**Recent Major Patterns:**
- Thin `Interactable` component + Entity owns real behavior (proven with Breakable Urn).
- TrenchBroom-authored activation uses `targetname` / `targets` and resolves live nodes through the active `Level` registry.
- Combat damage path is now `weapon active hitbox -> Hurtbox3D -> explicit damage_target.apply_damage(DamageRequest) -> HealthComponent`.
- Feedback is signal-driven off `HealthComponent.damaged` / `HealthComponent.died` where possible.
- Keep temporary behavior brains (`EnemyBehavior`) as siblings under `Components`, so the actor root stays close to the future state-machine shape.
