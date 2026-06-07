<#
  Blackspire room compositor (EXPERIMENTAL — evaluating the approach).

  A room is a turtle walk around its perimeter: an ordered list of `bay` panels
  and `corner` turns. The footprint falls out of the walk. Panels are ORIENTABLE
  (placed at any position + heading via a local frame), so the same pieces will
  work on straight or, later, diagonal walls.

  Convention: the walk goes counter-clockwise, interior on the turtle's LEFT, so
  inward = leftOf(heading). Reuses primitives from Mapkit.ps1 (Box, QuadPrism,
  Connector, Assemble).

  A panel is `function Panel-<Kind>($origin,$along,$inward,$cfg)` returning
  @{ b = <brushes>; e = <entities> }. Add a kind = add a function. That's the bet.
#>

# --- 2D turtle math (XY plane; Z is per-panel) -------------------------------
function Rot2([double]$x, [double]$y, [int]$deg) {
    switch (((($deg % 360) + 360) % 360)) {
        0   { @($x, $y) }
        90  { @((-$y), $x) }
        180 { @((-$x), (-$y)) }
        270 { @($y, (-$x)) }
        default {
            $r = $deg * [math]::PI / 180.0
            $c = [math]::Cos($r); $s = [math]::Sin($r)
            @((($x*$c)-($y*$s)), (($x*$s)+($y*$c)))
        }
    }
}
function LeftOf($dir) { Rot2 $dir[0] $dir[1] 90 }   # interior is on the turtle's left

# World point from panel-local coords: u along the wall, d into the wall from the
# face, z up. Depth goes opposite the inward normal (wall material is behind the face).
function PanelPt($origin, $along, $inward, [double]$u, [double]$d, [double]$z) {
    @( ($origin[0] + ($along[0]*$u) - ($inward[0]*$d)),
       ($origin[1] + ($along[1]*$u) - ($inward[1]*$d)),
       $z )
}

# A rectangular wall slab (panel-local box) as one oriented brush.
function PanelSlab($origin, $along, $inward, [double]$u0, [double]$u1, [double]$d0, [double]$d1, [double]$z0, [double]$z1, [string]$tex) {
    $A = PanelPt $origin $along $inward $u0 $d0 $z0
    $B = PanelPt $origin $along $inward $u1 $d0 $z0
    $C = PanelPt $origin $along $inward $u1 $d0 $z1
    $D = PanelPt $origin $along $inward $u0 $d0 $z1
    $e = @( (-$inward[0]*($d1-$d0)), (-$inward[1]*($d1-$d0)), 0 )
    QuadPrism $A $B $C $D $e $tex
}

# --- Panels ------------------------------------------------------------------

# Blank wall: one solid bay, full height.
function Panel-Wall($origin, $along, $inward, $cfg) {
    $b = @()
    $b += ,(PanelSlab $origin $along $inward 0 $cfg.bay 0 $cfg.thick 0 $cfg.height $WALL)
    @{ b = $b; e = @() }
}

# Plain door: two jambs + a lintel, with a room_connector facing out of the room.
function Panel-Door($origin, $along, $inward, $cfg) {
    $W = $cfg.bay; $T = $cfg.thick; $H = $cfg.height; $dw = $cfg.doorW; $dh = $cfg.doorH
    $j = ($W - $dw) / 2.0
    $b = @()
    $b += ,(PanelSlab $origin $along $inward 0 $j 0 $T 0 $H $WALL)            # left jamb
    $b += ,(PanelSlab $origin $along $inward ($W-$j) $W 0 $T 0 $H $WALL)      # right jamb
    $b += ,(PanelSlab $origin $along $inward $j ($W-$j) 0 $T $dh $H $TRIM)    # lintel

    $cx = $origin[0] + ($along[0] * ($W/2.0))
    $cy = $origin[1] + ($along[1] * ($W/2.0))
    $ang = ([int][math]::Round((([math]::Atan2((-$inward[1]), (-$inward[0])) * 180.0 / [math]::PI) + 360.0))) % 360
    $e = @()
    $e += ,(Connector ([int][math]::Round($cx)) ([int][math]::Round($cy)) 16 $ang "door" "crypt standard")
    @{ b = $b; e = $e }
}

