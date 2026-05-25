# Project Blackspire — Prototype GDD

## 1. Prototype Purpose

The Project Blackspire prototype exists to prove the core game loop, technical foundation, and multiplayer structure before expanding into the full roguelite dungeon crawler vision.

This prototype is not the full game. It is a controlled, reduced-scope version of the game designed to answer the most important questions early:

- Does first-person dungeon combat feel good?
- Does split-screen couch co-op work structurally?
- Can multiple players fight, loot, and interact cleanly?
- Can authored TrenchBroom rooms support the dungeon flow?
- Can equipment and stat changes be proven without a full inventory system?
- Can the project architecture support future online multiplayer without building online first?

The prototype should feel like the smallest playable version of Project Blackspire: players enter a small dungeon, fight enemies, pick up gear, survive several rooms, and reach an exit.

## 2. Prototype Target Experience

The prototype target experience is:

> One to two local players enter a small manually connected dungeon, fight basic monsters, collect simple gear, equip upgrades, and reach an exit room.

The prototype should be fun enough that a friend can sit down, pick up a controller, fight through a few rooms, and understand the core promise of the full game.

The prototype should prioritize feel, readability, and architecture over content volume.

## 3. Prototype Design Pillars

### Pillar 1 — Prove the Spine

The prototype must touch the major systems that the full game depends on: player slots, cameras, combat, enemies, items, equipment, rooms, interaction, and UI.

### Pillar 2 — Fake the Expensive Stuff

Manual room connections simulate procedural generation. Simple equipment slots simulate inventory. One adventurer simulates future classes. Local split-screen simulates multiplayer architecture before online networking.

### Pillar 3 — Build for Expansion, Not Final Complexity

Systems should be structured so they can grow, but they should not be overbuilt. The prototype should create clean seams, not giant final systems.

### Pillar 4 — Make the First Dungeon Fun

The prototype succeeds only if moving, fighting, looting, and surviving are enjoyable. Architecture is important, but the game must not become a spreadsheet wearing a helmet.

## 4. Prototype Scope Summary

### Included in Prototype

- First-person player controller
- Single-player mode
- Local split-screen couch co-op mode
- Player slot architecture
- Per-player input
- Per-player camera/viewport
- Per-player HUD
- TrenchBroom room import/pipeline validation
- Four to five manually connected rooms
- Basic room markers/spawn points
- Basic melee combat
- Basic enemy AI
- Health/damage/death
- Simple equipment system
- Weapon pickup
- Armor pickup
- Consumable pickup
- Basic interaction prompts
- Chest or loot pickup object
- Exit room / run completion trigger

### Excluded from Prototype

- Procedural dungeon generation
- Online multiplayer
- Dedicated servers
- Matchmaking
- Full class system
- Full backpack inventory
- Vendor/shop economy
- Crafting
- Full magic system
- Large enemy roster
- Full roguelite meta progression
- Save/load system
- Complex quest/narrative systems
- Large-scale content production

## 5. Play Modes in Prototype

The main menu should expose separate play mode buttons so the game session can bootstrap correctly.

Prototype menu options:

- Single Player
- Couch Co-op
- Online Multiplayer placeholder / disabled / future button

The selected mode creates a session configuration used by the dungeon run scene.

### Session Config Concept

The prototype should introduce a `GameSessionConfig` or equivalent data object.

It should contain:

- Play mode
- Local player count
- Max player count
- Selected dungeon scene
- Optional future seed value
- Optional future character selections

Example play modes:

- `SINGLE_PLAYER`
- `LOCAL_COOP`
- `ONLINE_HOST` — future
- `ONLINE_CLIENT` — future

## 6. Player Slot Architecture

The prototype should not assume there is only one player.

Every active player should be represented by a player slot.

A player slot may own:

- Player actor
- Input device/controller mapping
- Camera rig
- Viewport
- HUD
- Equipment state
- Interaction raycast/prompt state

Single-player mode creates one local player slot.

Couch co-op mode creates two local player slots initially. The architecture should allow expansion to four local player slots later, but the prototype only needs to prove one and two players.

### Local Player Slot Responsibilities

Each local player slot should:

- Spawn a player actor
- Assign input
- Create or bind a camera
- Assign camera to the correct viewport
- Bind HUD to that player actor
- Handle per-player interaction prompts

## 7. Split-Screen Direction

Local co-op requires split-screen because Project Blackspire is first-person.

Prototype split-screen requirement:

- 1 player: one full-screen viewport
- 2 players: two split-screen viewports

