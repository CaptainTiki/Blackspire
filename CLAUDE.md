# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Blackspire is a Godot 4.6 first-person four-player procedural dungeon raid (currently a single-player / local co-op / host-client prototype). Entry point: `system/main.tscn` (project main scene). Build label is tracked in `README.md` (currently `v0.0.0052`).

## Start-of-Session Reading

Before any non-trivial change, read in this order:

1. `docs/handoff_notes.md` — current state, durable rules, key files map.
2. `docs/multiplayer_playthrough_slice_plan.md` — active milestone.
3. `docs/project_blackspire_architecture.md` — full architectural contract.
4. `world/actors/player/README.md` and `world/actors/enemies/README.md` for the relevant actor.
5. `docs/network_known_issues.md` only when touching online sync.

`docs/README.md` is the running changelog (also reflected at the top of root `README.md`). When completing work, both root `README.md` and `docs/README.md` are updated with a new `v0.0.00XX` entry.

## Engine and Dependencies

- Godot 4.6, Forward+ renderer, Jolt Physics, D3D12 driver on Windows.
- Required editor plugins (in `addons/`): `func_godot` (TrenchBroom map import) and `godot_state_charts` (state chart nodes). Both must be enabled in `project.godot` — they are.
- Map authoring lives in TrenchBroom and enters Godot through FuncGodot. See `trenchbroom/SETUP_INSTRUCTIONS.md` for the local TrenchBroom game-config bootstrap. **All maps and placed objects are TrenchBroom-authored via FGD entities. There are no hybrid scenes.** When adding placeables, add a TrenchBroom entity definition in `trenchbroom/entities/` and re-export the FGD from `trenchbroom/blackspire_game_config.tres`.

## Common Commands

There is no project build script. Iteration uses the Godot editor and ad-hoc headless runs. From the repo root with `godot` on PATH (or substitute the full path to the 4.6 binary):

```powershell
# Headless syntax/load check of the whole project
godot --headless --check-only

# Boot the project headlessly (quits quickly; useful as a smoke test)
godot --headless --quit-after 2

# Run a one-off SceneTree diagnostic script (these live in .tests/, which is gitignored)
godot --headless --script .tests/tests/diagnose_basic_enemy.gd

# Fast iteration entry that bypasses the main menu (still flows through Game)
godot --headless system/quick_entry.tscn --quit-after 2
```

Headless logs go to `godot-headless*.log` (configured in `project.godot [debug]`); these are gitignored. Expected noise: Windows root-certificate warnings and shutdown leak warnings from diagnostic scripts.

Verification habits before handing off: `godot --headless --check-only` for whole-project script compile, run a focused `.tests/tests/<diagnose_X>.gd` when relevant, then `git diff --check`.

## Bootstrap and Session Flow

There is one session container. Every play mode flows through it:

```
system/main.tscn
  -> system/menu/main_menu.tscn (or system/quick_entry.tscn for dev)
  -> GameSessionConfig (SINGLE_PLAYER | LOCAL_COOP | MULTIPLAYER_HOST | MULTIPLAYER_CLIENT)
  -> system/game/game.tscn  (class_name Game — session owner)
     -> PlayerSlotManager.create_local_session_slots(...)
     -> NetworkSession (ENet host/client wrapper, no-op for local sessions)
     -> CrewStashInventory (session-lifetime shared stash)
     -> world/hub/hub.tscn  (deploy portal + stash + summary board)
     -> world/levels/test_level.tscn  (LevelGenerator builds room chain)
     -> extraction / failure -> back to hub
```

Key files:
- `system/game/game.gd` — owns world transitions, slot manager, crew stash, host-authoritative RPC bridges (transform/action/enemy/membership snapshots).
- `system/player_slot.gd` / `system/player_slot_manager.gd` — `PlayerSlot` is a **session participant** (slot index, session_player_id, peer_id, local_player_index, is_local), not just a local input device. Slot manager owns local player spawning, input-device assignment, split-screen viewport creation, and remote-slot reconciliation from host membership snapshots.
- `system/network/network_session.gd` — focused ENet wrapper; emits `peer_joined`/`peer_left`/`connected_to_host`/`connection_failed`/`host_disconnected`.
- `system/game_session_config.gd` — play mode + host address/port/max-player/local-player fields.

