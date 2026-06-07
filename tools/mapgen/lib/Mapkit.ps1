<#
  Blackspire map kit — reusable Valve-220 brush primitives and architectural
  components. Dot-sourced by the room recipes in Build-Maps.ps1.

  Layers:
    1. Primitives + emit : Box, vector helpers, Face/FacePts, TriPrism, QuadPrism,
                           Connector, PointEntity, Assemble.
    2. Architectural kit : niche walls, frames, pilasters, stairs, trim, chamfers.

  Functions read texture/cross-section config ($WALL, $TRIM, $HALF_W, ...) from the
  calling script's scope at call time, so the recipe file owns that config.

  The Box face order/winding/UV axes were derived face-for-face from the committed
  room_hallway_64_01.map so imported geometry matches existing rooms.

  PowerShell gotcha baked into every helper below: the comma operator binds tighter
  than +/-, so arithmetic inside an @(...) literal must be parenthesized, or
  `a-b, c` silently parses as `a - @(b,c)`.
#>

# ============================================================================
#  Primitives + Valve-220 emit
# ============================================================================

function Box([int]$x0,[int]$y0,[int]$z0,[int]$x1,[int]$y1,[int]$z1,[string]$tex) {
    if ($x0 -gt $x1) { $t=$x0; $x0=$x1; $x1=$t }
    if ($y0 -gt $y1) { $t=$y0; $y0=$y1; $y1=$t }
    if ($z0 -gt $z1) { $t=$z0; $z0=$z1; $z1=$t }
    @(
      "( $x0 $y1 $z1 ) ( $x0 $y0 $z1 ) ( $x0 $y0 $z0 ) $tex [ 0 -1 0 0 ] [ 0 0 -1 0 ] 0 1 1",   # -X
      "( $x0 $y0 $z1 ) ( $x1 $y0 $z1 ) ( $x1 $y0 $z0 ) $tex [ 1 0 0 0 ] [ 0 0 -1 0 ] 0 1 1",     # -Y
      "( $x1 $y1 $z0 ) ( $x0 $y1 $z0 ) ( $x0 $y0 $z0 ) $tex [ 1 0 0 0 ] [ 0 -1 0 0 ] 0 1 1",     # -Z
      "( $x0 $y1 $z1 ) ( $x1 $y1 $z1 ) ( $x1 $y0 $z1 ) $tex [ 1 0 0 0 ] [ 0 -1 0 0 ] 0 1 1",     # +Z
      "( $x1 $y1 $z0 ) ( $x1 $y1 $z1 ) ( $x0 $y1 $z1 ) $tex [ -1 0 0 0 ] [ 0 0 -1 0 ] 0 1 1",    # +Y
      "( $x1 $y0 $z1 ) ( $x1 $y1 $z1 ) ( $x1 $y1 $z0 ) $tex [ 0 1 0 0 ] [ 0 0 -1 0 ] 0 1 1"      # +X
    )
}

# A single Valve-220 face from 3 points + texture/UV strings.
function Face($p1, $p2, $p3, [string]$tex, [string]$uv) {
    "( $($p1[0]) $($p1[1]) $($p1[2]) ) ( $($p2[0]) $($p2[1]) $($p2[2]) ) ( $($p3[0]) $($p3[1]) $($p3[2]) ) $tex $uv 0 1 1"
}
$UV_FLAT = "[ 1 0 0 0 ] [ 0 -1 0 0 ]"   # horizontal face (top/bottom)
$UV_X    = "[ 0 1 0 0 ] [ 0 0 -1 0 ]"   # X=const vertical face
$UV_Y    = "[ 1 0 0 0 ] [ 0 0 -1 0 ]"   # Y=const vertical face
$UV_DIAG = "[ 0.7071067811865476 -0.7071067811865476 0 0 ] [ 0 0 -1 0 ]"  # 45-degree face

# --- Vector helpers ---------------------------------------------------------
function VSub($a,$b)  { @(($a[0]-$b[0]), ($a[1]-$b[1]), ($a[2]-$b[2])) }
function VAdd($a,$b)  { @(($a[0]+$b[0]), ($a[1]+$b[1]), ($a[2]+$b[2])) }
function VCross($a,$b){ @((($a[1]*$b[2])-($a[2]*$b[1])), (($a[2]*$b[0])-($a[0]*$b[2])), (($a[0]*$b[1])-($a[1]*$b[0]))) }
function VDot($a,$b)  { ($a[0]*$b[0]) + ($a[1]*$b[1]) + ($a[2]*$b[2]) }
function VLen($a)     { [math]::Sqrt((VDot $a $a)) }
function VNorm($a)    { $l = VLen $a; if ($l -eq 0) { @(0,0,0) } else { @(($a[0]/$l), ($a[1]/$l), ($a[2]/$l)) } }
function PtStr($p)    { "$($p[0]) $($p[1]) $($p[2])" }
function AxStr($a)    { "[ $($a[0]) $($a[1]) $($a[2]) 0 ]" }

