# Project Blackspire — Architecture Document

## 1. Architecture Purpose

This document defines the technical and structural direction for Project Blackspire.

Project Blackspire is a first-person cooperative dungeon crawler built in Godot, using FuncGodot and TrenchBroom for authored dungeon spaces. The architecture must support single-player, split-screen couch co-op, and future online co-op without becoming over-engineered, overly generic, or difficult to debug.

The goal is not to build a reusable framework for many games. The goal is to build a clear, focused architecture for this game.

## 2. Core Architecture Philosophy

Project Blackspire should use a Godot-native, node-first architecture.

Core principles:

- Use Godot scenes and nodes as the primary structure.
- Use short, focused scripts.
- Use components for reusable behavior.
- Use inheritance only where it clarifies identity and shared behavior.
- Use direct references for required relationships.
- Use local signals for nearby reactions.
- Avoid global event buses for normal gameplay.
- Use state machines and state charts for readable, debuggable behavior.
- Build for four-player co-op as the maximum target.
- Avoid systems that assume there is only one player.

The preferred style is:

> Simple enough to debug, structured enough to expand, specific enough to serve this game.

## 3. Explicit Non-Goals

The architecture should avoid:

- A global gameplay event bus.
- Plugin-style generic abstractions that are not needed yet.
- Giant inheritance trees.
- Giant manager objects that own unrelated gameplay.
- 1000-line scripts.
- Systems that silently tolerate broken required components.
- Full multiplayer networking before the local architecture is proven.
- Full inventory/class/magic systems before the combat and co-op spine works.

## 4. Event and Communication Philosophy

Project Blackspire should not use a large global event bus for normal gameplay.

Global event buses make it difficult to troubleshoot who emitted an event, who listened to it, and what order things happened in. This project favors visible relationships over hidden message traffic.

### Preferred Communication Methods

Use direct references when a relationship is required.

Example:

```gdscript
@onready var health: HealthComponent = $HealthComponent
@onready var stats: StatsComponent = $StatsComponent
```

Use local signals when nearby systems need to react.

Examples:

- `HealthComponent.health_changed` updates that actor's HUD/debug UI.
- `HealthComponent.died` notifies the owning actor and room controller.
- `EquipmentComponent.weapon_changed` updates weapon visuals and stats.
- `InteractionScanner.focus_changed` updates that player's prompt.
- `StateChart.state_changed` updates actor debug labels.

Avoid global catch-all events such as:

```gdscript
EventBus.player_damaged.emit(...)
EventBus.enemy_died.emit(...)
EventBus.item_picked_up.emit(...)
```

### Rule

If a system needs to know something happened, it should usually have a clear owner, direct reference, or local signal connection explaining why.

## 5. Required Component Rule

Core gameplay scenes may require specific child components.

If a `PlayerActor` requires a `HealthComponent`, then the player scene should directly reference it and fail loudly if it is missing. The architecture should not hide broken scenes behind endless `has_node()` checks.

### Example Required Player Components

A prototype `PlayerActor` may require:

- `HealthComponent`
- `StatsComponent`
- `EquipmentComponent`
- `ActionStateChart`
- `ActionStateMachine`
- `InteractionScanner`
- `WeaponController`
- `PlayerMotor`

### Example Required Enemy Components

A prototype `EnemyActor` may require:

- `HealthComponent`
- `StatsComponent`
- `EnemyStateChart`
- `EnemyStateMachine`
- `EnemyPerception`
- `EnemyMotor`
- `AttackComponent`

### Rule

Required components should be explicit, visible, and scene-owned.

Optional components may be exported references or checked where appropriate, but core actor scenes should not pretend their required components are optional.

## 6. Inheritance Philosophy

Use inheritance for identity and broad shared actor behavior.

Preferred inheritance shape:

```text
Actor
  PlayerActor
  EnemyActor
```

Possible future descendants:

```text
Actor
  PlayerActor
  EnemyActor
  DestructibleActor
  CombatTrapActor, only if the trap behaves like a targetable/damageable combat entity
```

Avoid deep inheritance chains such as:

```text
Actor
  CombatActor
    HumanoidActor
      PlayerHumanoidCombatLootInventoryNetworkActor
```

### Actor Definition

An `Actor` is a gameplay entity that participates in one or more of the following:

- Health/damage/death
- Team or faction rules
- Combat targeting
- Stateful gameplay behavior
- Player/enemy interaction as a living or active entity

