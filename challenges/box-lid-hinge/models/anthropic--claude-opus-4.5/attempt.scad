// Box Lid Hinge - Two-part assembly with filament pin
// Designed for 3mm thick walls, 20mm total width

/* [Main Parameters] */
wall_thickness = 3;        // Box wall thickness
hinge_width = 20;          // Total width of hinge
pin_diameter = 1.75;       // Standard filament diameter
pin_clearance = 0.3;       // Clearance for pin hole

/* [Hinge Dimensions] */
plate_thickness = 2.5;     // Thickness of mounting plate
knuckle_outer_dia = 6;     // Outer diameter of knuckle
screw_hole_dia = 3;        // Mounting screw hole diameter
screw_head_dia = 5.5;      // Countersink diameter
num_knuckles = 3;          // Number of knuckles (odd number)

/* [Derived Values] */
knuckle_gap = 0.3;         // Gap between knuckles
total_knuckle_length = hinge_width - 2 * knuckle_gap;
pin_hole_dia = pin_diameter + pin_clearance;
plate_length = knuckle_outer_dia + 8;  // Length for mounting holes

// Calculate knuckle sizes
// Part A gets outer knuckles (2), Part B gets center knuckle (1)
knuckle_a_width = (total_knuckle_length - knuckle_gap * 2) / 3;
knuckle_b_width = knuckle_a_width;

/* [Rendering] */
show_part_a = true;        // Box-side part
show_part_b = true;        // Lid-side part
explode_distance = 15;     // Distance between parts for visualization

module knuckle(width, outer_dia, inner_dia) {
    difference() {
        // Outer cylinder
        rotate([0, 90, 0])
            cylinder(d=outer_dia, h=width, $fn=32);
        // Pin hole
        rotate([0, 90, 0])
            translate([0, 0, -0.1])
                cylinder(d=inner_dia, h=width + 0.2, $fn=24);
    }
}

module mounting_plate(width, length, thickness, hole_dia, countersink_dia) {
    difference() {
        // Main plate
        translate([0, 0, -thickness])
            cube([width, length, thickness]);
        
        // Mounting holes with countersink
        hole_offset_y = length / 2;
        hole_offset_x1 = width * 0.25;
        hole_offset_x2 = width * 0.75;
        
        for (x = [hole_offset_x1, hole_offset_x2]) {
            translate([x, hole_offset_y, -thickness - 0.1]) {
                // Through hole
                cylinder(d=hole_dia, h=thickness + 0.2, $fn=24);
                // Countersink
                cylinder(d1=countersink_dia, d2=hole_dia, h=(countersink_dia-hole_dia)/2 + 0.1, $fn=24);
            }
        }
    }
}

module hinge_part_a() {
    // Box-side part - has 2 outer knuckles
    knuckle_r = knuckle_outer_dia / 2;
    
    union() {
        // Mounting plate
        mounting_plate(hinge_width, plate_length, plate_thickness, screw_hole_dia, screw_head_dia);
        
        // Connection from plate to knuckle axis
        translate([0, 0, -plate_thickness])
            cube([hinge_width, knuckle_r, plate_thickness + knuckle_r]);
        
        // Left knuckle
        translate([knuckle_gap, knuckle_r, knuckle_r])
            knuckle(knuckle_a_width, knuckle_outer_dia, pin_hole_dia);
        
        // Right knuckle
        translate([hinge_width - knuckle_gap - knuckle_a_width, knuckle_r, knuckle_r])
            knuckle(knuckle_a_width, knuckle_outer_dia, pin_hole_dia);
    }
}

module hinge_part_b() {
    // Lid-side part - has 1 center knuckle
    knuckle_r = knuckle_outer_dia / 2;
    
    union() {
        // Mounting plate (on opposite side)
        translate([0, -plate_length, 0])
            mounting_plate(hinge_width, plate_length, plate_thickness, screw_hole_dia, screw_head_dia);
        
        // Connection from plate to knuckle axis
        translate([0, -plate_length + knuckle_r, -plate_thickness])
            cube([hinge_width, plate_length - knuckle_r, plate_thickness + knuckle_r]);
        
        // Center knuckle
        center_start = knuckle_gap + knuckle_a_width + knuckle_gap;
        translate([center_start, -knuckle_r, knuckle_r])
            knuckle(knuckle_b_width, knuckle_outer_dia, pin_hole_dia);
    }
}

// Render parts
if (show_part_a) {
    color("DodgerBlue")
        translate([0, -explode_distance/2, 0])
            hinge_part_a();
}

if (show_part_b) {
    color("Coral")
        translate([0, explode_distance/2, 0])
            hinge_part_b();
}

// Pin visualization (for reference)
color("Silver", 0.5)
    translate([-2, 0, knuckle_outer_dia/2])
        rotate([0, 90, 0])
            cylinder(d=pin_diameter, h=hinge_width + 4, $fn=16);