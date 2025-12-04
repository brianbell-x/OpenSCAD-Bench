// Toroidal Propeller
// Parameters
hub_d = 15;
hole_d = 5;
hub_h = 10;
band_width = 12;
band_thick = 2;
tip_r = 50;
arc_angle = 340;
rise = 15;
hub_r = hub_d / 2;
dist = tip_r - hub_r;
theta_deg = atan(rise / dist) * 180 / PI;
r1 = (tip_r - hub_r - band_width) / 2;
r2 = r1 + band_width;
x_c = hub_r + r1;

// Module for partial annulus (2D)
module partial_annulus(r_inner, r_outer, ang) {
    half_ang = ang / 2;
    difference() {
        intersection() {
            circle(r = r_outer, $fn = 128);
            polygon(points = [
                [0, 0],
                [10000 * cos(-half_ang), 10000 * sin(-half_ang)],
                [10000 * cos(half_ang), 10000 * sin(half_ang)]
            ]);
        }
        intersection() {
            circle(r = r_inner, $fn = 128);
            polygon(points = [
                [0, 0],
                [10000 * cos(-half_ang), 10000 * sin(-half_ang)],
                [10000 * cos(half_ang), 10000 * sin(half_ang)]
            ]);
        }
    }
}

// Module for single flat blade (2D positioned)
module flat_blade_2d() {
    translate([x_c, 0])
        partial_annulus(r1, r2, arc_angle);
}

// Module for tilted blade
module tilted_blade() {
    translate([hub_r, 0, 0])
        rotate([0, theta_deg, 0])
            translate([-hub_r, 0, 0])
                linear_extrude(height = band_thick, center = true, $fn = 64)
                    flat_blade_2d();
    translate([0, 0, 5])
        children();  // Not used, but to allow shift if needed; shift applied after
}

// Wait, correction: the translate z=5 is applied to the entire tilted blade
// Redefine tilted_blade to include shift
module tilted_blade() {
    translate([0, 0, 5])
        translate([hub_r, 0, 0])
            rotate([0, theta_deg, 0])
                translate([-hub_r, 0, 0])
                    linear_extrude(height = band_thick, center = true, $fn = 64)
                        flat_blade_2d();
}

// Hub
module hub() {
    translate([0, 0, 0])
        difference() {
            cylinder(h = hub_h, d = hub_d, $fn = 100);
            translate([0, 0, -0.1])
                cylinder(h = hub_h + 0.2, d = hole_d, $fn = 50);
        }
}

// Assembly
union() {
    hub();
    for (i = [0 : 2]) {
        rotate([0, 0, i * 120])
            tilted_blade();
    }
}