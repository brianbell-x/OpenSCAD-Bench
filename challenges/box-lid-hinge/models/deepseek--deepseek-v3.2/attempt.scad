// Print-in-place hinge for 3mm thick walls
// Designed to be printed flat, then folded
// Use M3 screws for mounting

// Parameters
wall_thickness = 3;
hinge_width = 20;
hinge_height = 15;
pin_diameter = 4;
clearance = 0.2; // Print clearance
screw_diameter = 3.2; // Hole for M3 screw
screw_head_diameter = 5.5; // For M3 screw head
screw_head_depth = 2;

// Main hinge module
module hinge_half(is_lid_side = false) {
    difference() {
        // Main hinge body
        cube([hinge_width, wall_thickness, hinge_height]);
        
        // Screw holes
        for(x = [hinge_width/4, hinge_width*3/4]) {
            translate([x, -1, hinge_height/2])
            rotate([-90, 0, 0])
            cylinder(h = wall_thickness + 2, d = screw_diameter, $fn = 30);
            
            // Countersink for screw head
            translate([x, wall_thickness - screw_head_depth + 0.1, hinge_height/2])
            rotate([-90, 0, 0])
            cylinder(h = screw_head_depth, d = screw_head_diameter, $fn = 30);
        }
        
        // Pin hole
        translate([hinge_width/2, -1, hinge_height/2])
        rotate([-90, 0, 0])
        cylinder(h = wall_thickness + 2, d = pin_diameter + clearance, $fn = 30);
    }
    
    // Knuckle
    translate([hinge_width/2, wall_thickness, hinge_height/2])
    rotate([-90, 0, 0])
    cylinder(h = 6, d = pin_diameter, $fn = 30);
}

module hinge_assembly() {
    // Box side (bottom)
    hinge_half(false);
    
    // Lid side (top) - rotated 180 degrees
    translate([hinge_width, 0, hinge_height])
    rotate([0, 180, 0])
    hinge_half(true);
}

// Print layout - print flat for print-in-place
module print_layout() {
    // Box side
    hinge_half(false);
    
    // Lid side - positioned for printing
    translate([hinge_width + 5, 0, 0])
    hinge_half(true);
    
    // Print-in-place connection bridge
    translate([hinge_width/2 - 1, wall_thickness + 6, 0])
    cube([2, 2, hinge_height]);
}

// Uncomment one of the following lines:
// For assembly visualization:
// hinge_assembly();

// For printing (recommended):
print_layout();