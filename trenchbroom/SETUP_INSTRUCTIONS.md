# Blackspire TrenchBroom + FuncGodot Pipeline Setup

## Goal for this phase
Get the level art pipeline working so we can author rooms in TrenchBroom and import them cleanly into Godot for the M0 milestone (single room, player, one enemy).

## What I've pre-created (Godot side)
- `blackspire_map_settings.tres` — Project map build settings (scale 32, points at assets/textures, uses base FGD for now).
- `blackspire.fgd.tres` — Our future extended FGD (currently empty, inherits everything from func_godot base).
- `blackspire_game_config.tres` — The resource we'll use to export the TrenchBroom game definition.
- `test_room_01.tscn` — A starter wrapper scene under `world/rooms/test/`.
- `assets/textures/README.md` — Where your level textures should live.

## Step-by-step setup (do this now)

### 1. Configure FuncGodot Local Settings
1. In Godot, open `addons/func_godot/func_godot_local_config.tres` (double click it).
2. In the inspector, set **TrenchBroom Game Config Folder** to a path on your machine.
   Recommended:
   - `D:/TrenchBroom/games/Blackspire/`   (clean, outside the repo)
   - or `D:/Godot/REPOs/Blackspire/trenchbroom/exported/` (everything in one place)
3. Create that folder on disk first if it doesn't exist.
4. Click the **"Export func_godot settings"** button at the top of the inspector.
   (This saves to user:// JSON — the .tres file itself is mostly a template.)

### 2. Export the Blackspire Game Config for TrenchBroom
1. Open `trenchbroom/blackspire_game_config.tres` in the inspector.
2. (Optional but nice) Change the icon if you want.
3. Click the big **"Export GameConfig"** button.
4. It should write:
   - `GameConfig.cfg`
   - `Blackspire.fgd` (from the base for now)
   - `icon.png`
   into the folder you set in step 1.

### 3. Add "Blackspire" as a Game in TrenchBroom
1. Open TrenchBroom.
2. Go to **Edit → Preferences → Games**.
3. Click **Add** or the + button.
4. Point it at the folder you exported to in step 1 (the one containing `GameConfig.cfg`).
5. Name it "Blackspire".
6. Restart TrenchBroom or create a new map using the Blackspire game.

### 4. First Test Map (do this in TrenchBroom)
Create a dead simple room:
- One or two brushes for floor + walls (use Valve format or Standard).
- Give the room some height so a player fits comfortably.
- Optional: Create an `origin` brush or just note a good player spawn location.
- Save it as `maps/test_room_01.map` (or anywhere).

For the absolute first test you don't even need custom entities yet — just structural brushes.

### 5. Import into Godot
1. Open `world/rooms/test/test_room_01.tscn`.
2. Select the `FuncGodotMap` child node.
3. Set **Map File** to the path of your exported .map (relative to the scene or absolute during testing).
4. Make sure **Map Settings** points to `res://trenchbroom/blackspire_map_settings.tres`.
5. In the inspector, click the **Build** button on the FuncGodotMap node.

You should see geometry appear with collision.

### Next after pipeline works
- We'll add custom entities to the FGD (info_player_start, enemy spawns, etc.).
- Then build the player controller.
- Then the first enemy + combat loop for M0.

## Scale / Units note
We're using inverse_scale_factor = 32 (classic Quake-style). This is what the architecture doc assumes.
If you prefer different proportions later we can change it (affects everything).

## Textures
Drop PNGs into `res://assets/textures/`. 
Special textures (`clip`, `skip`, `origin`) can be copied from the addon for now:
`res://addons/func_godot/textures/`

Let me know when you've got the first box room importing cleanly and we'll move to the player controller.