# A Valve face from 3 points; UV axes derived from the plane so any orientation
# textures cleanly enough for blockout.
function FacePts($p1, $p2, $p3, [string]$tex) {
    $n = VNorm (VCross (VSub $p2 $p1) (VSub $p3 $p1))
    $up = @(0,0,1)
    if ([math]::Abs((VDot $n $up)) -gt 0.9) { $u = @(1,0,0); $v = @(0,-1,0) }
    else { $u = VNorm (VCross $up $n); $v = VNorm (VCross $n $u) }
    "( $(PtStr $p1) ) ( $(PtStr $p2) ) ( $(PtStr $p3) ) $tex $(AxStr $u) $(AxStr $v) 0 1 1"
}

# One face, winding flipped so its normal points toward the prism centroid g (inward).
function EmitFace($p1, $p2, $p3, $g, [string]$tex) {
    $n = VCross (VSub $p2 $p1) (VSub $p3 $p1)
    if ((VDot $n (VSub $g $p1)) -lt 0) { $tmp = $p2; $p2 = $p3; $p3 = $tmp }
    FacePts $p1 $p2 $p3 $tex
}

# Triangular prism: triangle (a,b,c) extruded by vector e. Normals point inward
# (Box convention) regardless of orientation. Faces emitted explicitly to avoid
# PowerShell flattening nested point-triples.
function TriPrism($a, $b, $c, $e, [string]$tex) {
    $a2 = VAdd $a $e; $b2 = VAdd $b $e; $c2 = VAdd $c $e
    $g = @( (($a[0]+$b[0]+$c[0]+$a2[0]+$b2[0]+$c2[0]) / 6.0),
            (($a[1]+$b[1]+$c[1]+$a2[1]+$b2[1]+$c2[1]) / 6.0),
            (($a[2]+$b[2]+$c[2]+$a2[2]+$b2[2]+$c2[2]) / 6.0) )
    $faces = @()
    $faces += (EmitFace $a  $b  $c  $g $tex)   # near cap
    $faces += (EmitFace $a2 $b2 $c2 $g $tex)   # far cap
    $faces += (EmitFace $a  $b  $b2 $g $tex)   # side a-b
    $faces += (EmitFace $b  $c  $c2 $g $tex)   # side b-c
    $faces += (EmitFace $c  $a  $a2 $g $tex)   # side c-a
    ,$faces
}

# Prism from a planar convex quad (a,b,c,d in order) extruded by e. Inward winding.
function QuadPrism($a, $b, $c, $d, $e, [string]$tex) {
    $a2 = VAdd $a $e; $b2 = VAdd $b $e; $c2 = VAdd $c $e; $d2 = VAdd $d $e
    $g = @( (($a[0]+$b[0]+$c[0]+$d[0]+$a2[0]+$b2[0]+$c2[0]+$d2[0]) / 8.0),
            (($a[1]+$b[1]+$c[1]+$d[1]+$a2[1]+$b2[1]+$c2[1]+$d2[1]) / 8.0),
            (($a[2]+$b[2]+$c[2]+$d[2]+$a2[2]+$b2[2]+$c2[2]+$d2[2]) / 8.0) )
    $faces = @()
    $faces += (EmitFace $a  $b  $c  $g $tex)   # front quad (d coplanar)
    $faces += (EmitFace $a2 $d2 $c2 $g $tex)   # back quad
    $faces += (EmitFace $a  $b  $b2 $g $tex)   # side a-b (inner slope edge)
    $faces += (EmitFace $b  $c  $c2 $g $tex)   # side b-c (top)
    $faces += (EmitFace $c  $d  $d2 $g $tex)   # side c-d (outer slope edge)
    $faces += (EmitFace $d  $a  $a2 $g $tex)   # side d-a (bottom)
    ,$faces
}

function Connector([int]$ox, [int]$oy, [int]$oz, [int]$angle, [string]$id,
                   [string]$tags = "crypt standard hallway", [int]$dw = 64, [int]$dh = 64) {
    @(
        '{'
        '"classname" "room_connector"'
        "`"origin`" `"$ox $oy $oz`""
        "`"angle`" `"$angle`""
        "`"connector_id`" `"$id`""
        '"connector_type" "doorway"'
        "`"tags`" `"$tags`""
        "`"door_width_units`" `"$dw`""
        "`"door_height_units`" `"$dh`""
        '}'
    )
}