Not every object is an actor.

A spike trap, door, chest, or pressure plate may be a standalone scene with components instead of inheriting from `Actor`.

## 7. Component Philosophy

Behavior should be composed through focused nodes/components.

Components should be small and own one area of behavior.

Examples:

- `HealthComponent`
- `StatsComponent`
- `EquipmentComponent`
- `InventoryLiteComponent`
- `WeaponController`
- `MeleeAttackComponent`
- `ProjectileAttackComponent`
- `InteractionScanner`
- `PlayerMotor`
- `EnemyMotor`
- `EnemyPerception`
- `LootDropComponent`
- `ReviveComponent`
- `DownedComponent`

Components may be tightly packed into actor scenes. The architecture does not need fake-generic discovery everywhere.

Good:

```gdscript
@onready var health: HealthComponent = $HealthComponent
health.apply_damage(damage_request)
```

Avoid as a normal pattern:

```gdscript
if actor.has_node("HealthComponent"):
    actor.get_node("HealthComponent").apply_damage(...)
```

Use generic checks only when the gameplay truly supports multiple object categories and the dependency is optional.

## 8. Node-First Scene Architecture

Godot scenes are the architecture.

A scene should visually express what the object is made of. If a player has health, equipment, interaction scanning, and a weapon controller, those should be understandable from the scene tree.

### Prototype Player Scene Example

```text
PlayerActor.tscn
  PlayerActor.gd
  Body / CharacterBody3D
  Head
    CameraMount
  PlayerMotor
  HealthComponent
  StatsComponent
  EquipmentComponent
  WeaponController
  InteractionScanner
  ActionStateChart
  ActionStateMachine
  DebugStateLabel
```

### Prototype Enemy Scene Example

```text
SkeletonEnemy.tscn
  EnemyActor.gd
  Body / CharacterBody3D
  EnemyMotor
  HealthComponent
  StatsComponent
  EnemyPerception
  AttackComponent
  EnemyStateChart
  EnemyStateMachine
  DebugStateLabel
```

### Prototype Room Scene Example

```text
Room_CombatSmall.tscn
  RoomRoot
  FuncGodotImportedGeometry
  RoomController
  RoomStateChart
  RoomStateMachine
  DoorSockets
  EnemySpawnPoints
  LootSpawnPoints
  PlayerSpawnPoints
  RoomBounds
  DebugRoomLabel
```

## 9. Session and Player Slot Architecture

Project Blackspire must support:

- Single-player
- Split-screen couch co-op
- Future online co-op

The architecture should be built around player slots instead of assuming one global player.

### PlayerSlot Concept

A `PlayerSlot` represents a participant in the current session.

A local player slot owns:

- Input device/controller mapping
- Local player actor reference
- Camera rig
- Viewport assignment
- HUD instance
- Interaction prompt UI
- Player index/color/name

A future remote player slot may own:

- Remote player actor reference
- Network peer ID
- Display name
- Replication state

Remote players do not need a local input device, local HUD, or local camera on every machine.

### PlayerSlotManager Responsibilities

`PlayerSlotManager` should:

- Read session config.
- Create player slots.
- Spawn local player actors.
- Assign input devices.
- Create split-screen viewports.
- Assign cameras to viewports.
- Bind HUDs to local players.
- Track active players for enemy targeting and room logic.

## 10. Session Configuration

Main menu play mode selection should create a session configuration before loading the dungeon.

Prototype play modes:

- `SINGLE_PLAYER`
- `LOCAL_COOP`
- `ONLINE_HOST`, future
- `ONLINE_CLIENT`, future

Session config should eventually include:

- Play mode
- Local player count
- Max player count
- Dungeon scene or run setup
- Optional dungeon seed later
- Optional selected characters later

### Max Player Target

Project Blackspire should tune around four-player co-op as the maximum target.

This means:

- Couch co-op target maximum: 4 players
- Online co-op target maximum: 4 players
- Room scale should consider up to 4 players
- Enemy targeting should handle up to 4 players
- Loot chaos should assume up to 4 greedy goblins in adventurer costumes

Initial implementation may prove 1-player and 2-player first, but the architecture should avoid decisions that block 4-player support.

## 11. Split-Screen Architecture

Because Project Blackspire is first-person with free movement, couch co-op requires split-screen.

### Viewport Layout Targets

