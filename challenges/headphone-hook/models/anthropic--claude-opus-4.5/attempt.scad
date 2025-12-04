// Headphone Hook with Desk Clamp
// Parameters
desk_thickness = 25;        // Thickness of the desk
hook_extension = 50;        // How far the hook extends from the desk
wall_thickness = 4;         // Minimum wall thickness for sturdiness
clamp_gap = desk_thickness + 1; // Slight clearance for friction fit
clamp_depth = 40;           // How deep the clamp goes onto the desk
clamp_opening = 20;         // Width of the C-clamp opening

// Hook parameters
hook_width = 30;            // Width of the entire hook
hook_curve_radius = 25;     // Radius for the headphone support curve
hook_drop = 40;             // How far down the hook curves

// Top clamp arm
module top_arm() {
    cube([clamp_depth, hook_width, wall_thickness]);
}

// Bottom clamp arm (slightly shorter for C-clamp shape)
module bottom_arm() {
    translate([clamp_opening, 0, -clamp_gap - wall_thickness])
        cube([clamp_depth - clamp_opening, hook_width, wall_thickness]);
}

// Back of clamp connecting top and bottom
module clamp_back() {
    translate([0, 0, -clamp_gap - wall_thickness])
        cube([wall_thickness, hook_width, clamp_gap + 2 * wall_thickness]);
}

// Lip on bottom arm to grip desk
module bottom_lip() {
    translate([clamp_opening, 0, -clamp_gap])
        cube([wall_thickness, hook_width, clamp_gap * 0.3]);
}

// Extension arm going outward from desk
module extension_arm() {
    translate([-hook_extension, 0, 0])
        cube([hook_extension + wall_thickness, hook_width, wall_thickness]);
}

// Curved hook for headphones
module headphone_hook() {
    translate([-hook_extension + hook_curve_radius, hook_width/2, -hook_drop]) {
        rotate([90, 0, 0]) {
            difference() {
                // Outer curve
                cylinder(h = hook_width, r = hook_curve_radius + wall_thickness, center = true, $fn = 60);
                // Inner curve (hollow)
                cylinder(h = hook_width + 2, r = hook_curve_radius, center = true, $fn = 60);
                // Cut off top half to make a U-shape
                translate([0, hook_curve_radius/2 + wall_thickness, 0])
                    cube([hook_curve_radius * 3, hook_curve_radius + wall_thickness * 2, hook_width + 4], center = true);
                // Cut off back to connect to extension
                translate([hook_curve_radius, 0, 0])
                    cube([hook_curve_radius * 2, hook_curve_radius * 3, hook_width + 4], center = true);
            }
        }
    }
}

// Vertical support connecting extension to hook
module vertical_support() {
    translate([-hook_extension, 0, -hook_drop + hook_curve_radius])
        cube([wall_thickness, hook_width, hook_drop - hook_curve_radius + wall_thickness]);
}

// Small reinforcement fillet at the desk edge
module reinforcement() {
    translate([wall_thickness, 0, 0]) {
        difference() {
            cube([10, hook_width, 10]);
            translate([10, -1, 10])
                rotate([-90, 0, 0])
                    cylinder(h = hook_width + 2, r = 10, $fn = 40);
        }
    }
}

// Assemble the complete headphone hook
module headphone_hook_assembly() {
    union() {
        // Clamp portion
        top_arm();
        bottom_arm();
        clamp_back();
        bottom_lip();
        
        // Hook portion
        extension_arm();
        vertical_support();
        headphone_hook();
        
        // Reinforcement
        reinforcement();
    }
}

// Render the hook
headphone_hook_assembly();