function PointEntity([string]$classname, [int]$ox, [int]$oy, [int]$oz) {
    @(
        '{'
        "`"classname`" `"$classname`""
        "`"origin`" `"$ox $oy $oz`""
        '}'
    )
}

function Assemble($brushes, $entities) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($l in @("// Game: Blackspire", "// Format: Valve", "// entity 0", "{",
                     '"mapversion" "220"', '"wad" ""', '"classname" "worldspawn"')) { $lines.Add($l) }
    for ($i = 0; $i -lt $brushes.Count; $i++) {
        $lines.Add("// brush $i"); $lines.Add("{")
        foreach ($face in $brushes[$i]) { $lines.Add($face) }
        $lines.Add("}")
    }
    $lines.Add("}")
    for ($i = 0; $i -lt $entities.Count; $i++) {
        $lines.Add("// entity $($i + 1)")
        foreach ($l in $entities[$i]) { $lines.Add($l) }
    }
    ($lines -join "`n") + "`n"
}

# ============================================================================
#  Hallway kit (96-wide cross-section; uses $HALF_W, $OUT_W, $HEIGHT, ...)
# ============================================================================

# Triangular prism that fills a corner with a 45-degree chamfer face.
# Right-angle vertex at (cx,cy); legs of length L run toward (dx,dy) in {-1,+1}.
# The hypotenuse (the visible chamfer) faces outward toward (-dx,-dy).
function CornerWedge([int]$cx, [int]$cy, [int]$dx, [int]$dy, [int]$L) {
    $z0 = 0; $z1 = $HEIGHT
    $bx = $cx + $dx * $L     # B along the X-leg
    $cyy = $cy + $dy * $L    # C along the Y-leg
    $A0=@($cx,$cy,$z0);  $A1=@($cx,$cy,$z1)
    $B0=@($bx,$cy,$z0);  $B1=@($bx,$cy,$z1)
    $C0=@($cx,$cyy,$z0); $C1=@($cx,$cyy,$z1)
    @(
        (Face $A0 $B0 $C0 $WALL $UV_FLAT)   # bottom (Z=z0)
        (Face $A1 $C1 $B1 $WALL $UV_FLAT)   # top    (Z=z1)
        (Face $A0 $B1 $B0 $WALL $UV_Y)      # leg on Y=cy
        (Face $A0 $C0 $C1 $WALL $UV_X)      # leg on X=cx
        (Face $B0 $C1 $C0 $WALL $UV_DIAG)   # hypotenuse (visible chamfer)
    )
}

# Door-pierced end wall on a +/-Y face (centered on X=0). Returns brushes.
function EndWallY([int]$yOuter, [int]$sign) {
    $yIn = $yOuter - ($sign * $WALL_T)
    @(
        ,(Box (-$HALF_W)  $yOuter 0       (-$DOOR_HW) $yIn $HEIGHT $WALL)   # left jamb
        ,(Box  $DOOR_HW   $yOuter 0         $HALF_W   $yIn $HEIGHT $WALL)   # right jamb
        ,(Box (-$DOOR_HW) $yOuter $DOOR_H   $DOOR_HW  $yIn $HEIGHT $TRIM)   # lintel
    )
}

# Door-pierced end wall on a +/-X face (centered on Y=0).
function EndWallX([int]$xOuter, [int]$sign) {
    $xIn = $xOuter - ($sign * $WALL_T)
    @(
        ,(Box $xOuter (-$HALF_W) 0       $xIn (-$DOOR_HW) $HEIGHT $WALL)   # south jamb
        ,(Box $xOuter  $DOOR_HW  0       $xIn  $HALF_W    $HEIGHT $WALL)   # north jamb
        ,(Box $xOuter (-$DOOR_HW) $DOOR_H $xIn  $DOOR_HW   $HEIGHT $TRIM)  # lintel
    )
}