- 1 player: full-screen viewport
- 2 players: horizontal or vertical split-screen
- 3 players: deferred layout, likely one larger viewport plus two smaller or a three-panel layout
- 4 players: quadrant split

The prototype should prove 2-player split-screen first, but the layout system should be designed with 4-player support in mind.

### Per-Player Requirements

Each local player needs:

- Separate camera
- Separate viewport
- Separate HUD
- Separate input mapping
- Separate interaction raycast/prompt
- Separate weapon/action state

## 12. Input Architecture

Input should be separated from actor behavior.

### Rule

The controller reads input. The actor performs gameplay.

Preferred shape:

```text
PlayerController
  reads input device
  sends commands to PlayerActor

PlayerActor
  owns gameplay state
  asks components to perform actions
```

This separation supports:

- Keyboard/mouse single-player
- Multiple controllers for couch co-op
- Future network-controlled remote actors
- Test bots or AI-controlled player actors later

### Avoid

Avoid burying all raw input checks directly inside `PlayerActor` in a way that makes local and network control hard to separate later.

## 13. Movement Direction

Project Blackspire uses modern free first-person movement, not tile/grid movement.

The target feel is:

> Call of Duty-style free movement with swords, bows, magic armor, and dungeon nonsense.

Movement requirements:

- WASD / left-stick movement
- Mouse / right-stick looking
- Smooth collision against dungeon geometry
- Responsive first-person control
- No tile stepping
- No fixed-grid turning

Jumping, crouching, sprinting, and stamina may be added based on combat and room needs, but are not required for the earliest prototype unless the controller feel demands them.

## 14. Player-to-Player Collision

In co-op, players should not hard-block each other like immovable hallway corks.

Preferred behavior:

- Very soft push between players.
- If one player walks into another, the second player is gently moved out of the way.
- Players should not become permanently stuck in doors or corners because of each other.

Future combat may allow intentional knockback effects between players depending on friendly-fire rules.

Examples:

- Knockback sword hit pushes another player.
- Fireball explosion pushes players.
- Trap blast pushes players.

This can create chaotic co-op moments, but baseline body collision should remain forgiving.

## 15. Camera and Weapon Presentation

The prototype should use a simple first-person weapon object.

Early implementation:

- Camera-mounted or player-mounted weapon visual
- Simple attack animation or motion
- Hitbox/raycast/shape check during attack window
- No full first-person arms required for M0

Later multiplayer requirement:

- Full player body visible to other players
- Weapon model visible to other players
- Multiplayer-friendly animations

The local first-person weapon presentation and remote third-person body presentation may eventually become separate visual layers.

## 16. Combat Architecture

Combat should be built from explicit actions and damage requests.

### Basic Combat Flow

1. Controller requests attack.
2. PlayerActor forwards attack to WeaponController or ActionStateMachine.
3. Action state enters attack state.
4. Attack component enables hit detection during the active attack window.
5. Valid target is hit.
6. DamageRequest is created.
7. Target HealthComponent applies damage.
8. DamageResult is returned or emitted locally.
9. UI/VFX/SFX respond.
10. Death is handled if health reaches zero.

### DamageRequest Concept

A damage request may contain:

- Source actor
- Target actor/component
- Base damage
- Damage type
- Knockback direction
- Knockback strength
- Is critical flag, later
- Status effects, later

### DamageResult Concept

A damage result may contain:

- Damage applied
- Was blocked
- Was lethal
- Remaining health
- Hit reaction type

This structure keeps combat explicit and eventually network-friendly without needing a global combat manager early.

## 17. Health, Downed, and Death Architecture

Health should be component-based.

### HealthComponent Responsibilities

- Store max health
- Store current health
- Apply damage
- Apply healing
- Report alive/dead state
- Emit local health changed signal
- Emit local damaged signal
- Emit local died signal

### Solo Death Rule

In solo play:

- Player death ends the run.
- Player returns to hub or run-end state.

Prototype may initially reset to menu or restart, but the intended rule is run failure.

### Multiplayer Death Rule

In multiplayer:

- A player at 0 HP enters a downed state.
- Downed player has a bleed-out timer.
- Other players can revive the downed player.
- Revived player returns with very low HP, such as 1 HP.
- If all players are down/dead, the run fails or restarts.

### Downed State Components

A future downed system may include:

- `DownedComponent`
- `ReviveInteractable`
- `BleedOutTimer`
- `ReviveProgressUI`

