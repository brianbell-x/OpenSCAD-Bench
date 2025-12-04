/*
Headphone Hook Clamp for 25mm Desk

- Desk thickness: param desk_thickness (default 25 mm)
- Friction-fit C-clamp, no screws
- Hanger extends ~50 mm from desk
- Curved cylindrical hanger to avoid headband creasing
- Minimum wall thickness 4 mm
*/

desk_thickness   = 25;   // actual desk thickness
clamp_clearance  = 0.6;  // extra space over desk_thickness; tweak for your printer
wall_thickness   = 4;    // minimum wall thickness
arm_depth        = 25;   // how far the clamp wraps over/under the desk edge
hanger_length    = 50;   // how far the headphone hanger sticks out from the desk
hanger_radius    = 15;   // curvature radius for hanger (~30mm wide contact area)

$fn = 64;

// Main C-shaped clamp body
module clamp_body() {
    width      = 2 * hanger_radius;  // width along the desk edge, matches hanger width
    gap_half   = (desk_thickness + clamp_clearance) / 2;
    outer_half = gap_half + wall_thickness;

    difference() {
        // Outer C-clamp shell.
        // Backplate is at x in [-wall_thickness, 0].
        // Desk outer face will sit at x = 0.
        translate([-wall_thickness, -outer_half, -width/2])
            cube([wall_thickness + arm_depth, 2 * outer_half, width]);

        // Inner void where the desk goes (open on the arm side).
        // This forms the "C" shape: top and bottom lips plus backplate.
        translate([0, -gap_half, -width/2 - 1])
            cube([arm_depth + 1, 2 * gap_half, width + 2]);
    }
}

// Curved headphone hanger
module hanger() {
    R       = hanger_radius;
    len     = hanger_length;
    width   = 2 * R;

    gap_half   = (desk_thickness + clamp_clearance) / 2;
    outer_half = gap_half + wall_thickness;

    // Place hanger just below the bottom of the clamp
    // Clamp bottom is at y = -outer_half
    top_y = -outer_half - 1; // 1 mm clearance below clamp
    dy    = top_y - R;       // segment we keep is y in [0, R], so shift so top (R) -> top_y

    // Attach to the outside of the backplate:
    // backplate outer face is at x = -wall_thickness
    translate([-wall_thickness - len, dy, 0])
    intersection() {
        // Full round bar, axis along X
        rotate([0, 90, 0])
            cylinder(h = len, r = R, center = false);

        // Keep only the top half (y â [0, R]) so the top is nicely curved
        // and the bottom is flattened for strength.
        translate([-1, 0, -R - 1])
            cube([len + 2, R + 1, 2 * R + 2]);
    }
}

// Assembly
module headphone_hook_clamp() {
    union() {
        clamp_body();
        hanger();
    }
}

// Render final part
headphone_hook_clamp();