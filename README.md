# Blackspire

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known.

## Current Status (as of 2026-05-30)

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
  - Floating damage numbers, timed damaged-target health bars, and player hit flash feedback are working.
  - Basic enemy spawns from TrenchBroom `info_enemy_spawn`, chases, uses a readable windup + forward cone lunge attack, damages the player, and can be killed.
- **Collision layers**: First named layer pass is in place for world, interactables, combat hurtboxes, weapon hitboxes, player, and enemy bodies.
- **Manual room-chain generation**: First deterministic authored dungeon chain is playable and runtime verified.
  - Rooms are authored as TrenchBroom maps and wrapped by reusable `Room` scenes.
  - `room_connector` point entities define mapper-facing doorway IDs, tags, dimensions, and outward direction.
  - `LevelGenerator` aligns rooms by connector transforms and spawns the generated chain before player/enemy setup.
  - Current test chain uses hallway buffers between rooms: spawn, 4-way combat, treasure side branch, small combat, and larger boss/elite-room shell.
  - Enemy spawns, player spawns, breakable urns, and traversal all work across generated room transforms.
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

Current focus: Turning the larger boss-room shell into an "elite enemy" encounter without jumping all the way to bespoke boss/state-chart design yet.

---

*This is still very early prototype work. Lots of systems are intentionally minimal while we prove the core loop.*
