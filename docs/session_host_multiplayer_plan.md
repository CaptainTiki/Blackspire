# Session and Host Multiplayer Plan

**Last Updated:** 2026-06-01

## Mission

Turn the proven local co-op hub/run loop into a host-authoritative session loop:

```text
host creates session -> clients join hub -> party deploys -> run plays -> rewards resolve -> everyone returns to hub
```

The first goal is not matchmaking, internet polish, or perfect combat prediction. The first goal is a repeatable two-instance host/client lifecycle using the current `Game -> Hub -> Level -> Hub` spine.

## Current Shape

The current architecture is already close to the right outline:

- `Main` owns the menu and creates `GameSessionConfig`.
- `Game` owns one session, the `PlayerSlotManager`, the crew stash, the current hub/level world, and hub/run transitions.
- `PlayerSlotManager` creates local session slots and spawns or moves player actors between hub and run worlds.
- `PlayerSlot` now represents a session participant. It stores session identity (`session_player_id`, `peer_id`, `local_player_index`) plus local-only input, camera, split-screen viewport, and per-slot UI references where applicable.
- `Hub` emits `deploy_requested` and `stash_requested`.
- `Level` owns run state, enemy spawning, active players, extraction, completion, and failure.
- Player input is already isolated behind `PlayerInput`.
- Damage, interaction, pickups, stash movement, health, down/revive, and extraction are explicit enough to become host-owned actions.

The first slot identity mismatch has been addressed: a slot no longer only means "a local input device." The remaining work is to add a real network session layer that assigns peers, creates remote slots from connections, and feeds remote players through network commands instead of local `PlayerInput`.

## Completed Prep

- Added this plan as the working host/client blueprint.
- Expanded `PlayerSlot` with `session_player_id`, `peer_id`, `local_player_index`, and `input_device`.
- Added participant-shaped `PlayerSlotManager` APIs: `create_local_session_slots()`, `spawn_slot_players()`, `spawn_or_move_slot_players()`, and a placeholder `add_remote_slot(peer_id)`.
- Updated `Game` to use slot-shaped spawn/move calls and to create/sync split-screen viewports only for local slots.
- Verified the prep slice with Godot check-only, quick-entry hub boot, `git diff --check`, and a local ignored session-slot smoke script.

## Authority Model

Use a host-authoritative model.

The host owns:

- session creation and peer membership
- slot assignment and readiness
- hub stash state
- deployment selection and scene transitions
- level generation/room state
- enemy spawning, AI, targeting, movement, and attacks
- player damage, bleed-out, revive, death, extraction, and run failure
- pickup ownership, dropped items, stash transfers, hotbar consumption, and reward summaries

Clients own only local presentation and input intent:

- movement/look input
- action requests such as interact, attack, hotbar use, stash slot activation, ready/deploy vote
- local camera/HUD/UI rendering
- optional client-side feel improvements later

## Target Session Objects

### `NetworkSession`

Add a focused session node under `system/network/`.

Responsibilities:

- create host peer
- join host peer
- close session
- track connected peers
- expose `is_host`, `local_peer_id`, and host peer id
- emit peer joined/left signals
- provide small wrappers for host-only checks and client request RPCs

This node should not know combat, inventory, UI layout, or dungeon details.

### `SessionPlayer`

Add a small resource or data script representing durable player identity.

Fields to start:

- `session_player_id`
- `peer_id`
- `local_player_index`
- `slot_index`
- `display_name`
- `is_local`
- `is_host`
- `is_connected`

`local_player_index` keeps local co-op compatible with online later. A single peer can eventually own more than one local player.

### Expanded `PlayerSlot`

Keep `PlayerSlot`, but make it session-shaped:

- `slot_index`
- `session_player_id`
- `peer_id`
- `local_player_index`
- `is_local`
- `is_host_owned`
- `player`
- local-only input/camera/viewport/UI references

Remote slots should have no local `PlayerInput`, camera, or split-screen UI on a client unless that slot is owned locally.

### `PlayerCommand`

Add a compact command object or dictionary shape for client-to-host input:

- movement vector
- look delta/vector
- sprint/jump
- attack pressed
- interact pressed
- hotbar slot
- optional sequence/tick

The first prototype can send simple unreliable/reliable RPCs directly. A formal command buffer can arrive once the lifecycle works.

## Milestone 1: Two-Instance Session Skeleton