There is exactly one active dungeon `Level` at runtime, accessed via `Level.current_level`. `Game` owns the world parent and explicitly destroys/instantiates hub/level on transition.

## Player Architecture

`world/actors/player/Player.tscn` uses **Godot State Charts + mirrored StateMachine scripts** in parallel branches:

- `Movement`: Grounded {Idle, Moving {Running, Sprinting}} / Airborne {Jumping}
- `Posture`: Standing / Crouching (real `StandingCollision` / `CrouchCollision` / `CrouchCheck` colliders — **no capsule resizing**)
- `Life`: Deploying -> Alive -> Downed -> Dead (Dead is not revivable)
- `Action`: Ready / PrimaryAttack / Interact / Revive / Extract

The chart owns active states and legal transitions. Mirrored state scripts under `world/actors/player/states/` own per-state entry/physics and call **intent verbs** on `PlayerController` (`run()`, `sprint()`, `request_jump_launch()`, `jump()`, `crouch()`, `stand()`, `can_stand()`, `cancel_primary_attack()`, etc.). `PlayerController` is the `CharacterBody3D` motor only — it does **not** own look math or input polling.

Per-player components (under `Components/`): `PlayerInput` (device ownership: `device = -1` keyboard+mouse, `>= 0` joypad), `PlayerLook` (mouse capture + mouse/controller look), `InteractionScanner` (focus + execution; does not poll input — the Action branch routes interact intent), `PlayerLifeState`, `PlayerEquipment`, `PlayerInventory`, `PlayerHotbar`, `PlayerMeleeAttack`, `HealthComponent`.

State scripts mirrored under `world/actors/player/states/` extend `player_base_state.gd` **by path string**, not `class_name`, to dodge global-class load-order failures on `--check-only`. Keep this pattern when adding new player states.

## Enemy Architecture

Two enemy systems currently coexist:

- **Legacy (do not extend):** `world/actors/enemies/basic_enemy.gd` + `enemy_behavior.gd` enum brain. Still used by current rooms; left as-is during the rebuild.
- **New (use for all new enemies):** `Enemy` base (`enemy.gd`) + `StateChart` + mirrored `EnemyStateMachine` (`enemy_state_machine.gd`) + state nodes under `states/`. First concrete impl: `slime.gd` / `slime.tscn`. Full contract in `world/actors/enemies/README.md`.

Contracts every new enemy must honor (see enemy README):
- `$AnimationPlayer` with clips `idle`, `move`, `windup`, `lunge`, `hurt`, `death`.
- Network surface: `network_enemy_id`, `is_dead`, `is_network_authority`, `set_network_authority_enabled(bool)`, `get_network_state()`, `apply_network_state(...)`, `apply_network_death()`. Clients run AI with authority disabled — state logic must early-return on `not enemy.is_network_authority`.
- Use motor verbs (`face_target`, `apply_horizontal_velocity`, `stop_horizontal_movement`, `move_with_gravity`) rather than editing `velocity` directly in state scripts.
- Damage routes through `apply_damage(damage_request)`; level-side spawning uses `network_enemy_id` for host/client correlation.

## Combat / Components

- `world/components/combat/health_component.gd` — `apply_damage(DamageRequest)`, `heal()`, signals `health_changed(current,max)`, `damaged`, `died`. Component-only; no global combat manager.
- `world/components/combat/damage_request.gd` / `hurtbox_3d.gd` / `world_health_bar_3d.gd` / `floating_damage_number_3d.gd` / `player_hit_feedback.gd`.
- Named 3D physics layers (set in `project.godot`): `World`, `Interactable`, `CombatHurtbox`, `WeaponHitbox`, `Player`, `Enemy`. The interaction ray excludes weapon hitboxes; weapon swings target `CombatHurtbox` explicitly. Preserve these layer roles when wiring new actors.
- Player physical damage flows: `enemy attack -> target.apply_damage(req) -> PlayerController mitigates via PlayerEquipment armor -> HealthComponent`. Non-physical damage bypasses armor.

## Rooms / Level Generation

