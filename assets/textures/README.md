# Blackspire Textures

Place your level textures here (PNG recommended for starters).

FuncGodot (via the current map settings) will look in `res://assets/textures` for textures matching the names used on brushes in TrenchBroom.

## Naming conventions (recommended)
- albedo / base color: `stone_floor.png` or `stone_floor_albedo.png`
- The map settings currently excludes common PBR suffixes from TrenchBroom display.

## Special textures (required for pipeline)
- `clip.png`   → removes faces from visual mesh but keeps collision
- `skip.png`   → completely removes faces (visual + collision)
- `origin.png` → used to define the origin of brush entities

You can copy the dev versions from:
`res://addons/func_godot/textures/clip.png`
`res://addons/func_godot/textures/skip.png`
`res://addons/func_godot/textures/origin.png`

## For M0 / first test
You can build a room using any textures. If none exist yet, FuncGodot will fall back to the default material from the addon.
