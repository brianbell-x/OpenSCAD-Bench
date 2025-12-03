// Print-in-place hinge for 3mm thick walls
// Print orientation: hinge pin side down
// Use 3mm filament as pin after printing

wall_thickness = 3;
hinge_width = 20;
hinge_height = 15;
pin_diameter = 3.2; // For 3mm filament
clearance = 0.3;
screw_hole_diameter = 3.2; // For M3 screws
screw_head_diameter = 6;
screw_head_height = 2;

// Main hinge module
module hinge() {
    difference() {
        // Base plate for box side
        translate([0, 0, 0])
        cube([hinge_width, wall_thickness, hinge_height]);
        
        // Screw holes for box attachment
        for(x = [hinge_width/4, 3*hinge_width/4]) {
            translate([x, -1, hinge_height/2])
            rotate([-90, 0, 0])
            cylinder(d = screw_hole_diameter, h = wall_thickness + 2, $fn = 30);
            
            // Countersink for screw head
            translate([x, wall_thickness - screw_head_height + 0.1, hinge_height/2])
            rotate([-90, 0, 0])
            cylinder(d = screw_head_diameter, h = screw_head_height + 0.1, $fn = 30);
        }
    }
    
    // Box side hinge knuckle
    translate([0, wall_thickness, hinge_height/2 - pin_diameter/2 - 1])
    rotate([0, 90, 0])
    cylinder(d = pin_diameter + wall_thickness*2, h = hinge_width, $fn = 60);
    
    // Lid side hinge (with gap for print-in-place)
    translate([0, wall_thickness + pin_diameter + clearance*2, 0])
    difference() {
        // Base plate for lid side
        cube([hinge_width, wall_thickness, hinge_height]);
        
        // Screw holes for lid attachment
        for(x = [hinge_width/4, 3*hinge_width/4]) {
            translate([x, wall_thickness + 1, hinge_height/2])
            rotate([90, 0, 0])
            cylinder(d = screw_hole_diameter, h = wall_thickness + 2, $fn = 30);
            
            // Countersink for screw head
            translate([x, 0, hinge_height/2])
            rotate([90, 0, 0])
            cylinder(d = screw_head_diameter, h = screw_head_height + 0.1, $fn = 30);
        }
    }
    
    // Lid side hinge knuckle (split for print-in-place)
    translate([0, wall_thickness + pin_diameter + clearance*2, hinge_height/2 - pin_diameter/2 - 1])
    rotate([0, 90, 0])
    difference() {
        cylinder(d = pin_diameter + wall_thickness*2, h = hinge_width, $fn = 60);
        
        // Cut to make it print-in-place
        translate([-pin_diameter - wall_thickness, -pin_diameter - wall_thickness, -1])
        cube([(pin_diameter + wall_thickness)*2, pin_diameter + wall_thickness + 1, hinge_width + 2]);
    }
    
    // Pin hole through both knuckles
    translate([-1, wall_thickness + pin_diameter/2 + clearance, hinge_height/2 - pin_diameter/2 - 1])
    rotate([0, 90, 0])
    cylinder(d = pin_diameter, h = hinge_width + 2, $fn = 30);
}

// Render the hinge
hinge();

// Optional: Uncomment to see cross-section for debugging
/*
difference() {
    hinge();
    translate([-10, -10, -10])
    cube([40, 10, 40]);
}
*/