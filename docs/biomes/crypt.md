# Biome: Crypt (Catacombs / Burial Chambers)

## Overview
The first major biome for testing and early development.

**Tone**: Dark, ancient, oppressive, but still readable. Heavy use of contrast through lighting.

**Role in the game**: Early-game area. Feels dangerous and claustrophobic. Good for teaching the player that the dungeon is hostile and the architecture itself can be threatening.

## Core Material Language

**Primary**:
- Worked stone (blocks, bricks, carved walls)
- Variations in age and condition (cleaner stone vs cracked/weathered)

**Secondary**:
- Moss / lichen growth (especially in damper areas)
- Dirt and dust accumulation
- Occasional wooden structural elements (beams, posts, scaffolding)

**Accents**:
- Bone and skull details
- Rusted iron (grates, chains, brackets)
- Faded carvings / reliefs

**Color Palette Direction**:
- Dominated by cool and neutral greys
- Subtle desaturated browns and greens from age/moss
- Strong warm accents from torchlight

## Lighting Language

This biome should be one of the best places to showcase the game's lighting.

- **Primary light source**: Torches (wall-mounted and freestanding)
- **Secondary**: Occasional braziers or hanging lanterns
- **Ambient**: Very low. Most areas should feel genuinely dark when torches are not nearby.
- **Contrast**: High. Bright torchlight pools against deep shadow.
- **Fog / Atmosphere**: Light dust or thin fog in larger chambers can help sell depth.

**Design goal**: Players should feel the need to stay near light sources.

## Architectural / Modular Goals

We are standardizing on a **64-unit module** (2.0m).

**Typical heights for this biome**:
- Standard rooms & hallways: **64 units**
- Tight/oppressive passages: **48 units**
- More important chambers: **80 units** (occasional)

**Modular pieces to prioritize** (in rough order):

### Tier 1 (Core kit - needed early)
- Straight wall segments (various lengths in 16-unit increments)
- Corner pieces (inside and outside)
- Door frames (48 high x 32 wide as starting size)
- Floor tiles / panels
- Ceiling pieces
- Simple pillars / columns

### Tier 2 (Gameplay & variation)
- Archways
- Niches / alcoves (for urns, statues, torches)
- Raised platforms / steps (16-unit increments)
- Rubble / damaged wall sections
- Wooden support beams / posts

### Tier 3 (Props & Interactables)
- Breakable urns / pots
- Coffins (some openable, some breakable)
- Levers / switches
- Wall torches (static + possibly dynamic lighting versions)
- Floor torches / braziers
- Bone piles, skulls, chains

## Texture Strategy (Current)

- **Base texture size**: 64×64 (with 128×128 and 64×128 variants as needed)
- **Texel density target**: Keep relatively consistent with our 64-unit module
- **Variation method**: Multiple stone variants + overlays (moss, dirt, cracks) rather than many unique high-res textures early on

**Current thinking**:
- Main wall and floor textures can be 64×64
- Wall sections that need vertical detail (wainscoting, carved bands) may use 64×128 or 128×256 textures
- Props can use smaller or non-square textures as needed

## Enemy Fit

**Primary early enemy**: Skeleton
- Melee variant (sword, axe, etc.)
- Ranged variant (bow or thrown bones)

Skeletons work extremely well in this environment both thematically and for gameplay (they can emerge from alcoves, coffins, bone piles, etc.).

## Open Questions / Future Expansion

- How much "worked stone" vs "carved tomb" do we want? (plain bricks vs ornate reliefs)
- Do we want any areas with more natural cave elements breaking into the crypt?
- How much wood do we actually want to use? (structural only, or more decorative?)

## Current Status

- First test room is using placeholder brick textures
- Player controller is at 1.45 capsule / 1.30 camera (tuned for 64-unit rooms)
- We are moving toward 64 units as the standard room/hallway height for this biome

---

**Next Steps** (suggested):
1. Define a small starter modular kit list with specific dimensions
2. Create a first pass of crypt-appropriate textures (stone variants + wood)
3. Block out a small multi-room crypt section at 64-unit scale
4. Test lighting + contrast in the new geometry