This should be built after basic health/death works.

## 18. Friendly Fire and Knockback Direction

Baseline damage/friendly-fire rules can be tuned later, but the architecture should support source actor and team/faction checks.

Possible future rules:

- No direct friendly damage, but friendly knockback allowed.
- Reduced friendly damage.
- Full friendly fire as an optional difficulty modifier.
- Fireball splash affects everyone.

The combat system should know who caused damage or knockback so these rules can be implemented without rewriting attacks.

## 19. Equipment and Item Architecture

Items should be data-driven where practical.

### ItemDefinition Resource

An item definition should hold tunable data:

- Item ID
- Display name
- Item type
- Equip slot
- Stat modifiers
- World pickup scene/model
- Icon
- Description
- Rarity, later

### EquipmentComponent Responsibilities

- Track equipped weapon
- Track equipped armor
- Track consumable slot
- Optional trinket slots later
- Apply equipment stat modifiers
- Emit local equipment changed signals

### Prototype Pickup Rule

Prototype loot is first-come-first-served.

If a chest drops one sword, the first player to grab it owns it. Players can negotiate, argue, bargain, or betray each other socially. Friends make the best enemies.

Trading can be added later if needed.

### Inventory Scope

The prototype should start with direct pickup/equip behavior and avoid a full backpack/grid inventory until the core combat and loot loop is proven.

## 20. Interaction Architecture

Each local player needs their own interaction scanner.

### InteractionScanner Responsibilities

- Raycast or shape check from the player's camera/view
- Find focused interactable
- Ask interactable for prompt
- Send interact command when player presses interact
- Emit local focus changed signal for that player's HUD

### Interactable Interface-Style Pattern

Interactables should expose predictable methods such as:

```gdscript
func can_interact(actor: Actor) -> bool
func interact(actor: Actor) -> void
func get_prompt(actor: Actor) -> String
```

Possible interactables:

- Loot pickup
- Chest
- Door
- Revive target
- Exit portal
- Shrine, later
- Shop, later

The player controller should not contain custom code for every interactable type.

## 21. Enemy Architecture

Enemies should be actor-based and component-driven.

### EnemyActor Responsibilities

- Own required components
- Provide clear references to health, movement, perception, attacks, and state logic
- Expose debug info
- Coordinate enemy-specific behavior without containing all behavior directly

### Enemy Targeting

Enemies should target from the active player registry/list.

They should not hardcode a single player path.

Target selection may start simple:

- nearest alive player
- nearest non-downed player
- player who damaged enemy most recently, later
- threat/aggro table, later

### Prototype Enemy States

Initial enemy behavior should include:

- Idle
- Alert/AcquireTarget
- Chase
- Attack
- Stunned, optional later
- Dead

## 22. State Chart and State Machine Architecture

Project Blackspire should use a two-part state architecture:

1. **State Chart** — handles states, transitions, triggers, and state visibility.
2. **State Machine Logic** — focused node/scripts that perform actions, processing, and behavior for each state or event.

This is inspired by Godot State Charts-style workflows, where the state chart provides the formal state structure and transitions, while separate logic nodes perform gameplay work.

### Why Split These?

The state chart answers:

- What state am I in?
- What transitions are allowed?
- What trigger moved me to another state?
- What state should debug UI display?

The state machine logic answers:

- What do I do during this state?
- What action runs when a state is entered?
- What conditions do I check each tick?
- What gameplay command or animation should fire?

This keeps the system readable and debuggable.

### Example Enemy Setup

```text
EnemyActor
  EnemyStateChart
    Idle
    Chase
    Attack
    Dead
  EnemyStateMachine
    IdleLogic
    ChaseLogic
    AttackLogic
    DeadLogic
  EnemyBlackboard
  EnemyPerception
  EnemyMotor
  AttackComponent
```

### Example Flow

1. EnemyStateChart enters `Idle`.
2. State chart fires an enter event/trigger.
3. EnemyStateMachine calls `IdleLogic.enter()`.
4. IdleLogic asks perception for a target.
5. If target found, IdleLogic requests trigger `target_found`.
6. EnemyStateChart transitions to `Chase`.
7. EnemyStateMachine begins running `ChaseLogic`.

### Rule

State charts should own transitions. State machine logic should own behavior.

State logic may request transitions, but the state chart decides whether the transition is valid.

## 23. State Machine Debugging

State should be visible during development.