Preferred initial layout:

- Horizontal split or vertical split may be tested
- Choose whichever feels better for first-person dungeon visibility

Future support:

- 3-player split-screen
- 4-player quadrant split

These do not need to be implemented in the initial prototype unless the two-player structure makes it cheap.

## 8. Player Controller Scope

The prototype player controller should support:

- First-person movement
- Mouse/controller look
- Jump optional, depending on dungeon geometry
- Crouch optional, likely deferred
- Interact
- Basic attack
- Use consumable
- Equip or pick up item

The controller should be cleanly separated from the player actor.

Preferred structure:

- PlayerController reads input
- PlayerActor owns movement/combat/equipment components
- PlayerCameraRig owns camera behavior
- PlayerHUD listens to player actor state

## 9. Prototype Adventurer

The prototype uses one character type: the Adventurer.

The Adventurer is a flexible fighter-style character used to prove the full gameplay loop.

Prototype Adventurer abilities:

- Move
- Attack with equipped weapon
- Take damage
- Equip weapon/armor
- Use potion
- Interact with doors/chests/items

The Adventurer temporarily represents all future classes.

Future classes such as Fighter, Rogue, and Ranger should not be implemented until the core loop is proven.

## 10. Combat Scope

Prototype combat should be simple, readable, and expandable.

Initial combat features:

- One melee attack
- Attack cooldown
- Hit detection
- Damage event
- Enemy hurt reaction optional
- Enemy death
- Player damage/death

Preferred combat pipeline:

1. Player attacks.
2. Weapon hitbox checks for valid targets.
3. Hit creates a damage request.
4. Target health component receives damage.
5. Health component emits damage/death events.
6. UI/audio/VFX respond to events.

### Deferred Combat Features

- Combos
- Heavy attacks
- Blocking
- Dodging
- Stamina
- Backstabs
- Parry
- Elemental damage
- Status effects
- Advanced weapon movesets

These may be added after the core combat loop works.

## 11. Enemy Scope

The prototype should include one primary enemy type.

Initial enemy:

- Skeleton or goblin-style melee enemy

Enemy behavior:

- Idle/patrol optional
- Detect player
- Chase nearest/valid player
- Attack in range
- Take damage
- Die

The enemy should work against one or two local players.

Targeting should use a player list, not a hardcoded player reference.

### Optional Second Enemy

A second enemy may be added only if the first enemy is stable.

Possible second enemy:

- Fast weak spider/rat
- Basic ranged cultist/goblin archer

This is optional and should not block the prototype.

## 12. Health, Damage, and Death

Health should be component-based and shared by players and enemies where practical.

Core features:

- Max health
- Current health
- Apply damage
- Is alive check
- Death signal/event

Prototype player death options:

- Immediate respawn at room start
- Downed/revive system
- Run failure when all players are dead

Recommended first implementation:

- Player reaches 0 HP and enters a downed or disabled state.
- If all players are down/dead, reset the dungeon or show prototype game-over.

A full revive system can be added after basic death state works.

## 13. Stats Scope

The prototype should use a small stat set.

Initial stats:

- Max Health
- Move Speed
- Attack Damage
- Armor / Damage Reduction
- Attack Cooldown or Attack Speed

Stats should support:

- Base value
- Equipment modifiers

Temporary buffs, status effects, and complex formulas are deferred.

## 14. Equipment and Item Scope

The prototype should prove that loot can change player performance without building a full inventory system.

Initial equipment slots:

- Weapon
- Armor
- Consumable

Optional slot:

- Trinket

Initial item types:

- Basic sword or axe
- Better sword or axe
- Basic armor
- Health potion

Items should be data-driven with item definition resources.

### Item Definition Concept

An item definition should include:

- Item ID
- Display name
- Item type
- Equip slot
- Stat modifiers
- Optional icon
- Optional world pickup scene/model

### Pickup Behavior

Initial pickup behavior may be simplified:

- Player looks at item.
- Player presses interact.
- Item is equipped directly if it fits a slot.
- Existing equipped item may be replaced or dropped later.

A full backpack inventory is intentionally deferred.

## 15. Interaction System

The prototype needs a reusable interaction system.

Interactable objects may include:

- Item pickups
- Chests
- Doors
- Exit trigger

Each local player should have their own interaction raycast and prompt.

Recommended interface-style behavior:

- `can_interact(actor)`
- `interact(actor)`
- `get_prompt(actor)`

