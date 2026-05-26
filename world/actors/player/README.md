# Player Controller

This is the basic first-person player controller for Blackspire.

## Current State (Early Prototype)
- CharacterBody3D based movement
- Mouse look with captured cursor
- Walk / Sprint
- Basic jumping
- Camera at ~1.65m eye height

## Controls (Default)
- WASD / Arrow keys: Move
- Shift: Sprint (if "sprint" action is bound)
- Space: Jump (if "jump" action is bound)
- Escape: Toggle mouse capture

## Next Steps
- Hook up proper input actions in Project Settings
- Replace temporary placement with spawning from `info_player_start` Marker3D
- Add crouching, interaction, weapon bob, etc. later
- Consider separating input reading from movement logic when we support multiple players / local co-op

## Temporary Testing
The player is currently manually placed in `test_room_01.tscn` for fast iteration.