# Framed door: jambs + lintel as Panel-Door, plus protruding frame with
# side pilasters, a horizontal mantle, and a triangular pediment above.
function Panel-DoorFramed($origin, $along, $inward, $cfg) {
    $W = $cfg.bay; $T = $cfg.thick; $H = $cfg.height
    $dw = $cfg.doorW; $dh = $cfg.doorH
    $j     = ($W - $dw) / 2.0  # jamb half-width
    $pw    = 8                  # pilaster width (u)
    $fp    = 4                  # pilaster protrusion
    $ffp   = 8                  # frame protrusion: capitol, mantle, rakes (fp+4)
    $ch    = 8                  # capitol height above door top  (capTop = dh+ch)
    $ph    = 16                 # pilaster height above door top (pilTop = dh+ph, taller than capitol)
    $cext  = 4                  # capitol extends this many u beyond pilaster outer (each side)
    $mh    = 4                  # mantle cap height (z)
    $mext  = 4                  # mantle extends this many u beyond capitol (each side)
    $mfp   = 4                  # mantle extra protrusion beyond fp
    $pedH  = 16                 # pediment rise from mantle top to apex

    # Derived z levels
    $capTop = [double]($dh + $ch)           # top of capitol block     (e.g. 76)
    $pilTop = [double]($dh + $ph)           # top of pilasters         (e.g. 84)
    $manTop = [double]($capTop + $mh)       # top of mantle cap
    $zApex  = [double]($pilTop + $pedH)     # pediment apex (rakes start at pilTop)

    # Derived u extents
    $uOL  = [double]($j - $pw)             # pilaster outer left  (e.g. 32)
    $uOR  = [double]($W - $j + $pw)        # pilaster outer right (e.g. 96)
    $uCL  = [double]($uOL - $cext)         # capitol left         (e.g. 28)
    $uCR  = [double]($uOR + $cext)         # capitol right        (e.g. 100)
    $uML  = [double]($uCL - $mext)         # mantle left          (e.g. 24)
    $uMR  = [double]($uCR + $mext)         # mantle right         (e.g. 104)
    $uAp  = [double]($W / 2.0)             # apex centre          (e.g. 64)

    $pedE = @( (-$inward[0]*$fp), (-$inward[1]*$fp), 0 )
    $b    = @()

    # Wall: left jamb, right jamb, lintel
    $b += ,(PanelSlab $origin $along $inward 0       $j      0 $T 0   $H       $WALL)
    $b += ,(PanelSlab $origin $along $inward ($W-$j) $W      0 $T 0   $H       $WALL)
    $b += ,(PanelSlab $origin $along $inward $j      ($W-$j) 0 $T $dh $H       $TRIM)

    # Frame: pilasters — floor to pilTop, width pw, protrusion fp
    $b += ,(PanelSlab $origin $along $inward $uOL    $j      (-$fp) 0 0 $pilTop $TRIM)
    $b += ,(PanelSlab $origin $along $inward ($W-$j) $uOR    (-$fp) 0 0 $pilTop $TRIM)

    # Frame: capitol block — above door, cext wider each side, czext taller than pilasters
    $b += ,(PanelSlab $origin $along $inward $uCL $uCR (-$ffp) 0 $dh $capTop $TRIM)

    # Frame: mantle cap — mext wider each side than capitol, mfp deeper into room
    $b += ,(PanelSlab $origin $along $inward $uML $uMR (-($ffp+$mfp)) 0 $capTop $manTop $TRIM)

    # Frame: open pediment — two parallelogram rakes.
    # Outer base at pilaster outer edge (uOL/uOR); inner base at pilaster inner edge (j / W-j).
    # Both edges are parallel (same slope direction) so rake width is consistent.
    # Inner edges meet at innerApexZ; outer edges meet at zApex — small solid tip between them.
    $slopeU     = $uAp - $uOL
    $innerApexZ = [double]($pilTop + $pedH * (1.0 - $pw / $slopeU))

    # Left rake: outer-base, inner-base, inner-apex, outer-apex  (base at pilTop)
    $rA = PanelPt $origin $along $inward $uOL    (-$fp) $pilTop
    $rB = PanelPt $origin $along $inward $j      (-$fp) $pilTop
    $rC = PanelPt $origin $along $inward $uAp    (-$fp) $innerApexZ
    $rD = PanelPt $origin $along $inward $uAp    (-$fp) $zApex
    $b += ,(QuadPrism $rA $rB $rC $rD $pedE $TRIM)

    # Right rake: outer-base, inner-base, inner-apex, outer-apex  (base at pilTop)
    $rA = PanelPt $origin $along $inward $uOR    (-$fp) $pilTop
    $rB = PanelPt $origin $along $inward ($W-$j) (-$fp) $pilTop
    $rC = PanelPt $origin $along $inward $uAp    (-$fp) $innerApexZ
    $rD = PanelPt $origin $along $inward $uAp    (-$fp) $zApex
    $b += ,(QuadPrism $rA $rB $rC $rD $pedE $TRIM)

    # Room connector
    $cx  = $origin[0] + ($along[0] * ($W / 2.0))
    $cy  = $origin[1] + ($along[1] * ($W / 2.0))
    $ang = ([int][math]::Round((([math]::Atan2((-$inward[1]), (-$inward[0])) * 180.0 / [math]::PI) + 360.0))) % 360
    $ents = @()
    $ents += ,(Connector ([int][math]::Round($cx)) ([int][math]::Round($cy)) 16 $ang "door" "crypt standard")
    @{ b = $b; e = $ents }
}