function SideWallWithNiche([string]$side, [int]$y0, [int]$y1, $nicheCenters,
                           [int]$nicheHW = 16, [int]$nz0 = 28, [int]$nz1 = 68, [int]$depth = 8) {
    if ($side -eq "left") { $xOut = -$OUT_W; $xIn = -$HALF_W; $xBack = $xIn - $depth }
    else                  { $xOut =  $OUT_W; $xIn =  $HALF_W; $xBack = $xIn + $depth }

    $brushes = @()
    $cursor = $y0
    foreach ($cy in ($nicheCenters | Sort-Object)) {
        $ny0 = $cy - $nicheHW
        $ny1 = $cy + $nicheHW
        if ($ny0 -gt $cursor) { $brushes += ,(Box $xOut $cursor 0 $xIn $ny0 $HEIGHT $WALL) }
        $brushes += ,(Box $xOut $ny0 0      $xIn  $ny1 $nz0    $WALL)   # under niche
        $brushes += ,(Box $xOut $ny0 $nz1   $xIn  $ny1 $HEIGHT $WALL)   # over niche
        $brushes += ,(Box $xOut $ny0 $nz0   $xBack $ny1 $nz1   $WALL)   # niche back panel
        $cursor = $ny1
    }
    if ($cursor -lt $y1) { $brushes += ,(Box $xOut $cursor 0 $xIn $y1 $HEIGHT $WALL) }
    ,$brushes
}

function Pilaster([string]$side, [int]$cy, [int]$half = 8, [int]$depth = 8) {
    if ($side -eq "left") { $xIn = -$HALF_W; $xFace = $xIn + $depth }
    else                  { $xIn =  $HALF_W; $xFace = $xIn - $depth }
    Box $xIn ($cy - $half) 0 $xFace ($cy + $half) $HEIGHT $TRIM
}

function Baseboard([string]$side, [int]$y0, [int]$y1, [int]$h = 12, [int]$depth = 4) {
    if ($side -eq "left") { $xIn = -$HALF_W; $xFace = $xIn + $depth }
    else                  { $xIn =  $HALF_W; $xFace = $xIn - $depth }
    Box $xIn $y0 0 $xFace $y1 $h $TRIM
}

# ============================================================================
#  Crypt-room kit: pointed (lancet) niche walls + frames + trim (interior +/-128)
# ============================================================================

function SegBox([string]$side, [int]$a0, [int]$a1, [int]$z0, [int]$z1) {
    switch ($side) {
        "north" { Box $a0 128 $z0 $a1 144 $z1 $WALL }
        "east"  { Box 128 $a0 $z0 144 $a1 $z1 $WALL }
        "west"  { Box (-144) $a0 $z0 (-128) $a1 $z1 $WALL }
    }
}

# Sill / header / back-panel boxes. depth d measured from the room-side face into the wall.
function NicheBox([string]$side, [int]$c, [int]$hw, [int]$z0, [int]$z1, [int]$d0, [int]$d1) {
    switch ($side) {
        "north" { Box ($c-$hw) (128+$d0) $z0 ($c+$hw) (128+$d1) $z1 $WALL }
        "east"  { Box (128+$d0) ($c-$hw) $z0 (128+$d1) ($c+$hw) $z1 $WALL }
        "west"  { Box (-128-$d0) ($c-$hw) $z0 (-128-$d1) ($c+$hw) $z1 $WALL }
    }
}

# The two angled gable fillers that turn a rectangular recess into a pointed arch.
function NicheFillers([string]$side, [int]$c, [int]$hw, [int]$Zs, [int]$Zt, [int]$recessD) {
    switch ($side) {
        "north" { $f = 128;  $e = @(0,$recessD,0)
                  $lA=@(($c-$hw),$f,$Zs); $lB=@($c,$f,$Zt); $lC=@(($c-$hw),$f,$Zt)
                  $rA=@(($c+$hw),$f,$Zs); $rB=@($c,$f,$Zt); $rC=@(($c+$hw),$f,$Zt) }
        "east"  { $f = 128;  $e = @($recessD,0,0)
                  $lA=@($f,($c-$hw),$Zs); $lB=@($f,$c,$Zt); $lC=@($f,($c-$hw),$Zt)
                  $rA=@($f,($c+$hw),$Zs); $rB=@($f,$c,$Zt); $rC=@($f,($c+$hw),$Zt) }
        "west"  { $f = -128; $e = @((-$recessD),0,0)
                  $lA=@($f,($c-$hw),$Zs); $lB=@($f,$c,$Zt); $lC=@($f,($c-$hw),$Zt)
                  $rA=@($f,($c+$hw),$Zs); $rB=@($f,$c,$Zt); $rC=@($f,($c+$hw),$Zt) }
    }
    @( (TriPrism $lA $lB $lC $e $WALL), (TriPrism $rA $rB $rC $e $WALL) )
}

