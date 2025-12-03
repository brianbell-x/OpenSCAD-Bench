// OpenSCAD L-Bracket Generator
// Based on implied requirements for reference.png
// Units: mm

/* [Global Dimensions] */
thickness = 5.0;        // Thickness of the bracket walls
width = 40.0;           // Width of the bracket
leg_vertical_len = 60.0;  // Exterior height of the vertical leg (Sensor side)
leg_horizontal_len = 50.0; // Exterior length of the horizontal leg (Frame side)
corner_radius = 2.0;    // Fillet radius for the outer corner (0 for sharp)

/* [Hole Configuration] */
// Standard M4 counterbore dimensions
m4_holedia = 4.5;
m4_head_dia = 8.0;
m4_head_depth = 4.4; // Slightly deeper to ensure flushness

// Standard M5 counterbore dimensions
m5_holedia = 5.5;
m5_head_dia = 9.5;
m5_head_depth = 5.4;

/* [Render Settings] */
$fn = 60; // Resolution for circles
epsilon = 0.1; // Small overlap to prevent z-fighting

module counterbored_hole(shank_dia, head_dia, head_depth, plate_thick) {
    // The thru-hole
    translate([0, 0, -epsilon])
        cylinder(d = shank_dia, h = plate_thick + 2*epsilon);
    
    // The counterbore
    translate([0, 0, plate_thick - head_depth])
        cylinder(d = head_dia, h = head_depth + epsilon);
}

module rounded_L_bracket() {
    difference() {
        // Positive geometry: The L-Shape Body
        union() {
            // Vertical Leg
            translate([0, 0, 0])
                cube([width, thickness, leg_vertical_len]);
            
            // Horizontal Leg
            translate([0, 0, 0])
                cube([width, leg_horizontal_len, thickness]);
            
            // Corner Fillet (Reinforcement)
            translate([0, thickness, thickness])
                rotate([0, 90, 0])
                cylinder(r=thickness, h=width);
        }

        // Negative geometry: The Hole Pattern
        // Note: Coordinates are relative to the outer corner
        
        // --- Vertical Leg Holes (Sensor Side) ---
        // Hole 1: Top Center
        translate([width/2, thickness + epsilon, leg_vertical_len - 10])
            rotate([90, 0, 0])
            counterbored_hole(m4_holedia, m4_head_dia, m4_head_depth, thickness);

        // Hole 2: Lower, Offset Left (Irregular pattern)
        translate([width/2 - 10, thickness + epsilon, leg_vertical_len - 30])
            rotate([90, 0, 0])
            counterbored_hole(m4_holedia, m4_head_dia, m4_head_depth, thickness);
            
        // --- Horizontal Leg Holes (Frame Side) ---
        // Hole 3: Far Tip, Center
        translate([width/2, leg_horizontal_len - 10, 0])
            counterbored_hole(m5_holedia, m5_head_dia, m5_head_depth, thickness);

        // Hole 4: Mid-body, Offset Right (Irregular pattern)
        translate([width/2 + 8, leg_horizontal_len - 28, 0])
            counterbored_hole(m5_holedia, m5_head_dia, m5_head_depth, thickness);
            
        // Clean up the inner corner fillet overlap
        difference() {
             translate([-epsilon, thickness, thickness])
                cube([width + 2*epsilon, thickness, thickness]);
             
             translate([-2*epsilon, thickness, thickness])
                rotate([0, 90, 0])
                cylinder(r=thickness, h=width + 4*epsilon);
        }
    }
}

// Render the part
rounded_L_bracket();