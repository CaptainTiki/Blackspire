# Blackspire

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known.

## Current Build

`v0.0.0053` - Room compositor and standard door vocabulary foundation; proto viewer for walkable room iteration.

## Current Direction

We have proven the technical session spine:

- single-player, local co-op, host, and client sessions all use the same `Game` / `PlayerSlotManager` shape
- host/client join and membership work
- hub -> run -> hub works in a two-instance session
- player transform and primary-action presentation replicate
- enemies can be host-owned, with client attacks forwarded to the host
- the remaining network bugs are understood as authority gaps, not unknown blockers

The next milestone is no longer "prove networking." It is:

**Make the first five multiplayer minutes fun enough to put in front of players.**

That means stepping back from deeper temporary-network patching and rebuilding the player, enemies, and first authored combat rooms around state-machine-driven gameplay, readable feel, and clean multiplayer-aware event hooks.

The current player baseline now includes analog controller movement magnitude, sprint and crouch speed multipliers, sprint wind-up and turn weight, attack movement drag, deliberate crouch camera movement, an active state debug label, real jump-state launch handling, melee cancel on Downed/Dead, and a first player life snapshot shape for future host-authoritative health/life replication.

## Active Plan

- [Multiplayer Playthrough Slice Plan](docs/multiplayer_playthrough_slice_plan.md)
- [Handoff Notes](docs/handoff_notes.md)
- [Architecture Document](docs/project_blackspire_architecture.md)
- [Prototype GDD](docs/project_blackspire_prototype_gdd.md)
- [Network Known Issues](docs/network_known_issues.md)
- [Project Changelog / Version History](docs/README.md)

## Development Notes

- Maps and placeable objects are authored in TrenchBroom and enter through FuncGodot.
- We prefer short scripts, direct references, and fail-loud behavior.
- Networking should remain host-authoritative, but the next gameplay pass should not over-invest in syncing temporary internals.
- Use `.tests/` and Godot headless runs for fast verification.

## Quick Start

1. Read [docs/handoff_notes.md](docs/handoff_notes.md).
2. Read [docs/multiplayer_playthrough_slice_plan.md](docs/multiplayer_playthrough_slice_plan.md).
3. Re-read the architecture/prototype docs when touching systems or scope.

---

*This is still prototype work. The next slice is not a public demo; it is the "is this fun?" pass.*
