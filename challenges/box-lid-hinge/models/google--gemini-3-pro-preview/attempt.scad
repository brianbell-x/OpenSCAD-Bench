// ==========================================
// Parametric Print-in-Place Hinge (3mm Walls)
// ==========================================

// --- Dimensions ---
// Total width of the hinge along the pin axis
total_width = 20;

// Thickness of the mounting leaves (matches box wall thickness)
wall_thickness = 3;

// Length of the leaf extending from the hinge
leaf_length = 15;

// Diameter of mounting screw holes
hole_diameter = 3;

// --- Tolerance Settings ---
// Internal gap between moving parts (0.4 - 0.5 is usually good for PLA)
clearance = 0.4;

// Gap between the side-by-side knuckles
knuckle_gap = 0.6; 

// Smoothness of curves
$fn = 60;

// --- Derived Calculations ---
knuckle_outer_r = wall_thickness; // Radius is same as thickness (6mm diam total)
pin_r = wall_thickness / 2;       // 3mm diam pin
z_offset = 0;                     // Vertical position base

// Width of the individual knuckle segments
// We have 2 outer segments and 1 inner segment
segment_width = (total_width - (2 * knuckle_gap)) / 3;

// ==========================================
// Main Render
// ==========================================

union() {
    // Part 1: Outer Knuckles + Pin + Leaf 1
    color("RoyalBlue") 
        part_outer();

    // Part 2: Inner Knuckle + Leaf 2
    color("Orange") 
        part_inner();
}


// ==========================================
// Modules
// ==========================================

module part_outer() {
    union() {
        // 1. The Leaf
        difference() {
            translate([-leaf_length, 0, 0])
                cube([leaf_length, total_width, wall_thickness]);
            
            // Mounting Holes
            translate([-leaf_length/2, total_width/2, -1])
                cylinder(h = wall_thickness + 2, d = hole_diameter);
            
            // Chamfer for screw head
            translate([-leaf_length/2, total_width/2, wall_thickness - 1.5])
                cylinder(h = 2.5, d1 = hole_diameter, d2 = hole_diameter + 3);
        }

        // 2. The Outer Knuckles
        // Segment 1 (Bottom/Front in Y)
        translate([0, 0, wall_thickness])
        rotate([0, 90, 0])
            cylinder(r=knuckle_outer_r, h=segment_width);
            
        // Segment 2 (Top/Back in Y)
        translate([0, total_width - segment_width, wall_thickness])
        rotate([0, 90, 0])
            cylinder(r=knuckle_outer_r, h=segment_width);
        
        // 3. The Pin (Runs through the whole length)
        translate([0, 0, wall_thickness])
        rotate([-90, 0, 0])
            cylinder(r=pin_r, h=total_width);
            
        // Connection from Leaf to Knuckle
        // We add a filler block to ensure the cylinder touches the leaf firmly
        translate([-wall_thickness, 0, 0])
            cube([wall_thickness, segment_width, wall_thickness]);

        translate([-wall_thickness, total_width - segment_width, 0])
            cube([wall_thickness, segment_width, wall_thickness]);
    }
}

module part_inner() {
    
    // Y Position of the central segment
    y_pos = segment_width + knuckle_gap;
    
    difference() {
        union() {
            // 1. The Leaf
            translate([0, 0, 0])
                cube([leaf_length, total_width, wall_thickness]);

            // 2. The Inner Knuckle
            translate([0, y_pos, wall_thickness])
            rotate([0, 90, 0])
                cylinder(r=knuckle_outer_r, h=segment_width);
            
            // Connection from Leaf to Knuckle
            translate([0, y_pos, 0])
                cube([wall_thickness, segment_width, wall_thickness]);
        }
        
        // CUTOUTS
        
        // 1. Hole for the Pin (Pin radius + clearance)
        translate([-1, y_pos - 1, wall_thickness]) // -1 extends cut region
        rotate([-90, 0, 0])
            cylinder(r=pin_r + clearance, h=segment_width + 2);
            
        // 2. Mounting Hole
        translate([leaf_length/2, total_width/2, -1])
            cylinder(h = wall_thickness + 2, d = hole_diameter);
            
        // 3. Chamfer for screw head
        translate([leaf_length/2, total_width/2, wall_thickness - 1.5]) // Countersink depth
            cylinder(h = 2.5, d1 = hole_diameter, d2 = hole_diameter + 3);

        // 4. Cutout for the neighbor outer knuckles (creates the gaps)
        // We cut away the leaf material where the outer knuckles need to sit
        translate([-0.1, -0.1, -0.1])
            cube([leaf_length+1, y_pos, wall_thickness+1]);
            
        translate([-0.1, y_pos + segment_width, -0.1])
             cube([leaf_length+1, segment_width + knuckle_gap + 1, wall_thickness+1]);
    }
}