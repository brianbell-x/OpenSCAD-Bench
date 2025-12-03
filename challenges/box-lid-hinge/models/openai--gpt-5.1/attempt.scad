//
// Simple 20mm-wide box hinge for 3mm walls
// - Print-in-place, with integrated pin
// - Designed for M3 mounting screws
// - For 3mm wall thickness
//

$fn = 64;

// =================== Parameters ===================
leaf_thickness     = 3;      // matches 3mm wall
hinge_width        = 20;     // total hinge width along X
leaf_depth         = 12;     // how far each leaf extends from hinge axis along Y

knuckle_diameter   = 6;      // outer diameter of knuckles
pin_diameter       = 2;      // internal pin diameter (fits 1.75mm filament if you drill it out)
clearance          = 0.25;   // radial clearance between pin and rotating knuckle (print tolerance)
plate_clearance    = 0.30;   // clearance between leaves around hinge axis (for rotation)

center_len         = 6;      // length of center knuckle segment along X
center_gap         = 0.30;   // axial gap between center & outer knuckles along X
edge_clear         = 0.40;   // nominal free margin from knuckles to the hinge outer edge

// Mounting holes (M3)
hole_diameter      = 3.2;    // clearance for M3 screw
hole_spacing       = 12;     // spacing between two holes on each leaf, along X
hole_offset_factor = 0.60;   // fraction of leaf_depth for hole position along Y

// =================== Derived values ===================
knuckle_r = knuckle_diameter / 2;
pin_r     = pin_diameter / 2;
hole_r    = hole_diameter / 2;

// Outer knuckle length so everything fits into hinge_width
outer_len = (hinge_width - 2*edge_clear - center_len - 2*center_gap) / 2;

// X-offset of outer knuckles from center
x_outer   = center_len/2 + center_gap/2 + outer_len/2;

// Y offset of mounting holes on each leaf
hole_offset_y = leaf_depth * hole_offset_factor;


// =================== Main assembly ===================
hinge();

module hinge() {
    difference() {
        union() {
            top_leaf();      // lid side
            bottom_leaf();   // box side
        }
        mounting_holes();    // through-holes for M3 screws
    }
}


// =================== Leaf definitions ===================

// Top (Y > 0) leaf with integrated pin & two outer knuckles
module top_leaf() {
    union() {
        // Top plate with circular relief at the hinge axis
        difference() {
            plate_top();
            relief_cut();
        }

        // Pin + two outer knuckles
        pin_and_outer_knuckles();
    }
}

// Bottom (Y < 0) leaf with single center knuckle
module bottom_leaf() {
    union() {
        // Bottom plate with circular relief at the hinge axis
        difference() {
            plate_bottom();
            relief_cut();
        }

        // Center knuckle with clearance around the pin
        inner_center_knuckle();
    }
}


// =================== Geometry building blocks ===================

module plate_top() {
    // Rectangular plate, top side (Y >= 0)
    translate([-hinge_width/2, 0, 0])
        cube([hinge_width, leaf_depth, leaf_thickness], center = false);
}

module plate_bottom() {
    // Rectangular plate, bottom side (Y <= 0)
    translate([-hinge_width/2, -leaf_depth, 0])
        cube([hinge_width, leaf_depth, leaf_thickness], center = false);
}

// Circular relief cut in the plates around the hinge axis
module relief_cut() {
    translate([0, 0, -0.1])
        cylinder(h = leaf_thickness + 0.2,
                 r = knuckle_r + plate_clearance,
                 center = false);
}

// Integrated pin + two outer knuckles (attached to top leaf)
module pin_and_outer_knuckles() {
    // Central pin
    translate([0, 0, 0])
        cylinder(h = leaf_thickness, r = pin_r, center = false);

    // Left outer knuckle segment
    knuckle_segment(x_center = -x_outer,
                    len      = outer_len,
                    r_outer  = knuckle_r);

    // Right outer knuckle segment
    knuckle_segment(x_center =  x_outer,
                    len      = outer_len,
                    r_outer  = knuckle_r);
}

// Inner center knuckle (attached to bottom leaf, rotating on pin)
module inner_center_knuckle() {
    difference() {
        // Solid center knuckle segment
        knuckle_segment(x_center = 0,
                        len      = center_len,
                        r_outer  = knuckle_r);

        // Bore for pin + clearance (for rotation)
        translate([0, 0, -0.1])
            cylinder(h = leaf_thickness + 0.2,
                     r = pin_r + clearance,
                     center = false);
    }
}

// Knuckle segment along X, cut from a full cylinder
module knuckle_segment(x_center, len, r_outer) {
    intersection() {
        // Full cylinder around Z axis
        translate([0, 0, 0])
            cylinder(h = leaf_thickness, r = r_outer, center = false);

        // Limiting block to define length along X
        translate([x_center - len/2, -r_outer - 1, -0.1])
            cube([len, 2*(r_outer + 1), leaf_thickness + 0.2], center = false);
    }
}

// Through-holes for mounting screws (M3)
module mounting_holes() {
    for (leaf_sign = [-1, 1])      // -1 = bottom, +1 = top
        for (xpos = [-hole_spacing/2, hole_spacing/2])
            translate([xpos,
                       leaf_sign * hole_offset_y,
                       -1])
                cylinder(h = leaf_thickness + 2,
                         r = hole_r,
                         center = false);
}