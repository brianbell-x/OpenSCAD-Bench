//
// L-shaped mounting bracket with counterbored holes
// All units in mm
//

$fn = 64;  // smooth cylinders

//--------------------
// USER PARAMETERS
//--------------------

// Overall sizes
leg1_length  = 80;   // Leg on XY plane (length in X)
leg2_height  = 80;   // Vertical leg on XZ plane (height in Z)
leg_width    = 30;   // Depth in Y (common to both legs)
thickness    = 4;    // Bracket wall thickness

// Hole specs
hole_d_through   = 4.0;  // Through-hole diameter
hole_d_c'bore    = 8.0;  // Counterbore diameter
c'bore_depth     = 2.0;  // Counterbore depth

//----------------------------
// HOLE PATTERN DEFINITIONS
//----------------------------
//
// Define your exact hole pattern here, based on your drawing.
//
// Leg 1: lies in XY plane, thickness along +Z.
//   Coordinates: [x, y], measured from the inside bend corner
//   at (x=0, y=0). Z is through the thickness.
//
// Leg 2: lies in XZ plane, thickness along +X.
//   Coordinates: [z, y], measured from the inside bend corner
//   at (z=0, y=0). X is through the thickness.
//
// Replace these example patterns with your real ones.
//

// Example: three holes on leg 1 (XY)
leg1_holes_xy = [
    [20, 10],
    [40, 10],
    [60, 10]
];

// Example: three holes on leg 2 (XZ)
leg2_holes_zy = [
    [20, 10],
    [40, 10],
    [60, 10]
];

//--------------------
// MAIN
//--------------------

bracket();

module bracket() {
    difference() {
        // Solid L-bracket
        bracket_solid();

        // Subtract all holes (through + counterbore)
        leg1_hole_pattern();
        leg2_hole_pattern();
    }
}

//--------------------
// GEOMETRY
//--------------------

// Solid L geometry (union of two overlapping plates).
module bracket_solid() {
    union() {
        // Leg 1: XY plate, thickness in +Z
        translate([0, 0, 0])
            cube([leg1_length, leg_width, thickness], center=false);

        // Leg 2: vertical plate in XZ, thickness in +X
        // Shares the inside edge at x=0 with leg 1 at z=0.
        translate([0, 0, 0])
            cube([thickness, leg_width, leg2_height], center=false);
    }
}

//--------------------
// HOLES - LEG 1 (XY)
//--------------------
//
// Through-holes normal to Z, counterbore on top (Z+ side).
//
module leg1_hole_pattern() {
    for (p = leg1_holes_xy) {
        x = p[0];
        y = p[1];
        leg1_hole(x, y);
    }
}

module leg1_hole(x, y) {
    // Through hole
    translate([x, y, -0.1])  // small extra to ensure clean boolean
        cylinder(h = thickness + 0.2, d = hole_d_through, center=false);

    // Counterbore (top side, Z+)
    translate([x, y, thickness - c'bore_depth])
        cylinder(h = c'bore_depth + 0.2, d = hole_d_c'bore, center=false);
}

//--------------------
// HOLES - LEG 2 (XZ)
//--------------------
//
// Through-holes normal to X, counterbore on +X side.
//
module leg2_hole_pattern() {
    for (p = leg2_holes_zy) {
        z = p[0];
        y = p[1];
        leg2_hole(z, y);
    }
}

module leg2_hole(z, y) {
    // Through hole in +X direction
    translate([-0.1, y, z])  // extend 0.1 outside for clean boolean
        rotate([0, 90, 0])   // align cylinder along +X
            cylinder(h = thickness + 0.2, d = hole_d_through, center=false);

    // Counterbore on +X side
    translate([0, y, z])
        rotate([0, 90, 0])
            cylinder(h = c'bore_depth + 0.2, d = hole_d_c'bore, center=false);
}