- TrenchBroom maps live in `world/rooms/generated/*.map` and are imported as `*.tscn` via FuncGodot.
- Rooms expose connectors (TrenchBroom point entity `room_connector`) and metadata via `Room` / `RoomConnector` / `RoomChainEntry`.
- `world/level_generator.gd` deterministically assembles a room chain by aligning connector origins and opposite outward directions. The current rule is **semantic rooms do not connect directly** — they go through hallway rooms.
- `world/level.gd` owns: spawned-enemy registry, active-player registry (for enemy targeting and bleed-out logic), `has_living_enemies()`, `begin_extraction(player, delay)` countdown, `exit_level(player)`, `current_level` singleton-style accessor, run-failed when all active players are bleeding out or dead. `Game` can override `show_run_end_overlays` and `pause_on_run_end` for hub-session flow.
- `MapEntityRegistry` (`world/systems/MapEntityRegistry.gd`) wires TrenchBroom `targetname` -> `targets` activation (e.g. lever -> door).

## Items / Inventory

Data-driven via `Resource` files under `data/items/`:
- `ItemDefinition` (id, name, icon, stack rules, item type, `world_pickup_scene_path`).
- `EquipmentDefinition extends ItemDefinition` adds slot + `StatModifierDefinition[]` (enum-backed stat ids include `ATTACK_DAMAGE`, `ARMOR`, `MAX_HEALTH`, `MOVE_SPEED`, `BACKPACK_SLOTS`, `HOTBAR_SLOTS`).
- `ConsumableDefinition extends ItemDefinition` adds consumable use type + heal amount + optional replacement item.

Runtime: `ItemInstance` references a definition + quantity + unique id. `PlayerInventory.add_item()` / `add_coins()` enforce backpack capacity (all-or-nothing; rejected pickups stay in world). `PlayerEquipment` tracks equipped definitions and totals modifiers. `PlayerHotbar.HotbarBinding` links a hotbar slot to a backpack `ItemInstance` — moving the item between backpack slots preserves the binding because it points at the instance, not a slot index. Equipped bags expand visible hotbar slot count.

Dropping uses each definition's `world_pickup_scene_path`; pickup roots are `RigidBody3D` so dropped items toss into the world.

## Interaction

Two-part pattern, see `docs/project_blackspire_architecture.md` §22:
- `world/components/interactable/interactable.gd` is the thin component: exposes prompt, detects focus, forwards `_on_interact(interactable, actor)` to its `Entity` ancestor via `self.owner`-style walk.
- The Entity subclass (e.g. `breakable_urn.gd`, `swing_door.gd`, `exit_portal.gd`, `lever.gd`) owns the actual behavior.

The player `InteractionScanner` should not contain per-interactable-type branches. New interactables = new Entity script + thin `Interactable` child node; map them through a TrenchBroom point entity.

## Architectural Rules (Durable)

These are enforced project-wide and worth re-stating because they affect almost every change:

- **Short, focused scripts.** Parents own references; siblings own behavior.
- **Fail loudly.** Avoid fallback/safety-net code in prototype gameplay systems. If a required `@onready` or `@export` is missing, the game should crash visibly. Fallbacks are acceptable *only* for multiplayer timing/transition concerns.
- **No global event bus.** Use direct `@export`/`@onready` references for required relationships, local signals (`health_changed`, `focus_changed`, `state_changed`, etc.) for nearby reactions. Do not introduce an `EventBus` autoload.
- **Required components are scene-owned, not optional.** Avoid `has_node()` guards as a normal pattern.
- **Multiplayer shape.** Host-authoritative is the target. Don't assume one player anywhere; use `PlayerSlot`s and the active-player registry. Don't bind future replication to temporary animation names, node paths, or one-off presentation scripts — state-machine transitions and semantic gameplay events (e.g. `onLunge`, `primary_action_started`, `died`) are the future replication hooks.
- **Entity discovery:** prefer `@export`/known `@onready` paths; fall back to `self.owner` only when the relationship is dynamic. The older pattern of `Room` pushing `initialize(room)` into children is deprecated.
- **State charts own transitions; state-machine scripts own behavior.** State logic may *request* transitions via `state_chart.send_event(&"onX")`; the chart decides validity.

## Ignored / Local-Only Areas

- `.tests/` is gitignored; it holds local diagnostic SceneTree scripts (`extends SceneTree`, run with `--script`) and their `.txt`/`.log` outputs. Add new diagnostics here rather than `tests/` or `addons/`.
- `tools/` is currently untracked (per `git status`).
- `.godot/` (editor cache, shader cache) is auto-managed; never edit by hand.
- `godot-headless*.log` files are the configured headless log path.
