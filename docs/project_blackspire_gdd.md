# Project Blackspire — Game Design Document

## 1. High-Level Pitch

**Project Blackspire** is a first-person cooperative dungeon-crawling roguelite where players descend into dangerous, modular fantasy dungeons, battle monsters, collect loot, equip gear, and push deeper toward the mysteries of the Blackspire.

The game blends the immediacy of first-person action, the social chaos of couch co-op dungeon crawling, and the long-term replayability of roguelite runs. Players begin as classic adventuring archetypes — fighter, rogue, ranger, and eventually additional fantasy roles — but the final game should favor flexible character growth, loot-driven builds, and emergent party strategies over strict tabletop rules.

The goal is to create a game that feels like a chunky retro fantasy dungeon crawler brought forward with modern co-op systems, satisfying combat, readable loot, and replayable dungeon runs.

## 2. Core Fantasy

Players are adventurers entering the shadowed halls, crypts, ruins, and underworld chambers surrounding the Blackspire — a cursed, ancient structure that rises above a dangerous frontier and extends deep below the earth.

The player fantasy is:

- Explore dangerous fantasy dungeons with friends.
- Fight monsters in close, first-person combat.
- Find loot that immediately changes how a character plays.
- Build a character through equipment, use-based skill growth, and run-based choices.
- Survive increasingly dangerous dungeon floors.
- Create memorable co-op moments: clutch revives, greedy loot grabs, terrible hallway decisions, and heroic last stands.

The game should feel adventurous, slightly dangerous, readable, tactile, and a little chaotic in the best couch co-op way.

## 3. Target Experience

Project Blackspire should feel like:

- A retro dungeon crawler with modern controls.
- A fantasy co-op action game that is easy to understand but has room for mastery.
- A roguelite where short runs generate stories.
- A loot game where equipment changes matter immediately.
- A game that supports both casual local play and deeper online testing/play with friends.

The player should be able to sit down, start a run, pick up a weapon, fight a skeleton, open a chest, argue over loot, survive a boss, and say, “One more run.”

## 4. Intended Platforms

Initial development target:

- PC
- Godot Engine
- Keyboard/mouse and controller support

Long-term preferred play modes:

- Single-player
- Local split-screen couch co-op
- Online co-op host/client multiplayer

Online multiplayer is part of the long-term game intention, but local co-op is treated as the first multiplayer foundation because it proves multi-player-slot architecture, split-screen cameras, per-player input, per-player UI, and co-op combat without immediately requiring network synchronization.

## 5. Visual Direction

Project Blackspire uses a retro-inspired, modular dungeon aesthetic built around authored room pieces and strong lighting composition.

Visual priorities:

- Chunky readable geometry
- Low-to-mid detail fantasy props
- Strong color/value control
- Torchlight, shadow, fog, and contrast
- Modular rooms authored in TrenchBroom or a similar room-building pipeline
- Stylized rather than realistic materials
- Distinct dungeon themes through palette, lighting, props, and enemy sets

The game should look intentionally designed rather than asset-dumped. The style should support solo development by leaning on simple shapes, strong composition, controlled color, and repeatable modular environment pieces.

## 6. Tone and Setting

The tone is dark fantasy adventure, but not grim misery.

Project Blackspire should support:

- Ancient ruins
- Crypts and catacombs
- Goblin warrens
- Abandoned keeps
- Arcane laboratories
- Cursed temples
- Underdark-style caverns
- Weird magical artifacts

The world should feel dangerous and mysterious, but still gamey and fun. It should not become lore-heavy before the gameplay is strong.

The Blackspire itself is the central mythic anchor: a cursed tower, fortress, dungeon-mouth, or magical scar on the world that justifies endless dangerous expeditions.

## 7. Gameplay Pillars

### Pillar 1 — Co-op Dungeon Chaos

The game should create fun party moments. Players should be able to fight side-by-side, split briefly to grab loot, revive each other, panic in tight corridors, and make questionable decisions together.

### Pillar 2 — Readable First-Person Combat

Combat should be physical, readable, and satisfying. The player should understand when they hit, when they are hit, when they blocked, when they dodged, and when an enemy is vulnerable.

### Pillar 3 — Loot That Changes Play

Gear should not be boring number confetti. Even simple gear should change the way a character feels: faster attacks, longer reach, more armor, elemental effects, crit bonuses, stamina changes, defensive options, or special triggers.

### Pillar 4 — Modular Replayable Dungeons

Dungeons should be assembled from authored rooms, not fully random noise. The final game should use procedural room selection and connection, but the content itself should be handcrafted enough to look and play well.

### Pillar 5 — Flexible Adventurer Growth

The game should support classic class fantasy without overcommitting to rigid tabletop rules. Characters may begin from archetypes, but growth can be influenced by gear, use-based progression, and run choices.

## 8. Player Archetypes

Long-term archetypes may include:

### Fighter

Durable front-line combatant. Strong with swords, axes, shields, armor, and stagger-based play.

### Rogue

Fast, evasive, crit-focused adventurer. Good with daggers, light armor, traps, backstabs, lockpicking, and opportunistic combat.