The player controller should not contain custom logic for every interactable object.

## 16. Rooms and Dungeon Flow

The prototype should use manually connected rooms to simulate procedural dungeon flow.

Prototype room count:

- 4 to 5 rooms

Suggested room set:

1. Entrance / spawn room
2. Small combat room
3. Treasure or side room
4. Larger combat room
5. Exit or boss-lite room

Rooms should be authored in TrenchBroom or the chosen dungeon room workflow.

### Room Metadata

Even manually connected rooms should use metadata/markers so future procedural generation can use the same structure.

Room markers may include:

- Player spawn points
- Enemy spawn points
- Loot spawn points
- Chest points
- Door sockets
- Room bounds/trigger area
- Exit marker

The prototype should not generate the dungeon procedurally. It should prove that authored rooms can carry gameplay.

## 17. TrenchBroom Pipeline Requirements

The prototype must prove the TrenchBroom-to-Godot pipeline early.

Pipeline validation checklist:

- Correct scale
- Correct collision
- Correct player height and door height
- Correct lighting workflow
- Correct material assignment
- Correct spawn marker/import strategy
- Correct room bounds strategy
- Good enough performance in split-screen

The prototype should establish a repeatable workflow for making rooms, importing them, and attaching gameplay markers.

## 18. UI/HUD Scope

UI must be per-player for split-screen.

Initial per-player HUD elements:

- Health
- Current weapon
- Consumable count or icon
- Interaction prompt
- Damage feedback optional

Global UI elements:

- Pause menu
- Prototype restart button
- Run complete / game over message

The HUD should bind to a specific player slot or actor.

The UI should not assume Player 1 is the only meaningful player.

## 19. Audio and Feedback Scope

Initial audio/feedback should be simple but present.

Needed feedback:

- Player attack sound
- Enemy hit sound
- Player hurt sound
- Enemy death sound
- Item pickup sound
- Door/chest interaction sound

Visual feedback:

- Hit flash or reaction
- Basic enemy death effect
- Pickup highlight
- Interaction prompt

Advanced positional audio for split-screen is deferred.

## 20. Prototype Architecture Targets

The prototype should establish clean foundations for:

- Session mode selection
- Player slots
- Input assignment
- Split-screen viewports
- Player actors
- Actor components
- Health/damage
- Equipment/stat modifiers
- Interactions
- Room markers
- Enemy targeting across multiple players

The prototype should avoid hardcoding global references to a single player whenever possible.

## 21. Online Multiplayer Preparation

Online multiplayer is not implemented in the prototype, but the architecture should avoid obvious blockers.

Online-friendly habits:

- Use player slots.
- Use explicit damage requests/events.
- Use explicit item pickup/equip events.
- Keep enemy targeting based on active player list.
- Keep room state explicit.
- Avoid direct singleton assumptions like `the_player`.
- Keep dungeon flow controlled by a session/run manager.

Future online model:

- Host authoritative
- Host resolves enemy AI, damage, loot, and room state
- Clients send inputs/actions
- Clients receive replicated results

## 22. Prototype Milestones

### M0 — First-Person Dungeon Room

Goal: prove basic dungeon movement and combat.

Build:

- One TrenchBroom room imported into Godot
- One local player
- First-person movement/look
- One melee attack
- One enemy dummy or skeleton
- Health/damage/death
- Basic HUD
- Restart/reset shortcut

Definition of done:

- Player can move around a dungeon room.
- Player can attack and kill an enemy.
- Enemy can damage player.
- Combat loop is testable.

### M1 — Player Slot and Split-Screen Foundation

Goal: prove local co-op architecture.

Build:

- Session config for single-player/couch co-op
- PlayerSlot structure
- Two local players
- Two inputs
- Two cameras/viewports
- Two HUDs
- Enemy can target either player

Definition of done:

- Two players can spawn in the same room.
- Both players can move/look/attack independently.
- Both players have separate cameras and HUDs.
- Enemy can engage either player.

### M2 — Manual Dungeon Chain

Goal: simulate dungeon progression without procedural generation.

Build:

- Four to five connected rooms
- Player spawn room
- Combat rooms
- Treasure room
- Exit room
- Room markers
- Door/transition logic
- Basic room clear state

Definition of done:

- Players can move through a small dungeon chain.
- Enemies/loot can be placed through markers.
- Exit room completes the run.

### M3 — Equipment and Loot Slice

Goal: prove loot changes player performance.

Build:

