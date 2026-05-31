# Blackspire

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known.

## Current Status (as of 2026-05-31)

- **Core authoring pipeline**: Fully TrenchBroom + FuncGodot. Everything placeable comes through the FGD.
- **Interaction system**: Thin `Interactable` component + `Entity` owns real behavior (proven pattern).
- **Swinging Door System**: Fully functional and runtime verified.
  - Always pushes open away from the player (from either side, including diagonals/backfaces).
  - Consistent closing using the original swing direction.
  - Proper collision blocking when closed.
  - `player_operated` support for doors that cannot be opened directly by the player.
  - Lever + door activation verified via `Level.current_level.entity_registry` + TrenchBroom `targetname` / `targets`.
- **First combat slice**: Playable and runtime verified.
  - First-person sword visual with attack animation and active hitbox window.
  - Reusable health/damage/hurtbox path.
  - Wooden doors and urns can be damaged/broken by sword hits.
  - Iron doors are combat-immune but can still be lever/interaction controlled.
  - Floating damage numbers, timed damaged-target health bars, player hit flash feedback, and a small player HP HUD are working.
  - Player zero-health now enters a bleeding-out state with controls locked and camera collapsed toward the floor.
  - Bleeding-out players notify `Level`; bleed-out expiry marks the player dead.
  - `Level` tracks active players and shows a run-failed overlay when all active players are bleeding out or dead.
  - Basic enemy spawns from TrenchBroom `info_enemy_spawn`, chases, uses a readable windup + forward cone lunge attack, damages the player, and can be killed.
  - Elite enemy variant spawns from the same marker type via an `elite` Yes/No property, using the basic enemy brain with heavier prototype tuning.
  - Enemy death now has a clear lifecycle: `die()` starts cleanup, then `decompose()` removes the enemy after a short timer.
- **Collision layers**: First named layer pass is in place for world, interactables, combat hurtboxes, weapon hitboxes, player, and enemy bodies.
- **Manual room-chain generation**: First deterministic authored dungeon chain is playable and runtime verified.
  - Rooms are authored as TrenchBroom maps and wrapped by reusable `Room` scenes.
  - `room_connector` point entities define mapper-facing doorway IDs, tags, dimensions, and outward direction.
  - `LevelGenerator` aligns rooms by connector transforms and spawns the generated chain before player/enemy setup.
  - Current test chain uses hallway buffers between rooms: spawn, 4-way combat, treasure side branch, small combat, elite room, and exit room.
  - Enemy spawns, player spawns, breakable urns, extraction portal, and traversal all work across generated room transforms.
- **Prototype loop closure**: `exit_portal` is a TrenchBroom-authored extraction entity.
  - Extraction can start while enemies remain.
  - Interacting with the portal starts a 15-second extraction countdown and alerts active enemies to the extracting player.
  - When the countdown ends, the overlay changes to "Extraction Ready"; interacting with the portal again calls `Level.exit_level(player)`.
  - Successful extraction shows a temporary run-complete overlay using the player's carried loot summary.
- **First loot slice**: Mapper-authored gold pickups are interactable and player-owned.
  - `PlayerInventory` currently tracks only picked-up coins.
  - `Pickup` provides the base interactable collection flow; `GoldPickup` adds coins to the interacting player's inventory.
  - `pickup_gold` is exposed through the FGD, and the treasure room currently contains 25 gold total.
- **Equipment data foundation**: First item/equipment definitions are in place.
  - `ItemDefinition`, `EquipmentDefinition`, and `StatModifierDefinition` are enum-backed Godot resources under `data/items`.
  - Equipment carries an equipment slot plus an array of signed stat modifiers.
  - Sample definitions exist for a gold coin, rusted sword, and padded vest.
- **Placeable equipment pickups**: Direct equip-on-pickup is working without inventory UI.
  - `PlayerEquipment` tracks equipped definitions by slot.
  - `rusted_sword_pickup` and `padded_vest_pickup` are available as TrenchBroom point entities.
  - The current treasure room contains one rusted sword and one padded vest.
  - The rusted sword's attack modifier currently raises player melee damage from 10 to 14.
- **Equipment inspection UI**: Tab opens a small player-owned paper doll.
  - Equip pickups show a short "Equipped X" feedback toast.
  - The panel shows equipment slots, focused item details, and current prototype stats.
  - The same panel now carries the first backpack display slice.