### Ranger

Ranged and mobile combatant. Uses bows, light melee weapons, traps, and positioning.

### Acolyte / Mage / Mystic — Future Consideration

A magic-oriented class may be added later, but magic should be deferred until the core combat, loot, multiplayer, and dungeon systems are stable.

## 9. Character Progression Direction

The preferred long-term direction is a hybrid model:

- Archetypes provide starting identity.
- Equipment shapes moment-to-moment gameplay.
- Skills improve based on use or run choices.
- Permanent progression may unlock options, not raw overwhelming power.

The game should avoid recreating a full D&D or Pathfinder ruleset. It should borrow the fantasy, roles, terminology inspiration, and adventuring feel, while using simplified action-game math.

## 10. Core Gameplay Loop

### Run Loop

1. Choose play mode.
2. Choose character or adventurer loadout.
3. Enter dungeon.
4. Explore rooms.
5. Fight monsters.
6. Find loot and resources.
7. Equip or use items.
8. Survive room events, traps, and bosses.
9. Descend deeper, extract, or die.
10. Gain unlocks/progression.
11. Start another run.

### Moment-to-Moment Loop

1. Move through dungeon.
2. Spot enemy or point of interest.
3. Fight, dodge, block, shoot, or interact.
4. Loot rewards.
5. Adjust equipment.
6. Choose next room/path.

## 11. Combat Direction

Combat should start simple and become deeper through weapons, enemy variety, and co-op interactions.

Possible combat actions:

- Light attack
- Heavy attack
- Block
- Dodge
- Bow shot
- Use item
- Interact
- Revive ally
- Class/action ability later

Combat should emphasize:

- Clear hit feedback
- Manageable stamina or cooldown pressure
- Distinct weapon feel
- Enemy tells
- Positioning
- Team survival

## 12. Loot and Equipment Direction

The final game should include:

- Weapons
- Armor
- Trinkets/rings
- Consumables
- Possibly offhand items
- Possibly class tools

Paper-doll direction:

- Weapon
- Offhand or shield
- Armor
- Trinket 1
- Trinket 2
- Consumable slots

Inventory should begin simple and only grow if it serves the gameplay. A full backpack/grid inventory is not mandatory for the earliest versions and should be treated as a major system, not a small UI task.

## 13. Dungeon Structure Direction

Dungeons should be built from modular authored rooms.

Each room should support metadata such as:

- Door sockets
- Spawn points
- Loot points
- Room type
- Difficulty rating
- Theme tag
- Bounds
- Encounter rules

Long-term dungeon types:

- Linear runs
- Branching paths
- Treasure side rooms
- Trap rooms
- Elite combat rooms
- Boss rooms
- Shops or safe rooms
- Secret rooms

The prototype should manually connect rooms first, simulating procedural generation before implementing the generator.

## 14. Multiplayer Direction

Project Blackspire is intended to support:

- Single-player
- Split-screen couch co-op
- Online co-op

The game should be architected around player slots instead of assuming a single player.

Each player slot may own:

- Actor
- Input controller
- Camera rig
- Viewport
- HUD
- Equipment/inventory state

Local couch co-op should use split-screen viewports.

Online multiplayer should eventually use a host-authoritative model:

- Host owns dungeon state.
- Host owns enemy AI.
- Host resolves damage and loot.
- Clients send inputs/actions.
- Clients receive synchronized world state.

Dedicated servers, matchmaking, and large-scale networking are not part of the initial target.

## 15. Content Scope Vision

Long-term content may include:

- Multiple dungeon themes
- Several enemy factions
- Boss encounters
- Class archetypes
- Weapon families
- Gear rarity tiers
- Consumables
- Shrines/events
- Meta unlocks
- Difficulty escalation
- Procedural room chains

Content should only scale after the core loop is fun.

## 16. Development Philosophy

Project Blackspire should be built through vertical slices.

The correct strategy is:

1. Prove the feel.
2. Prove co-op structure.
3. Prove loot/equipment.
4. Prove dungeon room flow.
5. Prove replayable runs.
6. Prove online multiplayer.
7. Then expand content.

The project should avoid building large amounts of content before the core systems feel good.

## 17. Explicit Non-Goals for Early Development

The following are not early goals:

- Full class roster
- Complex tabletop rules
- Large inventory grid
- Vendors/economy
- Crafting
- Large procedural dungeon generator
- Magic system
- Advanced skill trees
- Dedicated servers
- Matchmaking
- Large narrative campaign
- Save/load complexity

These systems may be revisited later, but they should not block the first playable slices.

## 18. Success Vision

The end product succeeds if players can:

- Jump into a dungeon quickly.
- Fight monsters with satisfying first-person action.
- Play with friends locally or online.
- Find loot that changes their build.
- Experience varied dungeon runs.
- Enjoy strong retro-fantasy atmosphere.
- Want to run the dungeon again.

Project Blackspire should feel like a dangerous little dungeon machine: easy to enter, fun to survive, and full of opportunities for co-op nonsense, loot greed, and heroic stupidity.