function PointedNicheWall([string]$side, $centers, [int]$hw = 24, [int]$Zb = 24,
                          [int]$Zs = 88, [int]$Zt = 120, [int]$recessD = 12) {
    $aMin = -144; $aMax = 144; $wallTop = 160
    $brushes = @()
    $cursor = $aMin
    foreach ($c in ($centers | Sort-Object)) {
        $n0 = $c - $hw; $n1 = $c + $hw
        if ($n0 -gt $cursor) { $brushes += ,(SegBox $side $cursor $n0 0 $wallTop) }
        $brushes += ,(NicheBox $side $c $hw 0   $Zb      0        16)   # sill
        $brushes += ,(NicheBox $side $c $hw $Zt $wallTop 0        16)   # header
        $brushes += ,(NicheBox $side $c $hw $Zb $Zt      $recessD 16)   # back panel
        foreach ($fp in (NicheFillers $side $c $hw $Zs $Zt $recessD)) { $brushes += ,$fp }
        $cursor = $n1
    }
    if ($cursor -lt $aMax) { $brushes += ,(SegBox $side $cursor $aMax 0 $wallTop) }
    ,$brushes
}

# Niche frame constants mirror PointedNicheWall.
$NF_HW = 24; $NF_ZB = 24; $NF_ZS = 88; $NF_ZT = 120

# A protruding trim box on a wall. along-axis is X (north) or Y (east/west);
# proj is how far it sticks into the room from the wall face.
function FrameBox([string]$side, [int]$a0, [int]$a1, [int]$z0, [int]$z1, [int]$proj = 4) {
    switch ($side) {
        "north" { Box $a0 (128-$proj) $z0 $a1 128 $z1 $TRIM }
        "east"  { Box (128-$proj) $a0 $z0 128 $a1 $z1 $TRIM }
        "west"  { Box (-128) $a0 $z0 (-128+$proj) $a1 $z1 $TRIM }
    }
}

# Two slim molding bars tracing the pointed arch, one per slope. Same 4x4 section
# as the jambs, offset perpendicular to the niche's 3:4 slope (perp unit 0.8,0.6).
function ArchMolding([string]$side, [int]$c, [int]$proj = 4) {
    $hw = $NF_HW; $Zs = $NF_ZS; $Zt = $NF_ZT
    $oa = 3.2; $oz = 2.4    # 4 * perpendicular unit (0.8 along, 0.6 up)
    switch ($side) {
        "north" { $f = 128;  $e = @(0,(-$proj),0)
                  $lInLow=@(($c-$hw),$f,$Zs);        $lInHigh=@($c,$f,$Zt)
                  $lOutHigh=@(($c-$oa),$f,($Zt+$oz)); $lOutLow=@(($c-$hw-$oa),$f,($Zs+$oz))
                  $rInLow=@(($c+$hw),$f,$Zs);        $rInHigh=@($c,$f,$Zt)
                  $rOutHigh=@(($c+$oa),$f,($Zt+$oz)); $rOutLow=@(($c+$hw+$oa),$f,($Zs+$oz)) }
        "east"  { $f = 128;  $e = @((-$proj),0,0)
                  $lInLow=@($f,($c-$hw),$Zs);        $lInHigh=@($f,$c,$Zt)
                  $lOutHigh=@($f,($c-$oa),($Zt+$oz)); $lOutLow=@($f,($c-$hw-$oa),($Zs+$oz))
                  $rInLow=@($f,($c+$hw),$Zs);        $rInHigh=@($f,$c,$Zt)
                  $rOutHigh=@($f,($c+$oa),($Zt+$oz)); $rOutLow=@($f,($c+$hw+$oa),($Zs+$oz)) }
        "west"  { $f = -128; $e = @($proj,0,0)
                  $lInLow=@($f,($c-$hw),$Zs);        $lInHigh=@($f,$c,$Zt)
                  $lOutHigh=@($f,($c-$oa),($Zt+$oz)); $lOutLow=@($f,($c-$hw-$oa),($Zs+$oz))
                  $rInLow=@($f,($c+$hw),$Zs);        $rInHigh=@($f,$c,$Zt)
                  $rOutHigh=@($f,($c+$oa),($Zt+$oz)); $rOutLow=@($f,($c+$hw+$oa),($Zs+$oz)) }
    }
    @( (QuadPrism $lInLow $lInHigh $lOutHigh $lOutLow $e $TRIM),
       (QuadPrism $rInLow $rInHigh $rOutHigh $rOutLow $e $TRIM) )
}

