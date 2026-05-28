# Blackspire

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known.

## Current Status (as of 2026-05-28)

- **Core authoring pipeline**: Fully TrenchBroom + FuncGodot. Everything placeable comes through the FGD.
- **Interaction system**: Thin `Interactable` component + `Entity` owns real behavior (proven pattern).
- **Swinging Door System**: Fully functional and runtime verified.
  - Always pushes open away from the player (from either side, including diagonals/backfaces).
  - Consistent closing using the original swing direction.
  - Proper collision blocking when closed.
  - Locked state support with explicit testing feedback.
  - Lever + door connection architecture in progress via `MapEntityRegistry` + targetnames.
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

Current focus: Completing the single-player combat slice (interactables, locked doors + levers, basic enemies/combat, multiple connected TrenchBroom rooms).

---

*This is still very early prototype work. Lots of systems are intentionally minimal while we prove the core loop.*