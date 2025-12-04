//
// Toroidal 3âblade propeller
// All dimensions in mm
//

// ---------- Global quality ----------
$fn = 80;          // cylinder smoothness
seg_step = 5;      // angular step (deg) for blade path sampling
                   // smaller = smoother, slower to render

// ---------- Parameters ----------
hub_od   = 15;     // outer diameter of hub
hub_h    = 10;     // hub height
hole_d   = 5;      // mounting hole diameter

blade_count      = 3;
blade_pitch_h    = 15;      // Z rise of loop from start to end
blade_arc_deg    = 340;     // loop arc (deg), <360 to leave a gap
band_width       = 12;      // vertical width of band
band_thickness   = 2;       // radial thickness of band
loop_outer_d     = 50;      // outer diameter of each toroidal loop

// Derived values
hub_r          = hub_od/2;
hole_r         = hole_d/2;
band_rad_half  = band_thickness/2;
loop_outer_r   = loop_outer_d/2;
ring_r0        = loop_outer_r - band_rad_half;      // path radius about loop center
blade_center_r = hub_r + ring_r0 + band_rad_half;   // distance hub->loop center

t_start = 180;                    // start angle (deg) around loop center
t_end   = t_start + blade_arc_deg;

// Center the band so it overlaps the hub midâheight
band_z_offset = hub_h/2;          // lower Z of hub is 0, upper is hub_h


// ---------- Main assembly ----------
propeller();

module propeller() {
    union() {
        hub();
        // three identical blades 120Â° apart
        for (i = [0:blade_count-1]) {
            rotate([0,0,120*i])
                blade_single();
        }
    }
}

// ---------- Hub with mounting hole ----------
module hub() {
    difference() {
        // solid hub
        cylinder(r = hub_r, h = hub_h);
        // through-hole
        translate([0,0,-1])
            cylinder(r = hole_r, h = hub_h + 2);
    }
}

// ---------- One toroidal blade ----------
module blade_single() {
    // Sweep a rectangular crossâsection along a helical arc
    for (t = [t_start:seg_step:t_end-seg_step]) {
        hull() {
            blade_slice(t);
            blade_slice(t + seg_step);
        }
    }
}

// Rectangular slice at parameter angle t (degrees) along the loop
module blade_slice(t) {
    // Parametric progress along arc (0 at start, 1 at end)
    u = (t - t_start) / (t_end - t_start);

    // Helical Z center of the band
    zc = band_z_offset + blade_pitch_h * u;

    // Centerline path of the band in XY (about the loop's own center)
    x = blade_center_r + ring_r0 * cos(t);
    y =                 ring_r0 * sin(t);

    // Approximate tangential length of the slice (for better overlap)
    seg_len = radians(seg_step) * ring_r0 * 1.2;

    // At angle t, rotate such that:
    //  - local X axis is tangential to the loop
    //  - local Y axis is radial (thickness direction)
    //  - local Z is vertical (band width)
    translate([x, y, zc])
        rotate([0,0,t])
            cube([seg_len, band_thickness, band_width], center=true);
}