//
// Simple twoâpart hinge for 3â¯mm box walls
// - Hinge length (along axis): ~20â¯mm
// - Mounting plate thickness: 3â¯mm (for 3â¯mm walls)
// - Uses 1.75â¯mm filament as a pin (or similar)
// - Two leaf parts are generated sideâbyâside for printing
//

////////////////////
// USER PARAMETERS
////////////////////

hinge_length      = 20;     // total hinge width along the axis (mm)
wall_thickness    = 3;      // plate thickness, matches 3 mm wall
leaf_depth        = 15;     // plate depth from hinge barrel (mm)

screw_diameter    = 3.2;    // through-hole for M3 screw (slight clearance)
barrel_outer_diam = 6;      // outside diameter of hinge barrel (mm)
pin_diameter      = 1.8;    // filament pin diameter (for 1.75 mm filament)
axial_gap         = 0.4;    // gap between knuckle segments along axis (mm)

$fn = 64; // smoothness for cylinders


////////////////////
// DERIVED VALUES
////////////////////

barrel_r        = barrel_outer_diam / 2;
pin_clearance   = 0.2;              // radial clearance between pin & barrel
barrel_inner_r  = pin_diameter/2 + pin_clearance;
screw_r         = screw_diameter / 2;

// Three knuckles total across the 20 mm length:
// pattern: [segment, gap, segment, gap, segment]
segment_len = (hinge_length - 2*axial_gap) / 3;

// helpers for axial positioning
function seg_start(i) = i*segment_len + (i > 0 ? i*axial_gap : 0);
function seg_end(i)   = seg_start(i) + segment_len;


////////////////////
// MAIN CALL
////////////////////

hinge_pair();   // Comment this out and call hinge_leaf() manually if desired.


////////////////////
// TOP-LEVEL ASSEMBLY
////////////////////

// Generates both hinge leaves spaced apart for printing.
module hinge_pair() {
    // Leaf A: center knuckle only
    hinge_leaf("A");

    // Leaf B: two outer knuckles
    translate([0, leaf_depth + 10, 0])   // move away in Y so parts don't touch
        hinge_leaf("B");
}


////////////////////
// LEAF MODULE
////////////////////

// pattern "A": center knuckle   (middle segment only)
// pattern "B": outer knuckles   (first and third segments)
module hinge_leaf(pattern = "A") {
    difference() {
        union() {
            // Mounting plate
            cube([hinge_length, leaf_depth, wall_thickness], center = false);

            // Hinge barrel knuckles
            if (pattern == "A") {
                // center segment only
                barrel_segment(seg_start(1), seg_end(1));
            } else { // "B"
                // two outer segments
                barrel_segment(seg_start(0), seg_end(0));
                barrel_segment(seg_start(2), seg_end(2));
            }
        }

        // Screw holes (two per leaf)
        screw_y = leaf_depth * 0.6;
        for (x_pos = [hinge_length * 0.3, hinge_length * 0.7]) {
            translate([x_pos, screw_y, -0.1])      // start slightly below plate
                cylinder(h = wall_thickness + 0.4,
                         r = screw_r,
                         center = false,
                         $fn = 32);
        }
    }
}


////////////////////
// BARREL SEGMENTS
////////////////////

// Single hollow knuckle from x_start to x_end.
module barrel_segment(x_start, x_end) {
    len = x_end - x_start;
    translate([x_start + len/2, 0, barrel_r])   // center at z = barrel_r
        rotate([0, 90, 0])                     // axis along X
            difference() {
                // outer barrel surface
                cylinder(h = len, r = barrel_r, center = true);

                // inner pin hole
                cylinder(h = len + 0.4,
                         r = barrel_inner_r,
                         center = true);
            }
}