# --- Joint: corner pilaster (square column at the turtle vertex) --------------
function Panel-CornerPilaster($pos, $cfg) {
    $pw = $cfg.pilaster
    $b = @()
    $b += ,(Box ([int]($pos[0]-$pw)) ([int]($pos[1]-$pw)) 0 ([int]($pos[0]+$pw)) ([int]($pos[1]+$pw)) $cfg.height $TRIM)
    ,$b
}

# --- Compositor: walk the perimeter, then fill floor + flat ceiling ----------
function Build-Room($cfg) {
    $pos = @([double]$cfg.start[0], [double]$cfg.start[1])
    $dir = @([double]$cfg.dir[0], [double]$cfg.dir[1])
    $b = @(); $e = @()
    $minx = $pos[0]; $maxx = $pos[0]; $miny = $pos[1]; $maxy = $pos[1]

    foreach ($step in $cfg.perimeter) {
        if ($step.op -eq "bay") {
            $inward = LeftOf $dir
            $r = & "Panel-$($step.kind)" $pos $dir $inward $cfg
            foreach ($br in $r.b) { $b += ,$br }
            foreach ($en in $r.e) { $e += ,$en }
            $pos = @( ($pos[0]+($dir[0]*$cfg.bay)), ($pos[1]+($dir[1]*$cfg.bay)) )
        }
        elseif ($step.op -eq "corner") {
            if ($step.turn -eq 90) {
                foreach ($br in (Panel-CornerPilaster $pos $cfg)) { $b += ,$br }
            }
            $dir = Rot2 $dir[0] $dir[1] $step.turn
        }
        if ($pos[0] -lt $minx) { $minx = $pos[0] }; if ($pos[0] -gt $maxx) { $maxx = $pos[0] }
        if ($pos[1] -lt $miny) { $miny = $pos[1] }; if ($pos[1] -gt $maxy) { $maxy = $pos[1] }
    }

    # Floor + flat ceiling spanning the footprint (extended under the walls).
    $T = $cfg.thick; $H = $cfg.height
    $b += ,(Box ([int]($minx-$T)) ([int]($miny-$T)) (-$T) ([int]($maxx+$T)) ([int]($maxy+$T)) 0 $FLOOR)
    $b += ,(Box ([int]($minx-$T)) ([int]($miny-$T)) $H ([int]($maxx+$T)) ([int]($maxy+$T)) ($H+$T) $TRIM)

    Assemble $b $e
}
