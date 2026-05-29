# Blackspire

## North Star

**Blackspire is a four-player procedural dungeon raid about discovery, greed, survival, and escape.** It recreates the feeling of early MMO raiding before every answer was known: your team enters an unfamiliar dungeon, figures out its routes and puzzles under pressure, gathers as much loot as you dare, and must survive the return trip to keep it.

---

v0.0.0008 : First combat slice completed and play-verified. Added reusable `HealthComponent`, `DamageRequest`, `Hurtbox3D`, first-person sword attack, floating damage numbers, world health bars, and player hit flash feedback. Wooden doors are now breakable by sword hits; iron doors are unbreakable but can still be interaction/lever controlled. Urns can be smashed by sword hurtbox overlap. Added `BasicEnemy` with a temporary dedicated `EnemyBehavior` enum brain (`IDLE`, `CHASE`, `ATTACK`, `DEAD`), health, hurtbox, damage feedback, death handling, and TrenchBroom entity `enemy_basic`. `Level` now consumes `info_enemy_spawn` markers and spawns basic enemies from the authored map. Verified: enemy spawns from marker, chases/attacks player, player can see hit feedback, sword damages/kills enemy, sword breaks doors/urns, and lever/door regressions still pass.

v0.0.0007 : Lever-operated door milestone completed and runtime-verified. `BaseLevel` renamed to `Level`, with a single active dungeon context exposed through `Level.current_level`. `Level` now owns an explicit `MapEntityRegistry` child used by TrenchBroom-authored `targetname` / `targets` activation. Door mapper property is now `player_operated`: false blocks direct player operation while still allowing external activators. Lever scene now has collider + placeholder visuals, receives FuncGodot properties via `@tool` scripts, and toggles target doors open/closed. Verified: player cannot operate remote-only doors, lever opens/closes target door, collision blocks while closed, and player can pass while open.

v0.0.0006 : Swinging door system completed and runtime-verified. `SwingDoor` base now delivers consistent push-to-open behavior from both sides using facing-based detection + stored open side for closing. Four animations (open_a/b + close_a/b). Proper `Interactable` wired. Locked door support + explicit testing path. `MapEntityRegistry` introduced for clean targetname-based lever/door (and future) connections. Basic Lever entity with `is_active`/`has_been_used` state machine. Strong "no fallbacks / fail loudly" + short focused scripts philosophy reinforced across the codebase. Lightweight diagnostics continue to be very effective.

v0.0.0005 : Completed Breakable Urn as a working interactable. Debris pieces now own their lifetime via Timer + "shrink" AnimationPlayer, then `queue_free()`. Fully functional using the self.owner pattern (no longer dependent on Room `initialize()`). Continued refinement of lightweight diagnostic testing approach.

v0.0.0004 : Entity self-discovery via `self.owner` (replacing Room-pushed `initialize()` for the Breakable Urn). Removed `initialize()` method from base `Entity` + `BreakableUrnEntity`, and removed the initialization loop from `Room` for urns. Established lightweight goal-oriented diagnostic testing process (`.tests/` directory + headless runs with explicit goal scorecards). Continued Breakable Urn work (thin `Interactable` component + dedicated `BreakableUrnEntity` root). Moved urn to `world/entities/urn/`.

v0.0.0003 : Interaction system design + component architecture. Room initialization pattern (`initialize()`). Player height locked at 1.45 / 1.30. 64-unit standard room height adopted. Crypt biome selected as first test level. Started `Room` base class and `InteractionScanner` / `Interactable` components. First interactable target: breakable urn.

v0.0.0002 : project refinement

v0.0.0001 : project setup
