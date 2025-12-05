// Toroidal Propeller with 3 Blades
// Each blade is a wide flat band forming a nearly complete loop

$fn = 100;

// Hub parameters
hub_outer_diameter = 15;
hub_height = 10;
mounting_hole_diameter = 5;

// Blade parameters
blade_loop_outer_diameter = 50;
blade_band_width = 12;  // height of the flat band
blade_band_thickness = 2;  // wall thickness
blade_arc_degrees = 340;  // nearly complete loop
blade_spiral_height = 15;  // vertical rise
num_blades = 3;

// Calculated values
hub_radius = hub_outer_diameter / 2;
blade_loop_radius = blade_loop_outer_diameter / 2;
blade_loop_inner_radius = blade_loop_radius - blade_band_thickness;

// Center of blade loop offset from hub center
// Position so blade connects to hub and sweeps outward
blade_center_offset = 25;  // distance from hub center to blade loop center

// Tilt angle for pitch (degrees)
blade_tilt_angle = 20;

// Module for a single blade band (nearly complete toroidal section)
module blade_band() {
    // Create a flat band as a partial cylinder shell
    // The band is oriented with its axis vertical initially
    
    arc_start = 10;  // leave gap
    arc_end = arc_start + blade_arc_degrees;
    
    difference() {
        // Outer cylinder section
        rotate([0, 0, arc_start])
        rotate_extrude(angle = blade_arc_degrees, convexity = 4) {
            translate([blade_loop_radius - blade_band_thickness/2, 0, 0])
            square([blade_band_thickness, blade_band_width], center = true);
        }
    }
}

// Module for a single blade with tilt and positioning
module blade() {
    // Position the blade loop so it connects to the hub
    // Tilt it to create pitch
    // The blade starts near the hub and loops outward
    
    translate([blade_center_offset, 0, blade_spiral_height/2])
    rotate([blade_tilt_angle, 0, 0])
    translate([0, 0, -blade_band_width/2])
    blade_band();
}

// Module for the hub
module hub() {
    difference() {
        cylinder(h = hub_height, d = hub_outer_diameter, center = true);
        cylinder(h = hub_height + 1, d = mounting_hole_diameter, center = true);
    }
}

// Module for connection between blade and hub
module blade_connector(blade_angle) {
    // Create a smooth connection from hub to blade
    rotate([0, 0, blade_angle])
    hull() {
        // Point at hub edge
        translate([hub_radius - 1, 0, 0])
        rotate([blade_tilt_angle, 0, 0])
        cube([2, blade_band_thickness, blade_band_width], center = true);
        
        // Point at start of blade loop
        translate([blade_center_offset - blade_loop_radius + blade_band_thickness, 0, blade_spiral_height/2])
        rotate([blade_tilt_angle, 0, 0])
        cube([2, blade_band_thickness, blade_band_width], center = true);
    }
}

// Main assembly
module toroidal_propeller() {
    union() {
        // Central hub
        hub();
        
        // Three blades arranged symmetrically
        for (i = [0 : num_blades - 1]) {
            angle = i * (360 / num_blades);
            
            // Blade loop
            rotate([0, 0, angle])
            blade();
            
            // Connector from hub to blade
            blade_connector(angle);
        }
    }
}

// Render the propeller
toroidal_propeller();