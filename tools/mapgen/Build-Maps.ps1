<#
  Blackspire TrenchBroom .map generator (Valve 220 format).

  This file owns config (textures, hallway cross-section) and the per-room
  "recipes". All reusable brush primitives and architectural components live in
  lib/Mapkit.ps1, which is dot-sourced below.

  Add a new architectural part -> lib/Mapkit.ps1. Add a new room -> a Build-* here
  plus an entry in $outputs.

  Run from repo root:  powershell -File tools/mapgen/Build-Maps.ps1
  Writes into trenchbroom/maps/.
#>

$ErrorActionPreference = "Stop"

# --- Config ------------------------------------------------------------------
$FLOOR  = "trenchbroom/six"
$WALL   = "trenchbroom/four"
$TRIM   = "trenchbroom/five"
$ACCENT = "trenchbroom/thre"   # niche interior, to stand out from the walls

# Standard crypt hallway cross-section (used by the hallway kit + recipes).
$HALF_W  = 48         # interior half-width  -> interior X[-48, 48]
$WALL_T  = 16         # wall thickness       -> outer X[-64, 64]
$HEIGHT  = 96         # interior height      -> Z[0, 96]
$SLAB    = 16         # floor/ceiling slab thickness
$DOOR_HW = 32         # door half-width      -> opening X[-32, 32]
$DOOR_H  = 64         # door opening height  -> Z[0, 64]
$OUT_W   = $HALF_W + $WALL_T   # 64

. "$PSScriptRoot/lib/Mapkit.ps1"

# ============================================================================
#  Room recipes
# ============================================================================

function Build-StraightLong {
    $halfLen = 128            # Y[-128,128] -> 256 long
    $inner = $halfLen - 16    # 112, between end walls
    $niches = @(-56, 56)

    $b = @()
    $b += ,(Box (-$OUT_W) (-$halfLen) (-$SLAB) $OUT_W $halfLen 0 $FLOOR)                 # floor
    $b += ,(Box (-$OUT_W) (-$halfLen) $HEIGHT  $OUT_W $halfLen ($HEIGHT + $SLAB) $TRIM)  # ceiling
    $b += (SideWallWithNiche "left"  (-$halfLen) $halfLen $niches)
    $b += (SideWallWithNiche "right" (-$halfLen) $halfLen $niches)
    $b += (EndWallY  $halfLen   1)    # north / entrance
    $b += (EndWallY (-$halfLen) (-1)) # south / exit
    $b += ,(Pilaster "left" 0)
    $b += ,(Pilaster "right" 0)
    $b += ,(Baseboard "left"  (-$inner) $inner)
    $b += ,(Baseboard "right" (-$inner) $inner)

    $e = @()
    $e += ,(Connector 0 $halfLen    16 90  "entrance")
    $e += ,(Connector 0 (-$halfLen) 16 270 "exit")
    $e += ,(PointEntity "prop_urn" (-40)  56 32)
    $e += ,(PointEntity "prop_urn"   40 (-56) 32)

    Assemble $b $e
}

function Build-Tee {
    $halfLen = 96             # Y[-96,96] -> 192 long

    $b = @()
    $b += ,(Box (-$OUT_W) (-$halfLen) (-$SLAB) $OUT_W $halfLen 0 $FLOOR)
    $b += ,(Box (-$OUT_W) (-$halfLen) $HEIGHT  $OUT_W $halfLen ($HEIGHT + $SLAB) $TRIM)
    $b += (SideWallWithNiche "left" (-$halfLen) $halfLen @(0))         # west wall + niche

    # East wall pierced by the branch door at Y=0.
    $b += ,(Box $HALF_W (-$halfLen)  0       $OUT_W (-$DOOR_HW) $HEIGHT $WALL)  # south of door
    $b += ,(Box $HALF_W  $DOOR_HW    0       $OUT_W  $halfLen   $HEIGHT $WALL)  # north of door
    $b += ,(Box $HALF_W (-$DOOR_HW)  $DOOR_H $OUT_W  $DOOR_HW   $HEIGHT $TRIM)  # door lintel

    $b += (EndWallY  $halfLen   1)
    $b += (EndWallY (-$halfLen) (-1))
    $b += ,(Baseboard "left" (-80) 80)

    $e = @()
    $e += ,(Connector 0 $halfLen    16 90  "entrance")
    $e += ,(Connector 0 (-$halfLen) 16 270 "exit")
    $e += ,(Connector $OUT_W 0 16 0 "side_east" "crypt standard branch")

    Assemble $b $e
}