# Full 4x4 raised border around one niche: side jambs, sill, and arch spandrels.
function NicheFrame([string]$side, [int]$c, [int]$fw = 4) {
    $hw = $NF_HW; $Zb = $NF_ZB; $Zs = $NF_ZS
    $b = @()
    $b += ,(FrameBox $side ($c-$hw-$fw) ($c-$hw)    $Zb       $Zs)   # left jamb
    $b += ,(FrameBox $side ($c+$hw)    ($c+$hw+$fw) $Zb       $Zs)   # right jamb
    $b += ,(FrameBox $side ($c-$hw-$fw) ($c+$hw+$fw) ($Zb-6)  $Zb)   # sill
    foreach ($fp in (ArchMolding $side $c)) { $b += ,$fp }
    ,$b
}

# Continuous trim band around all four walls (door gap on the south wall optional).
function PerimeterTrim([int]$z0, [int]$z1, [int]$depth, [switch]$doorGap) {
    $b = @()
    $b += ,(Box (-128) (128-$depth) $z0 128 128 $z1 $TRIM)            # north
    $b += ,(Box (128-$depth) (-128) $z0 128 128 $z1 $TRIM)           # east
    $b += ,(Box (-128) (-128) $z0 (-128+$depth) 128 $z1 $TRIM)       # west
    if ($doorGap) {
        $b += ,(Box (-128) (-128) $z0 (-32) (-128+$depth) $z1 $TRIM) # south, left of door
        $b += ,(Box 32 (-128) $z0 128 (-128+$depth) $z1 $TRIM)       # south, right of door
    } else {
        $b += ,(Box (-128) (-128) $z0 128 (-128+$depth) $z1 $TRIM)   # south, full
    }
    ,$b
}

# Column with wide base, narrow shaft, wide capital, floor to ceiling.
function Pillar([int]$cx, [int]$cy) {
    $b = @()
    $b += ,(Box ($cx-11) ($cy-11) 0   ($cx+11) ($cy+11) 18  $TRIM)   # base
    $b += ,(Box ($cx-7)  ($cy-7)  18  ($cx+7)  ($cy+7)  142 $WALL)   # shaft
    $b += ,(Box ($cx-11) ($cy-11) 142 ($cx+11) ($cy+11) 160 $TRIM)   # capital
    ,$b
}

# ============================================================================
#  Hub kit: engaged 2-story pilasters, parametric niche walls, frames, stairs
# ============================================================================

# One box of an engaged wall pilaster. ah = half-width along the wall, pr = how
# far it protrudes into the room from the inner face at +/-face.
function PilBox([string]$side, [int]$c, [int]$ah, [int]$pr, [int]$z0, [int]$z1, [string]$tex, [int]$face) {
    switch ($side) {
        "north" { Box ($c-$ah) ($face-$pr) $z0 ($c+$ah) $face $z1 $tex }
        "south" { Box ($c-$ah) (-$face) $z0 ($c+$ah) (-$face+$pr) $z1 $tex }
        "east"  { Box ($face-$pr) ($c-$ah) $z0 $face ($c+$ah) $z1 $tex }
        "west"  { Box (-$face) ($c-$ah) $z0 (-$face+$pr) ($c+$ah) $z1 $tex }
    }
}

# Engaged 2-story wall pilaster: stepped base at the floor, stepped capital +
# base around the balcony line, stepped capital at the ceiling, narrow shaft
# between. Each profile segment is { z0; z1; ah(=half-width); pr(=protrusion); tex }.
function WallPilaster([string]$side, [int]$c, [int]$face) {
    $prof = @(
        @{ z0=0;   z1=6;   ah=30; pr=14; tex=$TRIM },   # base step 1 (widest, floor)
        @{ z0=6;   z1=12;  ah=28; pr=13; tex=$TRIM },   # base step 2
        @{ z0=12;  z1=18;  ah=24; pr=11; tex=$TRIM },   # base step 3
        @{ z0=18;  z1=108; ah=20; pr=8;  tex=$WALL },   # lower shaft
        @{ z0=108; z1=114; ah=24; pr=11; tex=$TRIM },   # ground capital step
        @{ z0=114; z1=120; ah=28; pr=13; tex=$TRIM },   # ground capital step
        @{ z0=120; z1=136; ah=30; pr=14; tex=$TRIM },   # balcony band (widest)
        @{ z0=136; z1=142; ah=28; pr=13; tex=$TRIM },   # upper base step
        @{ z0=142; z1=148; ah=24; pr=11; tex=$TRIM },   # upper base step
        @{ z0=148; z1=254; ah=20; pr=8;  tex=$WALL },   # upper shaft
        @{ z0=254; z1=260; ah=24; pr=11; tex=$TRIM },   # capital step
        @{ z0=260; z1=266; ah=28; pr=13; tex=$TRIM },   # capital step
        @{ z0=266; z1=272; ah=30; pr=14; tex=$TRIM }    # capital step (widest, ceiling)
    )
    $b = @()
    foreach ($s in $prof) { $b += ,(PilBox $side $c $s.ah $s.pr $s.z0 $s.z1 $s.tex $face) }
    ,$b
}

