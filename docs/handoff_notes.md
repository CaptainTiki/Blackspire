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
  - The Tab panel now also carries the first backpack display slice.
- Added armor mitigation and hardened the stat pipeline.
  - `PlayerEquipment` now exposes named stat helpers for attack damage, armor, max health, and move speed.
  - `PlayerEquipment.mitigate_physical_damage()` applies flat armor reduction with a minimum of 1 chip damage for positive physical hits.
  - `PlayerController.apply_damage()` is now the player-side damage entry point and applies physical mitigation before forwarding to `HealthComponent`.
  - Enemy attacks now call `target.apply_damage(damage_request)` instead of reaching directly into the target's `HealthComponent`.
  - Non-physical damage bypasses armor for now.
  - `DamageRequest.with_amount()` preserves source, hit position, and damage type when producing adjusted requests.
- Added the item backend foundation without inventory UI.
  - `ItemInstance` is the runtime item model: item definition reference, quantity, stack helpers, split support, and unique ids for non-stackables.
  - `PlayerInventory` now stores item instances instead of only a raw coin counter.
  - `PlayerInventory.add_item()` supports stack merging, max-stack overflow, and non-stackable item instance creation.
  - Gold still works through `add_coins()` and the extraction summary, but it now uses the `gold_coin` item definition internally.
  - Inventory pickups emit `inventory_toast`, currently shown through the existing player-local equipment feedback label.
  - This deliberately does not add the inventory grid yet.
- Added the backpack and hotbar display foundation.
  - `PlayerInventory` exposes baseline slot counts: 5 backpack slots and a 3-slot hotbar placeholder.
  - The Tab paper-doll panel now shows a Backpack section populated from `PlayerInventory.get_items()`.
  - Backpack slot focus uses the existing item details area to show quantity and item modifier details where available.
  - The Hotbar section is visible but intentionally nonfunctional for now.
  - Future bag equipment should expand backpack capacity and alter hotbar size.
- Added the bag equipment capacity pipeline.
  - `EquipmentDefinition.EquipmentSlot` now includes `BAG`.
  - `StatModifierDefinition.StatType` now includes `BACKPACK_SLOTS` and `HOTBAR_SLOTS`.
  - `worn_pack` is the first bag definition: +3 backpack slots and +1 hotbar slot.
  - `pickup_worn_pack` is exposed through the TrenchBroom FGD and placed in the treasure room.
  - `PlayerInventory` computes current backpack/hotbar counts from base values plus equipped modifiers.
  - `PlayerEquipmentUI` rebuilds backpack and hotbar buttons when equipment changes the counts.
- Added backpack capacity enforcement.
  - `PlayerInventory.add_item()` and `add_coins()` now return success/failure.
  - Capacity is enforced as all-or-nothing for now; no partial gold/item pickup yet.
  - Stackable items can fit into matching stacks plus available empty slots.
  - Non-stackable items require one empty slot per instance.
  - Failed pickups emit an inventory toast and remain in the world.
  - The paper-doll stats readout shows backpack usage as used/total.
- Added mouse equip-from-backpack behavior.
  - `inventory_pick_place` and `inventory_cancel_drag` are defined in the input map.
  - Backpack slots preserve explicit slot positions, including empty holes.
  - Left-click backpack slot with no held item: hold that item.
  - Left-click backpack slot with a held item: place into empty slot or swap with occupied slot.
  - Left-click compatible equipment slot with a held equipment item: equip it.
  - Left-click occupied equipment slot with no held item: unequip it into the held cursor item.
  - Equipment pickups now go into the backpack first instead of direct-equipping.
  - Hotbar remains display-only; future hotbar assignment should link to backpack items rather than move them.
- Added hotbar binding foundation.
  - `HotbarBinding` links a hotbar slot to a real backpack `ItemInstance`.
  - `PlayerHotbar` owns bindings and uses the player's current hotbar slot count.
  - Dropping a held backpack item onto a hotbar slot returns it to the backpack and creates a link.
  - The link survives moving that same item instance to another backpack slot.
  - Clicking a bound hotbar slot, or pressing number keys 1-4, produces placeholder use feedback.
  - Hotbar slots still do not consume, equip, cast, or move items yet.
- Added generic drop-from-backpack.
  - `ItemDefinition` now carries `world_pickup_scene_path`.
  - Existing item definitions point to their pickup scenes.
  - Pickup scene roots are now `RigidBody3D`, so dropped loot can be tossed into the world.
  - The paper-doll Backpack panel has a Drop button.
  - Dropping requires holding a backpack item; equipped items must be unequipped to backpack first.
  - Dropping removes that item instance from the backpack, clears matching hotbar bindings, spawns the configured pickup scene near the player camera, and applies a small forward/up impulse.
  - Gold drops preserve stack quantity; equipment drops preserve equipment definition.