function Build-Bend {
    # 90-degree turn: enter from the north (+Y), exit to the east (+X).
    # Vertical leg centered on X=0; horizontal leg centered on Y=0. The inside
    # corner (+X,+Y) and outside corner (-X,-Y) are chamfered at 45 degrees so
    # the corridor bends rather than turning square. Chamfer leg = 28 keeps the
    # diagonal passage ~96 wide (matching the straight cross-section).
    $north = 160             # Y of north end (entrance)
    $east  = 160             # X of east end (exit)
    $cham  = 28

    $b = @()
    # Floor + ceiling as two overlapping L boxes.
    $b += ,(Box (-$OUT_W) (-$OUT_W) (-$SLAB) $OUT_W $north 0 $FLOOR)            # floor, vertical leg
    $b += ,(Box (-$OUT_W) (-$OUT_W) (-$SLAB) $east $OUT_W 0 $FLOOR)             # floor, horizontal leg
    $b += ,(Box (-$OUT_W) (-$OUT_W) $HEIGHT  $OUT_W $north ($HEIGHT+$SLAB) $TRIM)  # ceiling, vertical
    $b += ,(Box (-$OUT_W) (-$OUT_W) $HEIGHT  $east $OUT_W ($HEIGHT+$SLAB) $TRIM)   # ceiling, horizontal

    # Outer (long) walls.
    $b += ,(Box (-$OUT_W) (-$OUT_W) 0 (-$HALF_W) $north $HEIGHT $WALL)   # outer west
    $b += ,(Box (-$OUT_W) (-$OUT_W) 0 $east (-$HALF_W) $HEIGHT $WALL)    # outer south
    # Inner (short) walls, north/east of the bend.
    $b += ,(Box $HALF_W $HALF_W 0 $OUT_W $north $HEIGHT $WALL)           # inner east
    $b += ,(Box $HALF_W $HALF_W 0 $east $OUT_W $HEIGHT $WALL)            # inner north

    # End walls with doors.
    $b += (EndWallY $north 1)
    $b += (EndWallX $east 1)

    # Chamfer wedges.
    $b += ,(CornerWedge $HALF_W $HALF_W (-1) (-1) $cham)        # inside corner (48,48)
    $b += ,(CornerWedge (-$HALF_W) (-$HALF_W) 1 1 $cham)        # outside corner (-48,-48)

    $e = @()
    $e += ,(Connector 0 $north 16 90 "entrance")
    $e += ,(Connector $east 0 16 0 "exit")
    $e += ,(PointEntity "prop_urn" 96 (-24) 32)

    Assemble $b $e
}

function Build-Crypt {
    # Dead-end crypt chamber: 256x256 interior, single south entrance, sunken
    # central floor reached by two steps, pointed niches on the other 3 walls.
    $b = @()
    # Base slab (its top, Z=-24, is the sunken floor).
    $b += ,(Box (-144) (-144) (-40) 144 144 (-24) $FLOOR)
    # Walkway ring (entry level, Z=0) under/inside the perimeter walls.
    $b += ,(Box (-144) 96 (-24) 144 144 0 $FLOOR)
    $b += ,(Box (-144) (-144) (-24) 144 (-96) 0 $FLOOR)
    $b += ,(Box 96 (-96) (-24) 144 96 0 $FLOOR)
    $b += ,(Box (-144) (-96) (-24) (-96) 96 0 $FLOOR)
    # Step ring (Z=-12) between walkway and sunken floor.
    $b += ,(Box (-96) 80 (-24) 96 96 (-12) $FLOOR)
    $b += ,(Box (-96) (-96) (-24) 96 (-80) (-12) $FLOOR)
    $b += ,(Box 80 (-80) (-24) 96 80 (-12) $FLOOR)
    $b += ,(Box (-96) (-80) (-24) (-80) 80 (-12) $FLOOR)
    # Flat ceiling.
    $b += ,(Box (-144) (-144) 160 144 144 176 $TRIM)
    # Three walls of pointed niches.
    $b += (PointedNicheWall "north" @(-56, 56))
    $b += (PointedNicheWall "east"  @(-56, 56))
    $b += (PointedNicheWall "west"  @(-56, 56))
    # South wall with the single entrance door (64x64).
    $b += ,(Box (-144) (-144) 0 (-32) (-128) 160 $WALL)   # left jamb
    $b += ,(Box 32 (-144) 0 144 (-128) 160 $WALL)         # right jamb
    $b += ,(Box (-32) (-144) 64 32 (-128) 160 $TRIM)      # lintel

    # Dressing: baseboard, mantle, niche frames, pillars.
    $b += (PerimeterTrim 0 8 4 -doorGap)        # floor baseboard (gap at door)
    $b += (PerimeterTrim 120 130 6)             # mantle above the niches
    foreach ($side in @("north", "east", "west")) {
        foreach ($c in @(-56, 56)) { $b += (NicheFrame $side $c) }
    }
    foreach ($p in @(@(116,116), @(116,-116), @(-116,116), @(-116,-116),
                     @(0,116), @(116,0), @(-116,0))) {
        $b += (Pillar $p[0] $p[1])
    }

    $e = @()
    $e += ,(Connector 0 (-128) 16 270 "entrance" "crypt standard")
    $e += ,(PointEntity "prop_urn" (-48) (-48) (-24))
    $e += ,(PointEntity "prop_urn" 48 40 (-24))

    Assemble $b $e
}