Definition of done:

- main menu can start Host
- a second instance can Join by address/port or hardcoded localhost during development
- host and client create one slot each
- both players appear in the hub
- host can deploy
- both instances load the run
- both player actors appear in the run
- host can complete or fail the run
- both instances return to hub with the same session alive

Combat, enemies, inventory, and stash can be minimal or host-only during this milestone. The lifecycle is the prize.

Implementation steps:

1. Add `SessionType.MULTIPLAYER_HOST` and `SessionType.MULTIPLAYER_CLIENT` to `GameSessionConfig`.
2. Add host/client fields to `GameSessionConfig`: address, port, max players, local player count.
3. Wire `Main._on_host_game()` to create a host session instead of printing the placeholder.
4. Add a temporary quick-entry host/client path for smoke testing two instances.
5. Add `NetworkSession` and connect peer joined/left signals.
6. Expand the current slot paths with host/client-specific helpers:
   - `create_host_slot(...)`
   - `add_remote_slot(peer_id, ...)`
7. Spawn host-owned and remote player actors in hub from the same `PlayerSlotManager` path.
8. Add host RPC for deploy: clients request deploy/ready, host calls the existing `_load_starting_world()` path.
9. Add scene transition RPCs: host tells clients to load hub or run.
10. Smoke test two instances through hub -> run -> hub.

## Milestone 2: Networked Player Presence

Definition of done:

- each peer controls only its own player
- remote players move visibly on other peers
- remote camera/weapon presentation can be crude
- disconnect during hub removes or marks the slot
- reconnect/late join policy is explicit, even if late join is "hub only"

Recommended path:

- Split `PlayerController` into local input application and replicated state application only where necessary.
- Keep the real player actor scene for all players.
- Disable local `PlayerInput` processing for remote slots.
- Host receives client movement/look commands and applies movement.
- Host replicates player transforms, health, life state, and basic animation/combat state.
- Clients can locally apply their own camera/look for feel later; do not start there.

## Milestone 3: Host-Resolved Interaction and Loot

Definition of done:

- clients can request interact
- host validates the target and range
- host resolves pickups, drops, stash transfers, deploy portal, exit portal, and revive
- resulting inventory/stash/world changes replicate to all relevant peers

Important decisions:

- Stash inventory stays session-owned under `Game`, but mutates on host only.
- Player inventory remains player-owned, but host is the source of truth during online sessions.
- Client UI should request actions by slot index/item id, then refresh from host-confirmed state.

## Milestone 4: Host-Resolved Combat

Definition of done:

- clients can attack
- host validates attack timing and hit results
- enemy AI runs only on host
- host replicates enemy state, damage results, death, and player down/revive state
- all-down failure and extraction completion are host-owned

Use the current explicit combat path as the starting point:

```text
attack intent -> host attack window/hit check -> DamageRequest -> HealthComponent -> local signals -> replicated result
```

## Milestone 5: Session Hardening

Definition of done:

- client disconnect during hub is handled
- client disconnect during run is handled
- host quit returns clients to menu or a clear disconnected state
- duplicate slot/index bugs are rejected loudly
- run transition cannot start while clients are mid-stash/mid-inventory drag
- two consecutive network deployments work

## Known Risks

- `PlayerSlotManager` currently treats every slot as local input. This is the first refactor.
- `PlayerController._physics_process()` directly reads `PlayerInput`; remote players need a non-local command source.
- `InteractionScanner`, `PlayerMeleeAttack`, `PlayerHotbar`, and UI scripts currently react to local input. Online mode needs these to send requests when the slot is client-owned, and execute directly only when host/local-authoritative.
- The current split-screen viewport code lives inside `Game`. That is fine for now, but network sessions should only create split-screen UI for local slots.
- `Level.current_level` is acceptable for one active level, but online timing needs care during client scene transitions.
- Runtime item instances need stable ids for replication. Non-stackable items already have unique ids, but stackable item movement/pickup replication needs an explicit state snapshot format.

## First Build Target

Build a local-host networking skeleton with Godot high-level multiplayer:

```text
Host button -> ENet host -> Game starts as host -> creates host slot -> loads hub
Client quick entry -> ENet client -> joins localhost -> host creates remote slot -> both load hub
Host deploy -> both load run -> both spawn -> host exits -> both return hub
```

Keep gameplay shallow until that exact loop is boringly reliable.
