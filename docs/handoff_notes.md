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
- First combat slice reached a playable prototype state.
  - Lever now has `activate` / `deactivate` animations, locks out repeat interactions during its own animation and while activated targets finish animating.
  - Door types are now split:
    - `door_swing` / `WoodenDoor`: breakable by combat, still interactable/lever-operable.
    - `door_iron` / `IronDoor`: unbreakable by combat, still interactable/lever-operable depending on `player_operated`.
  - `HealthComponent`, `DamageRequest`, `Hurtbox3D`, `PlayerMeleeAttack`, `FloatingDamageNumber3D`, `WorldHealthBar3D`, and `PlayerHitFeedback` establish the first reusable combat feedback spine.
  - Player now has a visible first-person sword with a simple attack animation and active-window `Area3D` hitbox.
  - Wooden doors and urns have hurtboxes; sword hits can break wooden doors and smash urns.
  - `BasicEnemy` scene exists with `HealthComponent`, `Hurtbox3D`, floating damage feedback, and a dedicated temporary `EnemyBehavior` child.
  - `EnemyBehavior` currently uses simple enum states (`IDLE`, `CHASE`, `ATTACK`, `DEAD`) so it can later be replaced by a real state chart/state machine without rewriting the `BasicEnemy` combat contract.
  - `info_enemy_spawn` markers are now consumed by `Level.spawn_enemies()` and spawn `basic_enemy.tscn` from the TrenchBroom-authored marker.

**Current State:**
- Door + lever + first combat loop is functional and play-verified:
  - Player can pull animated levers; lever spam is gated.
  - Lever opens/closes remote-only iron doors; player cannot directly operate those doors when `player_operated = false`.
  - Wooden doors can be opened/closed normally and can be broken by sword hits.
  - Iron doors ignore primary sword attacks and keep blocking until opened by interaction/lever.
  - Sword hitbox overlaps hurtboxes, not debug raycast damage.
  - Urns can be smashed by sword hurtbox overlap.
  - Floating damage numbers are readable, smaller, billboarded, and use `no_depth_test`.
  - Damaged wooden door health bars show only when aimed at, appear immediately, and fade after focus loss.
  - Enemy spawns from the TrenchBroom marker, can chase/attack the player, can damage the player, and can be slain by sword hits.
  - Player hit feedback now flashes red when enemy damage lands.

**Next Steps / Pickup Goals (for tomorrow):**
- Immediate pickup: polish enemy readability and feel.
  - Add an obvious enemy attack tell / lunge / animation so the enemy does not look like it is standing still while damaging the player.
  - Add enemy health bar/focus behavior using the same feedback spine as doors, or decide whether enemies should always show health after damage.
  - Add enemy hit reaction when the sword connects.
  - Tune enemy movement, attack range, attack cooldown, and damage.
  - Consider a simple debug state label over enemy head while behavior remains enum-based.
- After enemy feel is readable, consider a first cleanup pass:
  - Review `EnemyBehavior` boundaries so it can later split into state chart + state machine logic.
  - Review `WorldHealthBar3D` for optional focus-less targets like enemies.
  - Review player feedback layering if/when proper HUD/split-screen UI starts.
- Optional gameplay variants:
  - One-shot lever behavior.
  - `enemy_type` property on `info_enemy_spawn` to choose enemy variants instead of always spawning `basic_enemy_scene`.

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
