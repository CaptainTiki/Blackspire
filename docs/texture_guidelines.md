# Blackspire Texture & UV Guidelines

## Core Standards (Locked In)

- **Scale**: 32 (32 TrenchBroom units = 1 Godot meter)
- **Standard Room Height**: **64 units** (2.0 meters)
- **Base Texture Size**: **64×64** (power of 2)
- **Player Capsule Height**: **1.45**
- **Player Camera (Eye) Height**: **1.30**

### Modular Grid
We use **64 units** as our primary module, broken into **16-unit increments** (¼ of 64):

- 16, 32, 48, 64 (1×), 80 (1.25×), 96 (1.5×), 112, 128 (2×), etc.

This system keeps layout math simple while still allowing variation (e.g. 1.5× or 2× rooms for more important spaces).

### Player Proportions
- Total height: 1.45
- Eye level: 1.30
- These values were tested and locked after validating against 64-unit rooms.

## Rationale

- Keeps all dimensions and textures on clean **power-of-2** numbers.
- Much easier texture authoring, tiling, and asset pipeline.
- Easy to find and reuse existing texture assets.
- 64-unit rooms feel appropriately tense and dangerous for a dungeon crawler without the player feeling oversized.

## Texture Size Recommendations (Updated)

We like the chunky pixel look of **64x64** textures, but they cause repetition problems on 80-unit walls (1.25 vertical repeats).

### Recommended Authoring Sizes

| Surface Type       | Recommended Resolution | Notes |
|--------------------|------------------------|-------|
| Floors             | 64x64 or 128x128      | Easy to tile |
| Main Wall Faces    | **64x128** or **128x256** | Taller aspect ratio so one vertical tile mostly covers an 80-unit wall |
| Wainscot / Borders | 64x32 or 64x64        | Apply only to lower wall section with separate UVs |
| Trim & Details     | 32x32 or 64x64        | Small pieces |
| Hero / Unique      | 256x256 or larger     | Rare focal pieces |

**Practical rule for now:**
- Main wall texture → Make it **taller** (64 high x 128 wide, or 128x256) so it covers most of an 80-unit wall in one vertical repeat.
- Use a separate small texture/material just for the bottom 16–24 units as wainscot.

This gives you clean borders without the pattern repeating up near the ceiling.

## UV Scaling in TrenchBroom

- Try to keep most faces on **consistent texture scale** across a room.
- Use the Face Inspector to adjust per-face scale when needed (especially for borders).
- For the current 80-unit walls with 64px-tall textures, you will likely need to manually scale the UVs on the main wall faces so the texture doesn't repeat awkwardly.

## Future Direction

Once we're happy with the look, we can decide on a firmer texel density target (e.g. "all standard walls should be authored so a 128px tile covers X units").

For now, prioritize:
- Good readability
- Minimal ugly repetition on walls
- Easy to author

## Next Actions

- Update the test room with 80-unit ceilings (done).
- Create a few 64x128 wall textures + matching 64x32 wainscot textures.
- Apply them with custom UVs in TrenchBroom.
- Import and evaluate.
