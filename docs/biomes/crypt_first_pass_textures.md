# Crypt Biome - First Pass Textures

**Goal**: Keep the first crypt test area extremely simple and flat while still looking like a believable crypt.

## Philosophy for This Pass
- Super simple, flat geometry only.
- No stairs or complex verticality yet (those come later when we refine stair stepping and player controller feel).
- Focus on readability and atmosphere over detail.
- Use a small, manageable texture set.

## Required Textures (First Pass)

### Walls
- **Brick Wall A** (main wall texture)
- **Brick Wall B** (variation — slight weathering, different brick layout, or subtle damage)
- **Tomb Wall (Single)** — Wall with one tomb/niche detail
- **Tomb Wall (Double)** — Wall with two stacked tombs/niches

### Floors
- **Concrete / Stone Floor** — Simple, slightly worn concrete or flat stone floor. Should read as "worked stone" rather than rough cave.

### Pillars / Columns
- **Pillar Texture A**
- **Pillar Texture B** (variation — different stone, slight weathering, or carved detail)

### Wooden Elements
- **Wooden Support Beam** — Rough wooden beams/posts used for structural support or decoration.

## Texture Specifications (Current Standard)

- **Base resolution**: 64×64 (we can go up to 128×128 for hero pieces later if needed)
- **Format**: PNG
- **Style**: Chunky / low-detail. Readable from first-person at typical distances.
- **Color**: Mostly cool/neutral greys. Some subtle variation and weathering allowed.

## Usage Notes

- Keep most surfaces using the main brick textures.
- Use the Tomb Wall variants sparingly for visual interest and to sell the "this is a burial place" feeling.
- Wooden beams should feel like later additions (reinforcements) rather than original construction.
- The concrete floor should feel old and slightly dirty, but still clearly man-made.

## Stretch Goals (Only if easy)

- A very simple "damaged" or "cracked" brick variation (can be the same texture with different UVs or a subtle overlay).
- A dirtier version of the floor for corners and low-traffic areas.

## What We Are NOT Doing Yet

- No fancy carved reliefs or highly detailed stonework.
- No complex trim pieces.
- No mossy or overgrown versions (we can add these later for variation).
- No stairs or sloped surfaces.

## Suggested Naming Convention

```
crypt_wall_brick_a_64.png
crypt_wall_brick_b_64.png
crypt_wall_tomb_single_64.png
crypt_wall_tomb_double_64.png
crypt_floor_concrete_64.png
crypt_pillar_a_64.png
crypt_pillar_b_64.png
crypt_wood_beam_64.png
```

## Next Steps

1. Author the textures listed above at 64×64.
2. Set up basic materials in Godot (mostly just albedo + slight roughness variation for now).
3. Block out a small section of crypt in TrenchBroom using the 64-unit module.
4. Apply textures and do a first lighting pass with torches.
5. Playtest and feel how the space works with the current player controller.

Once this first flat pass feels good, we can start talking about adding stair sets, more complex geometry, and additional texture variation.
