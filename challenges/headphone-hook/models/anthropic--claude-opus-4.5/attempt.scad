// Headphone Hook with Desk Clamp
// Parameters
desk_thickness = 25;        // Thickness of desk to clamp onto
hook_extension = 50;        // How far hook extends from desk
wall_thickness = 4;         // Minimum wall thickness for sturdiness
clamp_gap = desk_thickness - 1;  // Slightly smaller for friction fit
clamp_depth = 40;           // How far the clamp goes onto the desk
hook_width = 30;            // Width of the entire hook
headband_radius = 20;       // Radius of curved headphone rest
hook_drop = 60;             // How far down the hook extends

// Clamp inner dimensions
clamp_inner_height = clamp_gap;
clamp_outer_height = clamp_inner_height + 2 * wall_thickness;

// Main module
module headphone_hook() {
    difference() {
        union() {
            // Top part of C-clamp
            translate([0, 0, clamp_inner_height + wall_thickness])
                cube([clamp_depth, hook_width, wall_thickness]);
            
            // Bottom part of C-clamp
            cube([clamp_depth, hook_width, wall_thickness]);
            
            // Back of C-clamp (connects top and bottom)
            cube([wall_thickness, hook_width, clamp_outer_height]);
            
            // Hook extension from bottom of clamp
            translate([0, 0, -hook_extension + wall_thickness])
                cube([wall_thickness, hook_width, hook_extension]);
            
            // Curved headphone rest
            translate([wall_thickness + headband_radius, hook_width/2, -hook_extension + wall_thickness])
                rotate([90, 0, 0])
                    headphone_rest();
        }
        
        // Add grip ridges on inside of clamp (remove material for texture)
        for (i = [0:4]) {
            // Top grip ridges
            translate([wall_thickness + 5 + i * 7, -1, clamp_inner_height + wall_thickness - 1])
                cube([3, hook_width + 2, 2]);
            // Bottom grip ridges
            translate([wall_thickness + 5 + i * 7, -1, wall_thickness - 1])
                cube([3, hook_width + 2, 2]);
        }
    }
    
    // Add small lip at end of clamp arms for better grip
    // Top lip
    translate([clamp_depth - wall_thickness, 0, clamp_inner_height + wall_thickness])
        cube([wall_thickness, hook_width, wall_thickness + 2]);
    
    // Bottom lip
    translate([clamp_depth - wall_thickness, 0, 0])
        cube([wall_thickness, hook_width, wall_thickness + 2]);
}

// Curved rest for headphones
module headphone_rest() {
    difference() {
        union() {
            // Main curved section (180 degree arc)
            rotate_extrude(angle = 180, $fn = 60)
                translate([headband_radius, 0, 0])
                    circle(d = wall_thickness * 2, $fn = 30);
            
            // Flat extensions on both ends to catch headband
            translate([headband_radius, 0, 0])
                cylinder(h = hook_width, d = wall_thickness * 2, $fn = 30);
            translate([-headband_radius, 0, 0])
                cylinder(h = hook_width, d = wall_thickness * 2, $fn = 30);
            
            // Small upward curves at ends to prevent slipping
            translate([headband_radius + wall_thickness, 0, hook_width/2])
                rotate([0, -90, 0])
                    cylinder(h = wall_thickness, d1 = wall_thickness * 2, d2 = wall_thickness * 3, $fn = 30);
            translate([-headband_radius - wall_thickness, 0, hook_width/2])
                rotate([0, 90, 0])
                    cylinder(h = wall_thickness, d1 = wall_thickness * 2, d2 = wall_thickness * 3, $fn = 30);
        }
    }
}

// Render the hook
headphone_hook();