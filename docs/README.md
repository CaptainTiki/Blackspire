# Blackspire

## North Star

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known: your team enters an unfamiliar dungeon, figures out its routes and puzzles under pressure, gathers as much loot as you dare, and must survive the return trip to keep it.

---

v0.0.0005 : Completed Breakable Urn as a working interactable. Debris pieces now own their lifetime via Timer + "shrink" AnimationPlayer, then `queue_free()`. Fully functional using the self.owner pattern (no longer dependent on Room `initialize()`). Continued refinement of lightweight diagnostic testing approach.

v0.0.0004 : Entity self-discovery via `self.owner` (replacing Room-pushed `initialize()` for the Breakable Urn). Removed `initialize()` method from base `Entity` + `BreakableUrnEntity`, and removed the initialization loop from `Room` for urns. Established lightweight goal-oriented diagnostic testing process (`.tests/` directory + headless runs with explicit goal scorecards). Continued Breakable Urn work (thin `Interactable` component + dedicated `BreakableUrnEntity` root). Moved urn to `world/entities/urn/`.

v0.0.0003 : Interaction system design + component architecture. Room initialization pattern (`initialize()`). Player height locked at 1.45 / 1.30. 64-unit standard room height adopted. Crypt biome selected as first test level. Started `Room` base class and `InteractionScanner` / `Interactable` components. First interactable target: breakable urn.

v0.0.0002 : project refinement

v0.0.0001 : project setup



