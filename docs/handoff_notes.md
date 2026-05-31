# Handoff Notes

**Last Updated:** 2026-05-31

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
- Added a small player HP HUD.
  - `HealthComponent` now emits `health_changed(current_health, max_health)`.
  - `PlayerHUD` is a player-owned `CanvasLayer` bound directly to that player's `HealthComponent`.
  - The HUD currently shows `HP current/max` in the lower-left overlay.
- Added the player bleedout / run-fail slice.
  - `PlayerLifeState` listens to player `HealthComponent.died` and turns zero HP into bleeding out instead of immediate final death.
  - Bleeding out locks player control, interaction, and melee attacks, and collapses the camera toward the floor.
  - Bleed-out duration is currently 60 seconds; expiry marks the player dead.
  - Bleeding-out and dead players notify `Level`.
  - `Level` tracks active players and shows a run-failed overlay when all active players are bleeding out or dead.
  - A small revive hook exists on `PlayerLifeState`, but revive interaction/gameplay is not wired yet.
- Changed extraction from a living-enemy gate into a delayed holdout.
  - `ExitPortal` now starts extraction through `Level.begin_extraction(player, extraction_delay_seconds)`.
  - The mapper-facing `exit_portal` property is now `extraction_delay_seconds`, currently authored as 15 seconds.
  - Extraction can start while enemies remain.
  - Starting extraction alerts every active spawned enemy to the extracting player.
  - `Level` shows a temporary countdown overlay, changes it to `Extraction Ready` when the countdown expires, and waits for another portal interaction before calling `exit_level(player)`.
- Added the first loot pickup slice on top of the closed run loop.
  - `PlayerInventory` is a tiny player-owned component that currently tracks only collected coins.
  - `Pickup` is the base interactable collection entity; `GoldPickup` adds coins to the interacting player's inventory.
  - `pickup_gold` is exposed through the FGD, and `room_treasure_01.map` / generated scene now contains 25 gold total.
  - `Level` asks the player for the exit summary, emits exit/completion signals, shows the prototype overlay, and pauses the tree.
- Added the first equipment data foundation.
  - `ItemDefinition` owns id, display name, icon, stackability, max stack, and enum-backed item type.
  - `EquipmentDefinition` extends item data with enum-backed equipment slot and an array of stat modifier resources.
  - `StatModifierDefinition` owns enum-backed stat type and a signed value, so authored equipment can carry positive and negative modifiers.
  - Added sample `gold_coin`, `rusted_sword`, and `padded_vest` resources under `data/`.
  - Focused smoke coverage loads the sample resources and verifies item type, equipment slot, and stat modifier totals.
- Added placeable direct-equipment pickups.
  - `PlayerEquipment` tracks equipped equipment definitions by slot and totals stat modifiers from equipped gear.
  - `EquipmentPickup` reads an `EquipmentDefinition`, shows an equip prompt, equips directly into the interacting player's `PlayerEquipment`, then removes itself.
  - Added `rusted_sword_pickup.tscn` and `padded_vest_pickup.tscn`.
  - Added TrenchBroom point entities `pickup_rusted_sword` and `pickup_padded_vest` to the Blackspire FGD.
  - Placed one rusted sword and one padded vest in `room_treasure_01`.
  - `PlayerMeleeAttack` now includes equipped `ATTACK_DAMAGE` modifiers; the rusted sword raises melee damage from 10 to 14.
- Added the first equipment inspection UI.
  - `toggle_equipment` is bound to Tab.
  - `PlayerEquipmentUI` is a player-owned CanvasLayer that reads that player's `PlayerEquipment` and `PlayerMeleeAttack`.
  - Direct equip-on-pickup now shows a short "Equipped X" feedback toast.
  - The Tab panel shows equipment slots, focused slot/item details, and current prototype stats.
  - This is intentionally not a backpack/grid inventory yet.

**Current State:**
- The deterministic generated dungeon now supports the full rough loop:
  - Player spawns in the authored spawn room.
  - Combat rooms spawn basic enemies from `info_enemy_spawn`.
  - Treasure side room contains breakable urns and interactable gold pickups.
  - Treasure side room also contains one rusted sword pickup and one padded vest pickup.
  - Final elite room spawns the elite enemy from the same marker type with `elite = true`.
  - Exit room contains the extraction portal.
  - Extraction is smoke-verified to start while enemies remain, alert those enemies to the extracting player, become ready after the countdown, and only complete after a second portal interaction.
  - Player failure is smoke-verified with two active players: one down/dead player does not fail the run while another player is active, but all active players bleeding out/dead fails the run.
  - Player HUD is smoke-verified to update on damage and revive.
- Validation completed:
  - Targeted player HUD smoke script passed.
  - Targeted player bleedout/fail-state smoke script passed.
  - Targeted extraction-ready smoke script passed.
  - Targeted equipment definition smoke script passed.
  - Targeted equipment pickup smoke script passed.
  - Targeted treasure equipment placement smoke script passed.
  - Targeted equipment UI smoke script passed.
  - Godot check-only exited 0.
  - `git diff --check` exited 0.
  - Remaining Godot shutdown output is the known cleanup/leak-warning noise.

**Next Steps / Pickup Goals (for tomorrow):**
- Manual play-test the full chain and confirm the countdown-to-ready-to-interact extraction flow feels readable and tense.
- Manual play-test player death: enemy drops player, camera collapse reads correctly, and all-down failure overlay appears.
- Next foundational systems path:
  1. Equipment foundation without inventory UI.
     - Next: manual play-test pickup prompts, equip feedback, and Tab equipment inspection in the generated treasure room.
     - Mirror later with armor reducing incoming damage.
  2. Item instance / inventory model without fancy UI.
     - Add enough model support for held items, stack/non-stack rules, drop, and pickup semantics.
  3. Paper-doll / equipment UI.
     - Later: add inventory-to-equipment movement, visible icons, and deeper mouse/controller input.
  4. Hub / town.
     - Add stash, prep, multiplayer lobby flow, villagers, crafting, quests, lore, and run entry once loot/equipment matters.

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
- `world/components/player/player_inventory.gd`
- `world/components/player/player_life_state.gd`
- `world/components/player/player_hud.gd`
- `world/entities/entity.gd`
- `world/entities/pickups/pickup.gd`
- `world/entities/pickups/gold_pickup.gd`
- `world/entities/exit/exit_portal.gd`
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
