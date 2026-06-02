# Network Known Issues

**Last Updated:** 2026-06-02

This is the working punch list for the current host/client prototype. It captures observed bugs from manual two-instance testing, grouped by the authority system they belong to.

## Current Baseline

The two-instance session loop is now playable:

- client can join host
- both peers deploy from hub into the run
- player movement, rotation, jumping, and primary-action presentation replicate
- host-owned enemy movement/death replicates
- client-owned melee can kill host-owned enemies
- successful extraction returns both peers to hub
- hub summary board shows run gold on both peers

The remaining issues are mostly not mysterious networking failures. They are places where the current single-player/local-coop systems still mutate local state instead of asking the host to mutate authoritative session state and replicate the result.

## Bugs

### NET-BUG-001: Client Enemy Hit Feedback Is Missing

**Observed:** Player 2 can kill enemies and Player 1 sees those enemies die, but Player 2 does not see enemy health flash / hit feedback.

**Likely cause:** Client enemies are presentation-only and ignore local damage application. The client reports damage to the host, but the host-confirmed enemy damage result is not replicated back as a feedback event.

**Recommended next step:** Replicate enemy damage presentation events from host to clients: `enemy_id`, remaining/max health, hit position, and optional damage amount.

### NET-BUG-002: Client Player HUD Does Not Reflect Authoritative Health

**Observed:** Player 2 HUD stays at 100 HP even while Player 2 is downed. Player 2 does not see health updates when Player 1 takes damage.

**Likely cause:** Player health is still local actor state. The host applies real enemy damage, but player health/life snapshots are not broadcast to the owning client or remote peers.

**Recommended next step:** Add host-authored player health/life snapshots keyed by `session_player_id`.

### NET-BUG-003: Remote Player Downed State Is Not Visible

**Observed:** Player 1 does not see Player 2 as downed. Player 1 cannot revive Player 2.

**Likely cause:** Bleed-out/downed state currently lives in each local `PlayerLifeState`. Host-owned downed transitions are not replicated to remote presentation actors, so revive targeting cannot see the remote actor as downed.

**Recommended next step:** Replicate player life state (`alive`, `bleeding_out`, `dead`) and apply the presentation pose/state to non-local actors. Route revive interactions as host-validated requests.

### NET-BUG-004: Client Pickups Are Local Duplicates

**Observed:** Player 2 can pick up items and place them in inventory, but Player 1 still sees those same items and can also pick them up.

**Likely cause:** Pickups and inventory are still local-world/local-player mutations. The host is not validating pickup requests, assigning item instance ownership, removing world pickups, or replicating inventory changes.

**Recommended next step:** Make pickups host-owned. Clients send interact/pickup requests; host validates range/target, mutates player inventory, and broadcasts pickup removal plus inventory snapshot/update.

### NET-BUG-005: Inventories Are Not Replicated

**Observed:** Player 2 inventory changes are not visible to Player 1, and vice versa.

**Likely cause:** Player inventory and item instances are still peer-local. This is expected until inventory authority is moved to host.

**Recommended next step:** Add stable network ids for world pickups/item instances, then host-owned inventory snapshots keyed by `session_player_id`.

### NET-BUG-006: Potion Use Is Local-Only

**Observed:** Player 1 can use a health potion and restore health locally, but Player 2 does not see updates.

**Likely cause:** Hotbar activation and consumable use mutate local inventory/health directly instead of requesting host resolution.

**Recommended next step:** Treat hotbar use as a client command. Host validates bound item, consumes item, applies healing, and replicates inventory + health results.

### NET-BUG-007: Stash Is Not Shared Online

**Observed:** Both players can put things in the stash, but each peer appears to have an individual stash rather than a shared one.

**Likely cause:** `Game` owns a session-lifetime stash locally on each peer. Online sessions do not yet use the host stash as authoritative state.

**Recommended next step:** Make stash UI client-local presentation over host-owned stash state. Clients request transfer actions; host mutates stash/player inventory and broadcasts stash/inventory snapshots.

### NET-BUG-008: Run Summary Is Ahead Of Inventory Authority

**Observed:** Both players see gold on the hub board after extraction, even though pickup/inventory state is not yet fully shared.

**Likely cause:** Run summary is being synchronized enough to display, but the inventory events that feed it are not fully authoritative yet.

**Recommended next step:** Keep this as a positive milestone, but revisit summary correctness after host-owned pickups/inventory are implemented.

## Suggested Next Slices

These are networking slices to return to after the Multiplayer Playthrough Slice, unless one becomes a blocker for the fun-test run.

### Slice A: Player Health And Life State

Best next step if we want combat/run survival to feel correct.

- Host broadcasts player health/life snapshots.
- Clients update local HUD from host-confirmed health.
- Remote players show downed/dead presentation.
- Revive interaction can target replicated downed players.
- Potion use can be queued for the next slice or folded in if small.

### Slice B: Host-Owned Interactions And Pickups

Best next step if we want loot/inventory to stop duplicating.

- Clients send interact requests.
- Host validates target and range.
- Host resolves pickups and removes world pickup nodes.
- Host sends inventory updates to the owning player and pickup removal to all peers.

### Slice C: Host-Owned Inventory, Hotbar, And Stash

Best next step after Slice B, because stash/potion correctness depends on authoritative item instances.

- Host owns item instance ids and player inventory.
- Host owns crew stash inventory.
- Client UI requests transfers/use actions.
- Host sends inventory/stash snapshots.

## Current Direction

Do **not** continue pushing these networking slices immediately.

Networking has been proven enough for now. The active project direction is `docs/multiplayer_playthrough_slice_plan.md`: rebuild player/enemy feel, author the five-room playthrough, and preserve clean multiplayer-aware state/event hooks. Return to this bug list when the new gameplay foundation is ready for the next host-authority pass.
