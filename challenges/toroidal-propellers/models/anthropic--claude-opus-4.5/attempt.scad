// Toroidal Propeller with 3 Blades
// All dimensions in mm

$fn = 100; // High resolution for smooth curves

// Parameters
num_blades = 3;
blade_angle_spacing = 360 / num_blades; // 120 degrees

// Hub parameters
hub_outer_diameter = 15;
hub_height = 10;
mounting_hole_diameter = 5;

// Blade parameters
blade_loop_outer_diameter = 50;
blade_band_width = 12; // Height of the flat band
blade_band_thickness = 2; // Wall thickness
blade_arc_degrees = 340; // Nearly complete loop
blade_spiral_height = 15; // How high blades spiral up

// Calculated values
hub_radius = hub_outer_diameter / 2;
blade_loop_radius = blade_loop_outer_diameter / 2;
blade_loop_inner_radius = blade_loop_radius - blade_band_thickness;

// Center of blade loop offset from hub center
blade_center_offset = 42; // Adjusted to achieve ~100mm tip-to-tip

// Tilt angle for propeller pitch (angle of blade plane relative to horizontal)
blade_tilt_angle = 25; // degrees

// Module for the central hub
module hub() {
    difference() {
        cylinder(h = hub_height, d = hub_outer_diameter, center = true);
        cylinder(h = hub_height + 1, d = mounting_hole_diameter, center = true);
    }
}

// Module for a single toroidal blade band
module blade_band() {
    // Create a wide flat band forming an arc
    // The band is created by rotating a rectangle around the torus center
    
    arc_start = -blade_arc_degrees / 2;
    arc_end = blade_arc_degrees / 2;
    
    rotate_extrude(angle = blade_arc_degrees, $fn = 120) {
        translate([blade_loop_radius - blade_band_thickness/2, 0, 0])
            square([blade_band_thickness, blade_band_width], center = true);
    }
}

// Module for a single blade with tilt and positioning
module blade() {
    // Position blade loop center offset from hub
    translate([blade_center_offset, 0, blade_spiral_height/2])
    rotate([blade_tilt_angle, 0, 0]) // Tilt for pitch
    rotate([0, 0, -blade_arc_degrees/2 + 90]) // Orient the gap
    blade_band();
}

// Module for connection strut between hub and blade
module blade_connection(angle) {
    // Create a smooth connection from hub to the blade
    hull() {
        // At hub
        rotate([0, 0, angle])
        translate([hub_radius - 1, 0, 0])
        rotate([blade_tilt_angle/3, 0, 0])
        cube([3, blade_band_thickness, blade_band_width/2], center = true);
        
        // At blade start
        rotate([0, 0, angle])
        translate([blade_center_offset - blade_loop_radius + blade_band_thickness/2 + 2, 0, blade_spiral_height/2])
        rotate([blade_tilt_angle, 0, 0])
        rotate([0, 0, 0])
        cube([4, blade_band_thickness, blade_band_width], center = true);
    }
}

// Complete single blade with connection
module complete_blade(angle) {
    rotate([0, 0, angle]) {
        blade();
        rotate([0, 0, -angle])
        blade_connection(angle);
    }
}

// Main assembly
module toroidal_propeller() {
    // Hub
    hub();
    
    // Three blades arranged symmetrically
    for (i = [0 : num_blades - 1]) {
        complete_blade(i * blade_angle_spacing);
    }
}

// Render the propeller
toroidal_propeller();