Debug displays should include:

- Current actor state
- Current action/combat state
- Current enemy target
- Current health
- Current room state
- Current interaction target
- Current player slot/input device

### Actor Debug Example

```text
Skeleton
State: Chase
Target: P2
HP: 14/20
```

### Player Debug Example

```text
P1
Action: Attacking
HP: 42/100
Weapon: Rusty Sword
```

### Room Debug Example

```text
Room_03_Combat
State: ActiveCombat
Enemies Alive: 3
```

Debug UI may be implemented with Label3D, screen overlays, or both.

Recommended debug toggles:

- Actor state labels
- Room state labels
- Interaction debug
- Damage/combat debug
- Player slot/input debug

## 24. Room and Dungeon Architecture

Rooms should be authored externally in TrenchBroom and imported through FuncGodot, then wrapped in Godot scenes with gameplay controllers and markers.

### Room Authoring Direction

TrenchBroom/FuncGodot should handle:

- Dungeon geometry
- Collision geometry
- Brush-based layout
- Material assignment where appropriate
- Entity/marker data if supported by the workflow

Godot room wrapper should handle:

- RoomController
- RoomStateChart
- RoomStateMachine
- Spawn point nodes
- Door socket nodes
- Loot point nodes
- Room bounds/trigger areas
- Debug labels
- Lighting adjustments if not fully authored externally

### Room Metadata

Each room should expose metadata such as:

- Room ID
- Room type
- Door sockets
- Enemy spawn points
- Loot spawn points
- Chest points
- Player spawn points
- Room bounds
- Difficulty rating, later
- Theme tag, later

### Manual First, Procedural Later

The prototype should manually connect 4–5 rooms to simulate the dungeon loop.

Procedural generation is deferred.

However, manual rooms should still use room metadata so future procedural assembly can reuse the same structure.

## 25. Room State Architecture

Each gameplay room may have its own state chart and state machine.

Prototype room states:

- Unvisited
- Entered
- ActiveCombat
- Cleared
- Rewarded
- Completed

Room responsibilities:

- Detect players entering
- Spawn or activate enemies
- Track alive enemies
- Unlock doors or rewards when cleared
- Signal dungeon run controller when completed

Use local room signals/direct references rather than global events.

Example:

- RoomController spawns enemies.
- RoomController connects to those enemies' `died` signals.
- RoomController tracks remaining enemies.
- RoomController opens doors when clear.

## 26. Dungeon Run Architecture

`DungeonRun` or `DungeonRunManager` owns the current run state.

Responsibilities:

- Start run
- Spawn players
- Load manual dungeon scene
- Track run completion/failure
- Coordinate all-players-down failure
- Return to hub/menu after run
- Later: manage generated dungeon layout

Prototype run states:

- Loading
- Playing
- Paused
- RunComplete
- RunFailed

## 27. Main Menu and Bootstrap Architecture

The main menu should not directly build gameplay objects.

Preferred flow:

1. Player chooses play mode.
2. Main menu creates/sets `GameSessionConfig`.
3. Game loads dungeon run scene.
4. DungeonRun reads config.
5. PlayerSlotManager creates appropriate player slots/viewports.
6. Dungeon begins.

This keeps single-player, couch co-op, and future online modes flowing through the same run architecture.

## 28. UI Architecture

UI should be split into per-player UI and global UI.

### Per-Player UI

Each local player should have:

- Health display
- Downed/bleed-out display
- Current weapon display
- Consumable display
- Interaction prompt
- Damage feedback, optional
- Debug state display, optional

Per-player UI binds to a specific PlayerSlot or PlayerActor.

### Global UI

Global UI may include:

- Pause menu
- Run complete screen
- Run failed screen
- Main menu
- Loading screen
- Debug overlays

### Rule

HUD code should not assume Player 1 is the only meaningful player.

## 29. Data Resource Architecture

Use Godot resources for tunable data.

Likely resource types:

- `ItemDefinition`
- `WeaponDefinition`
- `ArmorDefinition`
- `EnemyDefinition`
- `PlayerClassDefinition`, later
- `RoomDefinition`, later
- `LootTableDefinition`, later

Resources hold data. Scenes/components hold behavior.

Example:

A sword's damage, cooldown, model, icon, and stat modifiers belong in data. The weapon swing behavior belongs in weapon/attack components.

## 30. Manager Philosophy