function Build-Hub {
    # Large two-level hub. Footprint variables drive everything; heights are fixed
    # (balcony at 128, ceiling at 272). Open central light-well, two back stairs
    # (8-unit rise), full perimeter balcony, doors on both levels.
    $hx = 384; $hy = 512            # interior half extents (768 x 1024 interior)
    $wt = 16; $ox = $hx + $wt; $oy = $hy + $wt
    $zb = 128; $zc = 272           # balcony top, ceiling
    $ring = 128                    # balcony walkway width
    $inx = $hx - $ring; $iny = $hy - $ring   # ring inner edges (256, 384)
    $dhw = 32; $dh = 64            # door half-width, ground door height
    $rt = 8; $rh = $zb + 32        # rail thickness, rail top (160)
    $sw = 72                       # stair width (narrower, less of a feature)
    $sn = 16; $srun = 16           # 16 steps, run 16 (steeper than before)
    $sy0 = $iny - ($srun * $sn)    # push stairs back: start so they land at the rear ring

    $b = @()
    # Ground floor + ceiling.
    $b += ,(Box (-$ox) (-$oy) (-16) $ox $oy 0 $FLOOR)
    $b += ,(Box (-$ox) (-$oy) $zc $ox $oy ($zc+16) $TRIM)

    # Perimeter walls in two bands: ground (square niches) + upper gallery (pointed
    # niches). Niches sit in the +/-256 bays; doors per level/side.
    $gDoor = @{ kind="door"; c=0; hw=$dhw; z0=0; z1=$dh }
    $bDoor = @{ kind="door"; c=0; hw=$dhw; z0=$zb; z1=($zb+$dh) }
    $sqL = @{ kind="square"; c=(-256); hw=48; z0=24; z1=96; recess=12 }
    $sqR = @{ kind="square"; c=256; hw=48; z0=24; z1=96; recess=12 }
    $ptL = @{ kind="pointed"; c=(-256); hw=48; z0=152; zs=200; z1=256; recess=12 }
    $ptR = @{ kind="pointed"; c=256; hw=48; z0=152; zs=200; z1=256; recess=12 }

    # Ground band (z 0..128).
    $b += (NicheWall "north" $hy (-$hx) $hx 0 $zb 16 @($gDoor, $sqL, $sqR))
    $b += (NicheWall "south" $hy (-$hx) $hx 0 $zb 16 @($gDoor, $sqL, $sqR))
    $b += (NicheWall "east"  $hx (-$oy) $oy 0 $zb 16 @($sqL, $sqR))
    $b += (NicheWall "west"  $hx (-$oy) $oy 0 $zb 16 @($sqL, $sqR))
    # Upper gallery band (z 128..272).
    $b += (NicheWall "north" $hy (-$hx) $hx $zb $zc 16 @($ptL, $ptR))
    $b += (NicheWall "south" $hy (-$hx) $hx $zb $zc 16 @($ptL, $ptR))
    $b += (NicheWall "east"  $hx (-$oy) $oy $zb $zc 16 @($bDoor, $ptL, $ptR))
    $b += (NicheWall "west"  $hx (-$oy) $oy $zb $zc 16 @($bDoor, $ptL, $ptR))

    # 4x4 frame trim around every niche (square + pointed) on all four walls.
    foreach ($side in @("north", "south")) {
        foreach ($f in @($sqL, $sqR, $ptL, $ptR)) { $b += (FrameWall $side $hy $f) }
    }
    foreach ($side in @("east", "west")) {
        foreach ($f in @($sqL, $sqR, $ptL, $ptR)) { $b += (FrameWall $side $hx $f) }
    }

    # Balcony ring floor (z[112,128]); central X[-inx,inx] Y[-iny,iny] stays open.
    $b += ,(Box (-$hx) $iny 112 $hx $hy $zb $FLOOR)      # north strip
    $b += ,(Box (-$hx) (-$hy) 112 $hx (-$iny) $zb $FLOOR)  # south strip
    $b += ,(Box $inx (-$iny) 112 $hx $iny $zb $FLOOR)    # east strip
    $b += ,(Box (-$hx) (-$iny) 112 (-$inx) $iny $zb $FLOOR) # west strip

    # Balcony railings; north rail has gaps where the two stairs land.
    $b += ,(Box (-$hx) $iny $zb (-$inx) ($iny+$rt) $rh $TRIM)       # north NW
    $b += ,(Box (-$inx+$sw) $iny $zb ($inx-$sw) ($iny+$rt) $rh $TRIM) # north center
    $b += ,(Box $inx $iny $zb $hx ($iny+$rt) $rh $TRIM)            # north NE
    $b += ,(Box (-$hx) (-$iny-$rt) $zb $hx (-$iny) $rh $TRIM)      # south
    $b += ,(Box $inx (-$iny) $zb ($inx+$rt) $iny $rh $TRIM)        # east
    $b += ,(Box (-$inx-$rt) (-$iny) $zb (-$inx) $iny $rh $TRIM)    # west

    # Two back stairs (8 rise, run 16) rising in the open center to the balcony.
    $b += (StairY (-$inx) (-$inx+$sw) $sy0 $iny $zb $sn)    # west stair
    $b += (StairY ($inx-$sw) $inx $sy0 $iny $zb $sn)        # east stair

    # Center dais (POI pedestal base).
    $b += ,(Box (-112) (-112) 0 112 112 8 $FLOOR)
    $b += ,(Box (-88) (-88) 0 88 88 16 $FLOOR)

    # Engaged wall pilasters dividing the walls into bays (define niche sizes).
    # N/S pilasters flank the ground door (X=0); E/W pilasters flank the balcony door (Y=0).
    foreach ($c in @((-128), 128)) {
        $b += (WallPilaster "north" $c $hy)
        $b += (WallPilaster "south" $c $hy)
    }
    foreach ($c in @((-384), (-128), 128, 384)) {
        $b += (WallPilaster "east" $c $hx)
        $b += (WallPilaster "west" $c $hx)
    }

    $e = @()
    $e += ,(Connector 0 (-$hy) 16 270 "ground_south" "crypt standard")
    $e += ,(Connector 0 $hy 16 90 "ground_north" "crypt standard")
    $e += ,(Connector (-$hx) 0 ($zb+16) 180 "balcony_west" "crypt standard upper")
    $e += ,(Connector $hx 0 ($zb+16) 0 "balcony_east" "crypt standard upper")
    $e += ,(PointEntity "info_enemy_spawn" 0 0 16)
    $e += ,(PointEntity "info_enemy_spawn" (-240) (-240) 0)
    $e += ,(PointEntity "info_enemy_spawn" 240 240 0)
    $e += ,(PointEntity "prop_urn" (-320) 448 $zb)
    $e += ,(PointEntity "prop_urn" 320 (-448) $zb)

    Assemble $b $e
}

# ============================================================================
#  Output
# ============================================================================

$mapsDir = Join-Path (Get-Location) "trenchbroom/maps"
if (-not (Test-Path $mapsDir)) { throw "Run from repo root: $mapsDir not found" }

$outputs = [ordered]@{
    "crypt_hall_straight_01.map"   = Build-StraightLong
    "crypt_hall_tee_01.map"        = Build-Tee
    "crypt_hall_bend_01.map"       = Build-Bend
    "crypt_room_deadend_01.map"    = Build-Crypt
    "crypt_room_hub_2level_01.map" = Build-Hub
}
foreach ($name in $outputs.Keys) {
    $path = Join-Path $mapsDir $name
    [System.IO.File]::WriteAllText($path, $outputs[$name])
    $nbrush = ([regex]::Matches($outputs[$name], "// brush ")).Count
    $nent = ([regex]::Matches($outputs[$name], "// entity ")).Count - 1
    Write-Host "wrote $path  ($nbrush brushes, $nent entities)"
}
