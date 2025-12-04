// --- Parameters ---

// Total width of the hinge along the axis
hinge_width = 20;

// Thickness of the box walls (leaf thickness)
leaf_thickness = 3;

// Length of the leaf (distance from hinge center to edge)
leaf_length = 15; 

// Diameter of the mounting screw holes (e.g., 3mm)
screw_hole_dia = 3; 

// Diameter of the hinge knuckle (outer cylinder)
knuckle_dia = 6; 

// Clearance gap between moving parts (0.3 to 0.5 is standard for FDM)
tolerance = 0.4; // [0.2:0.1:0.6]

// Resolution of curves
$fn = 60;

// --- Calculations ---

// Radius of the knuckle
k_rad = knuckle_dia / 2;

// Calculate segments: 2 outer (Part A), 1 inner (Part B)
// We want roughly equal thirds, but accounting for gaps
segment_width = (hinge_width - (2 * tolerance)) / 3;

// --- Main Rendering ---

union() {
    // Part A: The "Outer" Wings (e.g., Box Side)
    color("RoyalBlue") 
        part_outer();

    // Part B: The "Inner" Center (e.g., Lid Side)
    color("Orange") 
        part_inner();
}

// --- Modules ---

module part_outer() {
    // Left Wing
    translate([-hinge_width/2, 0, 0]) {
        // Leaf Geometry
        translate([0, k_rad - leaf_thickness, 0])
            leaf_base(segment_width);
        
        // Knuckle Geometry
        translate([segment_width/2, 0, k_rad]) {
            rotate([0, 90, 0]) {
                // Main Cylinder
                cylinder(h = segment_width, r = k_rad, center = true);
                // The Pin (Cone pointing inwards)
                translate([0, 0, segment_width/2])
                    cylinder(h = segment_width/2, r1 = k_rad/1.5, r2 = k_rad/3);
            }
        }
    }

    // Right Wing
    translate([hinge_width/2 - segment_width, 0, 0]) {
        // Leaf Geometry
        translate([0, k_rad - leaf_thickness, 0])
            leaf_base(segment_width);
            
        // Knuckle Geometry
        translate([segment_width/2, 0, k_rad]) {
            rotate([0, 90, 0]) {
                // Main Cylinder
                cylinder(h = segment_width, r = k_rad, center = true);
                // The Pin (Cone pointing inwards)
                translate([0, 0, -segment_width])
                    cylinder(h = segment_width/2, r1 = k_rad/3, r2 = k_rad/1.5);
            }
        }
    }
}

module part_inner() {
    center_w = segment_width;
    
    translate([-center_w/2, 0, 0]) {
        // Leaf Geometry (Mirrored to the other side)
        translate([0, -leaf_length-k_rad, 0])
            leaf_base(center_w);
        
        // Knuckle Geometry
        translate([center_w/2, 0, k_rad]) {
            difference() {
                // Main Block
                rotate([0, 90, 0])
                    cylinder(h = center_w, r = k_rad, center = true);
                
                // Minus Left Cone Chamber (with tolerance)
                rotate([0, 90, 0])
                    translate([0, 0, -center_w/2 - 0.05])
                    cylinder(h = (center_w/2) + 0.1, r1 = k_rad/3 + tolerance, r2 = k_rad/1.5 + tolerance);

                // Minus Right Cone Chamber (with tolerance)
                rotate([0, 90, 0])
                    translate([0, 0, 0]) // Starts at center
                    cylinder(h = (center_w/2) + 0.1, r1 = k_rad/1.5 + tolerance, r2 = k_rad/3 + tolerance);
                
                // Center Drill Channel (Backup for simple filament hinge if print fails)
                rotate([0,90,0])
                    cylinder(h=center_w+2, r=0.5, center=true);
            }
        }
    }
}

module leaf_base(w) {
    difference() {
        // Main Plate
        cube([w, leaf_length, leaf_thickness]);
        
        // Mounting Hole
        translate([w/2, leaf_length/2 + k_rad/2, -0.1]) {
            // Shaft
            cylinder(h = leaf_thickness + 0.2, d = screw_hole_dia);
            // Countersink head (Top side)
            translate([0,0, leaf_thickness - (screw_hole_dia/2)])
                cylinder(h = screw_hole_dia/2 + 0.1, d1 = screw_hole_dia, d2 = screw_hole_dia * 2);
        }
    }
}