- **Armor mitigation**: Equipped armor now affects incoming physical damage.
  - `PlayerController.apply_damage()` applies player-owned mitigation before forwarding to `HealthComponent`.
  - The padded vest's armor currently reduces physical hits by 3, with at least 1 chip damage.
  - Non-physical damage bypasses armor for now.
- **Item backend foundation**: Inventory is now item-instance backed without a grid UI yet.
  - `ItemInstance` tracks item definition, quantity, stackability, split behavior, and non-stackable ids.
  - `PlayerInventory` supports `add_item()`, stack merging, max-stack overflow, item counts, and gold through `gold_coin`.
  - Pickup readouts use a player-local toast so backend changes are visible during playtests.
- **Backpack and hotbar UI foundation**: The paper-doll panel now shows inventory space.
  - Players start with 5 baseline backpack slots and 3 baseline hotbar placeholders.
  - Hotbar slots can now bind to backpack items without moving the item out of the backpack.
  - Bag equipment now expands backpack capacity and can alter hotbar size.
  - The current `worn_pack` pickup grows the backpack from 5 to 8 slots and the hotbar from 3 to 4 slots.
  - Backpack capacity is enforced: full backpacks reject new item stacks/instances and leave pickups in the world.
  - Mouse-driven backpack/equipment movement is working: click to hold, click to place, occupied slots swap.
  - Equipment pickups now go to the backpack first instead of direct-equipping.
  - Hotbar activation now supports health potion use; other item actions still report item-specific placeholder feedback.
  - Backpack items can be dropped through the paper-doll Drop button, spawning their definition's pickup scene as a tossed rigid body.
  - Health potions restore 15 HP from the hotbar, consume one potion, and leave an empty bottle in the backpack or drop it if the backpack is full.
- **Controller input foundation**: First single-controller pass is in place.
  - Left stick moves, right stick looks, left-stick press sprints, A jumps, X interacts, right trigger attacks, Y opens the paper doll, B cancels held inventory drag, and the D-pad activates hotbar slots 1-4.
  - Right-stick look is handled in `PlayerController` and pauses while the paper-doll UI is open.
  - Opening the paper doll from controller keeps the mouse cursor hidden; opening it from keyboard/mouse still shows the cursor.
  - Paper-doll inventory movement now supports controller focus + A-button hold/place/equip/bind/drop without fake mouse dragging.
  - Manual controller playtest verified the full current run loop has no missing controller-only blockers.
- **Level context**: `Level` owns the active dungeon context and explicit `MapEntityRegistry`.
- **Philosophy**: Strong emphasis on short focused scripts, "fail loudly" (minimal defensive fallbacks in single-player code), direct references, and lightweight diagnostics (`.tests/` + headless runs).

## Key Documents

- [Project Changelog / Version History](docs/README.md)
- [Handoff Notes](docs/handoff_notes.md) — Start here for the next session
- [Architecture Document](docs/project_blackspire_architecture.md)
- [Prototype GDD](docs/project_blackspire_prototype_gdd.md)

## Quick Start for Development

1. Read the latest [handoff notes](docs/handoff_notes.md).
2. Re-read the Architecture Document and Prototype GDD.
3. Use the `.tests/` directory + headless Godot runs for fast iteration and verification.

## Recent Major Work

See [docs/README.md](docs/README.md) for the full version history.

Latest equipment milestones:
- `v0.0.0018` Equipment Definition Foundation.
- `v0.0.0019` Direct Equip-on-Pickup.
- `v0.0.0020` Paper-doll + Stats.
- `v0.0.0021` Armor Mitigation + Stat Pipeline.
- `v0.0.0022` Item Backend Foundation.
- `v0.0.0023` Backpack and Hotbar UI Foundation.
- `v0.0.0024` Bag Equipment Capacity Pipeline.
- `v0.0.0025` Backpack Capacity Enforcement.
- `v0.0.0026` Mouse Equip From Backpack.
- `v0.0.0027` Hotbar Binding Foundation.
- `v0.0.0028` Generic Drop From Backpack.
- `v0.0.0029` Health Potion Hotbar Use.
- `v0.0.0030` Controller Input Foundation.

Current focus: Choose the next large slice: player-slot/local co-op scaffolding, or the first Hub/Town shell and run-transition wrapper.

---

*This is still very early prototype work. Lots of systems are intentionally minimal while we prove the core loop.*
