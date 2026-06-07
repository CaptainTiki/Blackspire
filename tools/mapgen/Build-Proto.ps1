<#
  Proto room builder — swap $ActiveRoom to try different configs.

  Run from repo root:  powershell -File tools/mapgen/Build-Proto.ps1
#>

$ErrorActionPreference = "Stop"

$FLOOR = "trenchbroom/six"
$WALL  = "trenchbroom/four"
$TRIM  = "trenchbroom/five"

. "$PSScriptRoot/lib/Mapkit.ps1"
. "$PSScriptRoot/lib/Compositor.ps1"

# ---------------------------------------------------------------------------
# Panel-size presets
# ---------------------------------------------------------------------------

# Large panel: grand rooms, boss arenas.
$Large = @{ bay=256; thick=16; height=192; doorW=64;  doorH=64;  pilaster=20 }

# Standard panel: typical crypt rooms, corridors.
$Standard = @{ bay=128; thick=8;  height=128; doorW=48;  doorH=64;  pilaster=12 }

# ---------------------------------------------------------------------------
# Room specs
# ---------------------------------------------------------------------------

# Large: 3x4 long octagon with chamfered corners.
function Room-LargeOctagon($p) {
    $b = $p.bay
    @{
        bay=$b; thick=$p.thick; height=$p.height; doorW=$p.doorW; doorH=$p.doorH; pilaster=$p.pilaster
        start=@((-1.5*$b), (-2.0*$b)); dir=@(1,0)
        perimeter=@(
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="door" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=45 }, @{ op="bay"; kind="wall" }, @{ op="corner"; turn=45 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=45 }, @{ op="bay"; kind="wall" }, @{ op="corner"; turn=45 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=45 }, @{ op="bay"; kind="wall" }, @{ op="corner"; turn=45 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=45 }, @{ op="bay"; kind="wall" }, @{ op="corner"; turn=45 }
        )
    }
}

# Standard: 3x3 square room, single door on south wall.
function Room-StandardSquare($p) {
    $b = $p.bay
    @{
        bay=$b; thick=$p.thick; height=$p.height; doorW=$p.doorW; doorH=$p.doorH; pilaster=$p.pilaster
        start=@((-1.5*$b), (-1.5*$b)); dir=@(1,0)
        perimeter=@(
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="doorframed" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=90 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=90 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=90 },
            @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" }, @{ op="bay"; kind="wall" },
            @{ op="corner"; turn=90 }
        )
    }
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

$ActiveRoom = Room-StandardSquare $Standard

$mapsDir = Join-Path (Get-Location) "trenchbroom/maps"
if (-not (Test-Path $mapsDir)) { throw "Run from repo root: $mapsDir not found" }

$text = Build-Room $ActiveRoom
$path = Join-Path $mapsDir "proto_room_01.map"
[System.IO.File]::WriteAllText($path, $text)
$nb = ([regex]::Matches($text, "// brush ")).Count
$ne = ([regex]::Matches($text, "// entity ")).Count - 1
Write-Host "wrote $path  ($nb brushes, $ne entities)"
