desk_thickness = 25;
wall = 4;
under_depth = 30;
ext_width = 30; // extrusion width
extension = 50;
hook_down = 20;
round_radius = 8;

module arm_profile() {
    difference() {
        union() {
            translate([0, desk_thickness + wall]) square([extension, wall]);
            translate([extension, desk_thickness + wall - hook_down]) square([wall, hook_down + wall]);
        }
        translate([extension, desk_thickness + wall]) circle(r = round_radius);
    }
}

module clamp_profile() {
    union() {
        // bottom jaw
        translate([-under_depth, 0]) square([under_depth, wall]);
        // vertical back
        translate([0, 0]) square([wall, desk_thickness + 2 * wall]);
        // arm with hook
        arm_profile();
    }
}

linear_extrude(height = ext_width, center = true, convexity = 10) {
    clamp_profile();
}