Managers are allowed when they own a real domain.

Good managers/controllers:

- `GameSessionManager`
- `PlayerSlotManager`
- `DungeonRunManager`
- `RoomController`
- `ViewportLayoutManager`

Avoid managers that become vague dumping grounds:

- `EverythingManager`
- `CombatManager` before combat needs one
- `ItemManager` that owns all item behavior unnecessarily
- `SignalManager`

Combat can initially be component-to-component through weapons, hitboxes, hurtboxes, and health components.

## 31. Networking Preparation

Online multiplayer is not part of the earliest prototype, but the architecture should avoid obvious blockers.

Future online target:

- Four-player online co-op maximum
- Host-authoritative model
- Host owns dungeon state
- Host owns enemy AI
- Host resolves damage
- Host resolves loot pickup/equip
- Clients send input/action requests
- Clients receive replicated state/results

### Online-Friendly Rules Now

- Do not assume one player.
- Use PlayerSlots.
- Keep damage explicit.
- Keep item pickup explicit.
- Keep room state explicit.
- Keep enemy targeting based on active players.
- Keep controller/input separate from actor behavior.
- Keep local first-person visuals separate from remote player body visuals where needed.

## 32. Folder Organization Direction

Folder structure should support clarity without becoming sterile.

Suggested structure:

```text
res://src/core/
  game_session/
  player_slots/
  state/

res://src/actors/
  actor.gd
  player/
  enemies/

res://src/components/
  health/
  stats/
  combat/
  equipment/
  interaction/
  movement/

res://src/items/
  definitions/
  pickups/
  equipment/

res://src/dungeon/
  rooms/
  doors/
  markers/
  run/

res://src/ui/
  hud/
  menus/
  debug/

res://src/data/
  items/
  enemies/
  rooms/
```

Colocation is acceptable when it improves readability. For example, a scene and its script should usually live near each other.

## 33. Early Build Order Supported by Architecture

The architecture should support the prototype milestone order.

### M0 — First-Person Dungeon Room

- FuncGodot/TrenchBroom room import
- One player
- Free first-person movement
- Simple weapon object
- One enemy
- Health/damage/death
- Basic HUD/debug

### M1 — Player Slots and Split-Screen

- Session config
- PlayerSlotManager
- Two local players
- Split-screen viewports
- Per-player input
- Per-player HUD
- Enemy targets either player

### M2 — Manual Dungeon Chain

- 4–5 connected rooms
- RoomControllers
- Door sockets
- Spawn markers
- Room clear flow
- Exit trigger

### M3 — Equipment and Loot

- ItemDefinition resources
- Weapon/armor pickups
- EquipmentComponent
- Stat modifiers
- First-come-first-served loot behavior

### M4 — Prototype Run

- Start run
- Clear rooms
- Collect loot
- Down/revive in multiplayer
- Run failure when all down
- Exit completes run

### M5 — Online Readiness Review

- Audit player slot structure
- Audit input/actor separation
- Audit explicit damage/item/room events
- Audit state replication candidates
- Identify blockers before networking

## 34. Architecture Decision Defaults

These are the current project defaults unless later testing proves otherwise.

- Movement: modern free first-person movement
- Camera: first-person, split-screen for local co-op
- Max players: 4
- Couch co-op: supported target
- Online co-op: future supported target
- Player collision: very soft push, not hard blocking
- Solo death: run ends
- Multiplayer death: downed with bleed-out timer, revive to very low HP, all down equals run failure
- Loot: first-come-first-served
- Room pipeline: TrenchBroom + FuncGodot
- First rooms: manually connected
- Procedural generation: deferred
- Weapons: simple first-person weapon object first
- Remote bodies: full visible player bodies later for multiplayer
- Signals: local only
- Event bus: avoided
- State system: state chart plus behavior state machine
- Debug: visible state labels and overlays from early development

## 35. Final Architecture Summary

Project Blackspire should be built as a focused Godot game, not a generic RPG engine.

The architecture should make it easy to answer:

- Where is this behavior located?
- What node owns this state?
- What component changes this value?
- What state is this actor currently in?
- Which player slot owns this input/camera/HUD?
- Why did this room open its doors?
- Why did this enemy attack Player 2?

If the architecture helps answer those questions quickly, it is doing its job.

The guiding idea is:

> Build clear scenes, focused components, visible states, and explicit relationships. Let the dungeon be dangerous, not the codebase.

