//
// Ergonomic Tool Handle Grip
// NOTE: Dimensions are reasonable placeholders.
//       Adjust values marked "TODO: tune from reference.png" to match your drawing.
//

// ----------------------------
// Global quality / units
// ----------------------------
$fn = 64;  // smoothness of curves

// ----------------------------
// Key dimensional parameters
// ----------------------------

// Overall handle length
handle_len = 90;              // ~90 mm total length

// Axial positions of cross-sections (from base toward tip)
z_A = 0;
z_B = 30;                     // TODO: tune from reference.png
z_C = 60;                     // TODO: tune from reference.png
z_D = handle_len;

// Section A: rounded rectangle at base
w_A   = 32;                   // overall width  (X)  - TODO: tune
h_A   = 26;                   // overall height (Y)  - TODO: tune
r_A   = 5;                    // corner radius       - TODO: tune

// Section B: ellipse
rx_B  = 14;                   // semi-major radius X - TODO: tune
ry_B  = 13;                   // semi-minor radius Y - TODO: tune

// Section C: circle + thumb bump
rC_base      = 11;            // base circular radius  - TODO: tune
rC_bump      = 4.5;           // radius of thumb bump  - TODO: tune
bump_offsetY = 8;             // bump center offset Y  - TODO: tune

// Section D: circular tip
r_D = 9;                      // radius at tip         - TODO: tune


// ----------------------------
// 2D cross-section profiles
// (All centered at origin in XY)
// ----------------------------

module profile_A_rounded_rect(w, h, r) {
    // Centered rounded rectangle using offset
    // Ensures manifold, 2D closed profile.
    offset(r = r)
        square([w - 2*r, h - 2*r], center = true);
}

module profile_B_ellipse(rx, ry) {
    scale([rx, ry, 1])
        circle(1);
}

module profile_C_thumb_circle(r_base, r_bump, bump_y) {
    union() {
        circle(r_base);
        // Thumb bump on "top" side ( +Y direction )
        translate([0, bump_y])
            circle(r_bump);
    }
}

module profile_D_circle(r) {
    circle(r);
}


// ----------------------------
// 3D handle construction
// ----------------------------

// Hull between two 2D profiles placed at different Z
module loft_between(z1, shape1, z2, shape2) {
    hull() {
        translate([0, 0, z1]) children(shape1);
        translate([0, 0, z2]) children(shape2);
    }
}

// Wrapper modules so they can be referenced as children indices
module section_A() profile_A_rounded_rect(w_A, h_A, r_A);
module section_B() profile_B_ellipse(rx_B, ry_B);
module section_C() profile_C_thumb_circle(rC_base, rC_bump, bump_offsetY);
module section_D() profile_D_circle(r_D);


// Main handle geometry
module ergonomic_handle() {
    union() {
        // Smooth transition A â B
        loft_between(z_A, 0, z_B, 1)
            { section_A(); section_B(); }

        // Smooth transition B â C (introduces thumb bump)
        loft_between(z_B, 0, z_C, 1)
            { section_B(); section_C(); }

        // Smooth transition C â D (fades out thumb bump toward tip)
        loft_between(z_C, 0, z_D, 1)
            { section_C(); section_D(); }
    }
}

// ----------------------------
// Orientation helper (optional)
// ----------------------------
// Rotate the handle so Z is along its length; adjust if desired.
module oriented_handle() {
    // As modeled, Z is already along the handle axis.
    // You can rotate for printing, e.g. lay on side:
    // rotate([90, 0, 0]) ergonomic_handle();
    ergonomic_handle();
}

// ----------------------------
// Render
// ----------------------------
oriented_handle();