- ItemDefinition resources
- ItemPickup interactable
- Weapon slot
- Armor slot
- Consumable slot
- Stat modifiers from equipment
- Pickup/equip feedback

Definition of done:

- Player can pick up and equip a weapon.
- Equipped weapon changes attack damage.
- Player can pick up armor and reduce incoming damage.
- Player can use a potion or consumable.

### M4 — Prototype Dungeon Run

Goal: combine systems into a small playable run.

Build:

- Full manual dungeon path
- Multiple enemy placements
- Chest/loot placement
- Exit condition
- Failure/reset condition
- Basic run-complete screen/message

Definition of done:

- One or two players can start a run, clear rooms, collect loot, and reach the exit.
- The prototype can be handed to a friend for basic playtesting.

### M5 — Architecture Review for Online

Goal: identify and fix blockers before network work.

Review:

- Are player slots clean?
- Are local players separated from actors?
- Are damage events explicit?
- Are pickup/equip events explicit?
- Are enemies using a player registry?
- Is room state controlled centrally?
- Is UI per-player?

Definition of done:

- Major systems are organized well enough to attempt a host/client networking prototype later.

## 23. Testing Priorities

### Feel Tests

- Does first-person movement feel good in tight rooms?
- Is combat readable?
- Are enemies too fast, too slow, or too sticky?
- Do weapons feel like they connect?
- Does split-screen make the game hard to read?

### Co-op Tests

- Can two players fight in the same room without constant body-blocking?
- Can each player see their own prompt/HUD?
- Can enemies target both players?
- Does player death/reset work?

### Room Tests

- Are rooms too cramped for two first-person players?
- Are doors/hallways wide enough?
- Is enemy pathing reliable?
- Do spawn points work?
- Is lighting readable in split-screen?

### Loot Tests

- Is pickup/equip obvious?
- Does gear change feel meaningful?
- Is loot ownership understandable?
- Does one player stealing all loot become funny or annoying?

## 24. Prototype Content Targets

### Rooms

- Entrance room
- Small combat room
- Treasure/chest room
- Large combat room
- Exit or boss-lite room

### Enemies

- One melee enemy required
- One optional secondary enemy

### Items

- Weak weapon
- Stronger weapon
- Armor
- Health potion
- Optional trinket

### Interactables

- Door
- Chest
- Pickup item
- Exit trigger

## 25. Open Design Questions

These questions do not need final answers immediately, but should be tested during the prototype.

- Should local players collide with each other or softly pass through?
- Should loot be shared, individual, or first-come-first-served?
- Should player death be downed/revive, respawn, or run failure?
- Should combat include blocking early, or only attack/dodge later?
- Should the camera split be horizontal or vertical for two players?
- How wide do hallways need to be for comfortable co-op?
- Is first-person melee fun enough, or does ranged combat need to appear early?

## 26. Recommended Early Defaults

Until testing proves otherwise:

- Use two-player split-screen as the first co-op target.
- Let players softly pass through or lightly push each other rather than hard-blocking doorways.
- Use first-come-first-served loot for early prototype simplicity.
- Use simple equip-on-pickup before full inventory.
- Use one melee enemy first.
- Use manual room connections before procedural generation.
- Use one Adventurer character before classes.
- Use basic death/reset before full revive mechanics.

## 27. Prototype Success Criteria

The prototype succeeds when:

- One player can complete a small dungeon run.
- Two local players can complete the same run in split-screen.
- Combat is understandable and has the seed of fun.
- Loot can be picked up and equipped.
- Gear changes matter.
- Rooms can be authored, imported, connected, and played.
- The architecture does not assume only one player.
- The next step toward online multiplayer is technically plausible.

## 28. Prototype Failure Warnings

The prototype is drifting if development gets stuck on:

- Full inventory UI too early
- Too many classes
- Too many enemies
- Procedural generation before manual rooms are fun
- Online networking before local co-op works
- Complex RPG stats before basic combat feels good
- Visual polish before room scale/combat/readability are proven
- Large lore/narrative work before the playable loop exists

If any of these happen, cut scope and return to the smallest playable dungeon loop.

## 29. Immediate Next Build Target

The first implementation target is:

# M0 — First-Person Dungeon Room

Build the smallest combat test possible:

- One imported dungeon room
- One player
- One enemy
- One attack
- Health/damage/death
- Basic HUD
- Reset shortcut

This milestone should answer the first major question:

> Is first-person dungeon combat inside a Project Blackspire room worth building on?

If yes, move immediately into player slot and split-screen architecture.