- Added health potion hotbar use.
  - `ConsumableDefinition` extends `ItemDefinition` for authored consumables.
  - `health_potion` restores 15 HP when used from a bound hotbar slot.
  - Health potion use consumes one item from the linked backpack stack and clears the hotbar binding when that stack is exhausted.
  - Health potion use creates an `empty_bottle` replacement item.
  - Replacement bottles go into the backpack when space is available; otherwise they drop into the world through the same generic rigid-body drop path.
  - `pickup_health_potion` is exposed through the TrenchBroom FGD and placed in the treasure room.
- Added controller input foundation.
  - Existing keyboard/mouse controls remain in place.
  - Controller bindings now cover the basic run loop: left stick movement, right stick look, left-stick press sprint, A jump, X interact, right trigger primary attack, Y paper-doll toggle, B drag cancel, and D-pad hotbar slots 1-4.
  - `PlayerController` owns right-stick look through `look_left/right/up/down` actions and `controller_look_speed`.
  - `PlayerEquipmentUI` disables gameplay input and controller look while the paper doll is open, then re-enables them when the panel closes.
  - Opening the paper doll from controller keeps the mouse cursor hidden; keyboard/mouse toggles still show the cursor.
  - Controller inventory movement uses focus + A-button hold/place/equip/bind/drop.
  - Controller-held items mark the source slot as `[Held]` instead of using the mouse-follow drag label.

**Current State:**
- The application bootstrap now follows the new session chain:
  - `system/main.tscn` is the app root and opens the main menu.
  - `system/menu/main_menu.tscn` routes Single Player into a `GameSessionConfig`.
  - `system/game/game.tscn` owns `PlayerSlotManager`, creates configured local slots, and loads the temporary test level world.
  - `world/levels/test_level.tscn` still owns the deterministic generated dungeon chain through `LevelGenerator`.
  - Single Player is restored through `Main -> Menu -> Game -> Level -> Rooms`.
  - `system/quick_entry.tscn` skips the menu for fast iteration while still using the same `Game` session path.
  - Temporary bridge: `Game` waits for `Level.level_ready`, calls `Level.spawn_player(player_scene)`, and assigns the spawned player/input to slot 0. This should move into `PlayerSlotManager` when local co-op spawning and viewports are implemented.
- The deterministic generated dungeon now supports the full rough loop:
  - Player spawns in the authored spawn room.
  - Combat rooms spawn basic enemies from `info_enemy_spawn`.
  - Treasure side room contains breakable urns and interactable gold pickups.
  - Treasure side room also contains one rusted sword pickup and one padded vest pickup.
  - Treasure side room also contains two health potion pickups.
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
  - Targeted armor mitigation smoke script passed.
  - Targeted inventory backend smoke script passed.
  - Targeted backpack UI smoke script passed.
  - Targeted bag capacity smoke script passed.
  - Targeted inventory capacity enforcement smoke script passed.
  - Targeted mouse inventory/equipment movement smoke script passed.
  - Targeted hotbar binding smoke script passed.
  - Targeted drop-from-backpack smoke script passed.
  - Targeted health potion smoke script passed.
  - Targeted controller input smoke script passed.
  - Targeted controller inventory pick/place smoke script passed.
  - Targeted controller inventory cursor-mode smoke script passed.
  - Targeted controller held-item affordance smoke script passed.
  - Targeted main-menu single-player boot smoke passed: `main.tscn` created `Game`, loaded `Level`, generated rooms, spawned the player, and assigned slot 0.
  - Manual controller playtest passed: movement, look, combat, interaction, inventory, equipment, hotbar, potion use, and extraction are all reachable without switching back to mouse/keyboard.
  - Godot check-only exited 0.
  - `git diff --check` exited 0.
  - Remaining Godot shutdown output is the known cleanup/leak-warning noise.

**Next Steps / Pickup Goals:**
- Manual play-test the restored menu path in the editor: launch `main.tscn`, choose Single Player, confirm mouse capture, movement/combat/loot/paper-doll/hotbar/extraction still feel correct.
- Start the local co-op slice on top of the restored session chain:
  1. Move player spawning responsibility from the temporary `Game -> Level.spawn_player()` bridge into `PlayerSlotManager`.
  2. Spawn two local players for `LOCAL_COOP`.
  3. Assign distinct `PlayerInput.device` / `owns_mouse` values per slot.
  4. Add the first 2-player split-screen viewport layout.
  5. Bind each local player's camera and HUD to that player's slot.
- Keep online/host flow as menu-only placeholder until local co-op is proven.

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
- `world/components/player/player_hotbar.gd`
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
