// ========================================================
// Toroidal 3âblade propeller
// ========================================================

$fn = 80;  // global resolution

// ---------------- Parameters ----------------
hub_d  = 15;   // hub outer diameter
hub_h  = 10;   // hub height
hole_d = 5;    // mounting hole diameter

blade_loop_outer_d    = 50;  // each loop outer diameter
blade_band_width      = 12;  // vertical width of band
blade_band_thickness  = 2;   // radial thickness of band
blade_arc_deg         = 340; // loop coverage (330â350Â° requested)
blade_pitch_height    = 15;  // rise from start to end of loop (helical pitch)

// ---------------- Modules -------------------

// Central hub with mounting throughâhole
module hub() {
    difference() {
        cylinder(d = hub_d, h = hub_h);
        translate([0,0,hub_h/2])
            cylinder(d = hole_d, h = hub_h + 4, center = true);
    }
}

// One toroidal blade, initially oriented along +X
module toroidal_blade() {
    outer_r   = blade_loop_outer_d / 2;
    thickness = blade_band_thickness;
    height    = blade_band_width;
    pitch     = blade_pitch_height;

    inner_r = outer_r - thickness;
    r_mid   = (outer_r + inner_r) / 2;  // radius of band centerline

    gap_deg = 360 - blade_arc_deg; // missing section of loop (opening near hub)
    steps   = 80;                  // more steps = smoother band

    union() {
        // Build helical band as chained hulls of small rectangular sections
        for (i = [0 : steps - 1]) {
            frac0 = i / steps;
            frac1 = (i + 1) / steps;

            ang0 = 180 + gap_deg/2 + frac0 * blade_arc_deg;
            ang1 = 180 + gap_deg/2 + frac1 * blade_arc_deg;

            z0 = pitch * frac0;
            z1 = pitch * frac1;

            hull() {
                blade_section(ang0, z0, outer_r, r_mid, thickness, height);
                blade_section(ang1, z1, outer_r, r_mid, thickness, height);
            }
        }
    }
}

// Crossâsection of the blade band at a given angle around its own loop center
module blade_section(theta, z_off, loop_offset, r_mid, thickness, height) {
    tangential_len = 2;               // small; hull between sections smooths band
    center_z       = hub_h/2 + z_off; // roughly centered on hub and rising by pitch

    translate([0, 0, center_z])           // vertical placement
        translate([loop_offset, 0, 0])    // move loop center away from hub axis
            rotate([0, 0, theta])        // angle around loop center
                translate([r_mid, 0, 0]) // radius from loop center
                    cube([thickness, tangential_len, height], center = true);
}

// Complete 3âblade toroidal propeller
module toroidal_propeller() {
    union() {
        hub();
        // Three identical blades 120Â° apart
        for (rot = [0, 120, 240])
            rotate([0, 0, rot]) toroidal_blade();
    }
}

// -------- Render --------
toroidal_propeller();