# Wall-relative box: along [a0,a1], depth [d0,d1] from the inner face, z [z0,z1].
# side picks the wall; face is the inner-face magnitude; depth goes into the wall.
function WBox([string]$side, [int]$face, [int]$a0, [int]$a1, [int]$d0, [int]$d1, [int]$z0, [int]$z1, [string]$tex) {
    switch ($side) {
        "north" { Box $a0 ($face+$d0) $z0 $a1 ($face+$d1) $z1 $tex }
        "south" { Box $a0 (-$face-$d1) $z0 $a1 (-$face-$d0) $z1 $tex }
        "east"  { Box ($face+$d0) $a0 $z0 ($face+$d1) $a1 $z1 $tex }
        "west"  { Box (-$face-$d1) $a0 $z0 (-$face-$d0) $a1 $z1 $tex }
    }
}

# Wall-relative point (along, depth-from-face, z) -> world.
function WPt([string]$side, [int]$face, [int]$along, [int]$d, [int]$z) {
    switch ($side) {
        "north" { @($along, ($face+$d), $z) }
        "south" { @($along, (-$face-$d), $z) }
        "east"  { @(($face+$d), $along, $z) }
        "west"  { @((-$face-$d), $along, $z) }
    }
}

# Extrusion vector that pushes a niche filler from the face into the wall.
function NicheExtrude([string]$side, [int]$recess) {
    switch ($side) {
        "north" { @(0, $recess, 0) }
        "south" { @(0, (-$recess), 0) }
        "east"  { @($recess, 0, 0) }
        "west"  { @((-$recess), 0, 0) }
    }
}

# Build one wall (one z-band) from a feature list. Each feature is a hashtable:
#   @{ kind="door"|"square"|"pointed"; c=center; hw=halfWidth; z0=..; z1=..; zs=shoulder(pointed); recess=.. }
# Solid wall fills the gaps between features. Recesses leave the front empty with a back panel.
function NicheWall([string]$side, [int]$face, [int]$aMin, [int]$aMax, [int]$base, [int]$top, [int]$thick, $features) {
    $b = @()
    $cursor = $aMin
    foreach ($f in ($features | Sort-Object { $_.c })) {
        $s0 = $f.c - $f.hw; $s1 = $f.c + $f.hw
        if ($s0 -gt $cursor) { $b += ,(WBox $side $face $cursor $s0 0 $thick $base $top $WALL) }
        switch ($f.kind) {
            "door" {
                if ($f.z0 -gt $base) { $b += ,(WBox $side $face $s0 $s1 0 $thick $base $f.z0 $WALL) }
                $b += ,(WBox $side $face $s0 $s1 0 $thick $f.z1 $top $TRIM)        # lintel
            }
            "square" {
                $b += ,(WBox $side $face $s0 $s1 0 $thick $base $f.z0 $WALL)         # below
                $b += ,(WBox $side $face $s0 $s1 0 $thick $f.z1 $top $WALL)          # above
                $b += ,(WBox $side $face $s0 $s1 $f.recess $thick $f.z0 $f.z1 $ACCENT) # back panel (accent)
            }
            "pointed" {
                $b += ,(WBox $side $face $s0 $s1 0 $thick $base $f.z0 $WALL)         # sill
                $b += ,(WBox $side $face $s0 $s1 0 $thick $f.z1 $top $WALL)          # above apex
                $b += ,(WBox $side $face $s0 $s1 $f.recess $thick $f.z0 $f.z1 $ACCENT) # back panel (accent)
                $e = NicheExtrude $side $f.recess
                $lA = WPt $side $face ($f.c-$f.hw) 0 $f.zs; $lB = WPt $side $face $f.c 0 $f.z1; $lC = WPt $side $face ($f.c-$f.hw) 0 $f.z1
                $rA = WPt $side $face ($f.c+$f.hw) 0 $f.zs; $rB = WPt $side $face $f.c 0 $f.z1; $rC = WPt $side $face ($f.c+$f.hw) 0 $f.z1
                foreach ($fp in @( (TriPrism $lA $lB $lC $e $ACCENT), (TriPrism $rA $rB $rC $e $ACCENT) )) { $b += ,$fp }
            }
        }
        $cursor = $s1
    }
    if ($cursor -lt $aMax) { $b += ,(WBox $side $face $cursor $aMax 0 $thick $base $top $WALL) }
    ,$b
}

