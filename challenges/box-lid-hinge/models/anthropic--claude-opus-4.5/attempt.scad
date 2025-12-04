// Box Lid Hinge - Filament Pin Design
// For 3mm thick walls, ~20mm total width
// Uses 1.75mm filament as hinge pin

/* [Hinge Parameters] */
wall_thickness = 3;        // Box wall thickness
hinge_width = 20;          // Total hinge width
pin_diameter = 1.75;       // Filament diameter for pin
pin_clearance = 0.3;       // Clearance for pin hole
knuckle_count = 3;         // Number of knuckles (odd for symmetric)

/* [Mounting] */
screw_hole_diameter = 3;   // M3 screw holes
countersink = true;        // Countersink the screw holes

/* [Derived Dimensions] */
knuckle_outer_d = pin_diameter + 3;  // Knuckle outer diameter
plate_thickness = 2;                  // Mounting plate thickness
plate_height = 12;                    // Height of mounting plate
plate_width = hinge_width;

// Knuckle dimensions
knuckle_width = hinge_width / knuckle_count;
pin_hole_d = pin_diameter + pin_clearance;

$fn = 32;

// Main hinge leaf module
module hinge_leaf(is_box_side = true) {
    difference() {
        union() {
            // Mounting plate
            translate([0, 0, plate_thickness/2])
                cube([plate_width, plate_height, plate_thickness], center=true);
            
            // Knuckles
            for (i = [0 : knuckle_count - 1]) {
                // Alternating knuckles between box and lid sides
                if ((i % 2 == 0) == is_box_side) {
                    translate([
                        -hinge_width/2 + knuckle_width/2 + i * knuckle_width,
                        plate_height/2,
                        0
                    ])
                    rotate([0, 90, 0])
                    cylinder(d = knuckle_outer_d, h = knuckle_width - 0.2, center = true);
                }
            }
            
            // Fillet between plate and knuckles
            translate([0, plate_height/2 - knuckle_outer_d/4, plate_thickness/2])
                cube([plate_width, knuckle_outer_d/2, plate_thickness], center=true);
        }
        
        // Pin hole through all knuckles
        translate([0, plate_height/2, 0])
        rotate([0, 90, 0])
        cylinder(d = pin_hole_d, h = hinge_width + 2, center = true);
        
        // Screw holes
        hole_spacing = plate_width * 0.6;
        for (x = [-hole_spacing/2, hole_spacing/2]) {
            translate([x, 0, -1]) {
                // Through hole
                cylinder(d = screw_hole_diameter, h = plate_thickness + 2);
                // Countersink
                if (countersink) {
                    translate([0, 0, plate_thickness + 1 - 1.5])
                    cylinder(d1 = screw_hole_diameter, d2 = screw_hole_diameter + 3, h = 1.6);
                }
            }
        }
    }
}

// Pin (cut from 1.75mm filament)
module pin_reference() {
    color("orange")
    rotate([0, 90, 0])
    cylinder(d = pin_diameter, h = hinge_width + 2, center = true);
}

// Assembly view
module assembly() {
    // Box side leaf
    color("SteelBlue")
    hinge_leaf(is_box_side = true);
    
    // Lid side leaf (rotated to show hinge action)
    color("LightSteelBlue")
    translate([0, plate_height, 0])
    rotate([0, 0, 180])
    hinge_leaf(is_box_side = false);
    
    // Show pin position
    translate([0, plate_height/2, 0])
    pin_reference();
}

// Print layout - both parts flat
module print_layout() {
    // Box side
    translate([0, -plate_height/2 - 2, 0])
    hinge_leaf(is_box_side = true);
    
    // Lid side
    translate([0, plate_height/2 + 2, 0])
    hinge_leaf(is_box_side = false);
}

// Uncomment desired output:

// Show assembled hinge
assembly();

// For printing - uncomment this and comment assembly():
// print_layout();

// Single box-side leaf:
// hinge_leaf(is_box_side = true);

// Single lid-side leaf:
// hinge_leaf(is_box_side = false);