# Double-precision wall-relative point at the face (protrusion is via the extrude vector).
function WPtD([string]$side, [int]$face, [double]$along, [double]$z) {
    switch ($side) {
        "north" { @($along, $face, $z) }
        "south" { @($along, (-$face), $z) }
        "east"  { @($face, $along, $z) }
        "west"  { @((-$face), $along, $z) }
    }
}

# Extrusion that pushes trim out of the face into the room.
function ProtrudeE([string]$side, [int]$proj) {
    switch ($side) {
        "north" { @(0, (-$proj), 0) }
        "south" { @(0, $proj, 0) }
        "east"  { @((-$proj), 0, 0) }
        "west"  { @($proj, 0, 0) }
    }
}

# Two slim molding bars tracing the pointed arch, offset perpendicular to the slope.
function ArchMoldingWall([string]$side, [int]$face, [int]$c, [int]$hw, [int]$zs, [int]$z1, [int]$proj, [int]$fw) {
    $dz = $z1 - $zs
    $L = [math]::Sqrt(($hw * $hw) + ($dz * $dz))
    $oa = $fw * $dz / $L      # perpendicular offset along the wall
    $oz = $fw * $hw / $L      # perpendicular offset in z
    $e = ProtrudeE $side $proj
    $lInLow  = WPtD $side $face ($c-$hw) $zs;        $lInHigh = WPtD $side $face $c $z1
    $lOutHigh = WPtD $side $face ($c-$oa) ($z1+$oz); $lOutLow = WPtD $side $face ($c-$hw-$oa) ($zs+$oz)
    $rInLow  = WPtD $side $face ($c+$hw) $zs;        $rInHigh = WPtD $side $face $c $z1
    $rOutHigh = WPtD $side $face ($c+$oa) ($z1+$oz); $rOutLow = WPtD $side $face ($c+$hw+$oa) ($zs+$oz)
    @( (QuadPrism $lInLow $lInHigh $lOutHigh $lOutLow $e $TRIM),
       (QuadPrism $rInLow $rInHigh $rOutHigh $rOutLow $e $TRIM) )
}

# 4x4 raised border around a niche: sill + jambs, plus a flat header (square)
# or arch molding (pointed). proj = protrusion into the room, fw = border width.
function FrameWall([string]$side, [int]$face, $f, [int]$proj = 4, [int]$fw = 4) {
    $c = $f.c; $hw = $f.hw
    $b = @()
    $b += ,(WBox $side $face ($c-$hw-$fw) ($c+$hw+$fw) (-$proj) 0 ($f.z0-$fw) $f.z0 $TRIM)  # sill
    if ($f.kind -eq "square") {
        $b += ,(WBox $side $face ($c-$hw-$fw) ($c-$hw) (-$proj) 0 $f.z0 $f.z1 $TRIM)        # left jamb
        $b += ,(WBox $side $face ($c+$hw) ($c+$hw+$fw) (-$proj) 0 $f.z0 $f.z1 $TRIM)        # right jamb
        $b += ,(WBox $side $face ($c-$hw-$fw) ($c+$hw+$fw) (-$proj) 0 $f.z1 ($f.z1+$fw) $TRIM) # header
    } else {
        $b += ,(WBox $side $face ($c-$hw-$fw) ($c-$hw) (-$proj) 0 $f.z0 $f.zs $TRIM)         # left jamb
        $b += ,(WBox $side $face ($c+$hw) ($c+$hw+$fw) (-$proj) 0 $f.z0 $f.zs $TRIM)         # right jamb
        foreach ($fp in (ArchMoldingWall $side $face $c $hw $f.zs $f.z1 $proj $fw)) { $b += ,$fp }
    }
    ,$b
}

# Solid stepped staircase rising in +Y from z=0 to zTop across [x0,x1].
function StairY([int]$x0, [int]$x1, [int]$yStart, [int]$yEnd, [int]$zTop, [int]$nsteps) {
    $run = [int](($yEnd - $yStart) / $nsteps)
    $rise = [int]($zTop / $nsteps)
    $b = @()
    for ($i = 0; $i -lt $nsteps; $i++) {
        $y0 = $yStart + ($run * $i)
        $y1 = $yStart + ($run * ($i + 1))
        $z1 = $rise * ($i + 1)
        $b += ,(Box $x0 $y0 0 $x1 $y1 $z1 $FLOOR)
    }
    ,$b
}
