// L-shaped mounting bracket with counterbored holes
// All dimensions in mm

// Main bracket parameters
thickness = 6;          // Material thickness
width = 40;             // Width of bracket arms
height = 60;            // Height of vertical arm
depth = 50;             // Depth of horizontal arm

// Hole parameters
hole_diameter = 4.2;    // Clearance hole for M4 screw
cbore_diameter = 8;     // Counterbore diameter for screw head
cbore_depth = 3;        // Counterbore depth

// Sensor mounting hole pattern (vertical arm)
sensor_holes = [
    [10, 10],    // Bottom-left hole
    [10, 50],    // Top-left hole
    [30, 10],    // Bottom-right hole
    [30, 50]     // Top-right hole
];

// Frame mounting hole pattern (horizontal arm)
frame_holes = [
    [10, 10],    // Front-left hole
    [10, 40],    // Back-left hole
    [30, 10],    // Front-right hole
    [30, 40]     // Back-right hole
];

// Fillet radius for internal corner
fillet_radius = 8;

module counterbored_hole(x, y, z, vertical = true) {
    // Create a counterbored hole at specified position
    translate([x, y, z]) {
        if (vertical) {
            // Counterbore (top)
            translate([0, 0, -cbore_depth])
            cylinder(h = cbore_depth + 0.1, d = cbore_diameter, $fn = 30);
            
            // Through hole
            cylinder(h = thickness + 0.2, d = hole_diameter, center = true, $fn = 30);
        } else {
            // Counterbore (top surface)
            translate([0, 0, thickness - cbore_depth])
            cylinder(h = cbore_depth + 0.1, d = cbore_diameter, $fn = 30);
            
            // Through hole
            cylinder(h = thickness + 0.2, d = hole_diameter, center = true, $fn = 30);
        }
    }
}

module rounded_cube(x, y, z, r) {
    // Create a cube with rounded corners
    hull() {
        translate([r, r, 0])
        cylinder(h = z, r = r, $fn = 30);
        
        translate([x - r, r, 0])
        cylinder(h = z, r = r, $fn = 30);
        
        translate([r, y - r, 0])
        cylinder(h = z, r = r, $fn = 30);
        
        translate([x - r, y - r, 0])
        cylinder(h = z, r = r, $fn = 30);
    }
}

module bracket() {
    difference() {
        union() {
            // Vertical arm (sensor mounting)
            translate([0, 0, 0])
            cube([width, thickness, height]);
            
            // Horizontal arm (frame mounting)
            translate([0, 0, 0])
            cube([thickness, depth, width]);
            
            // Reinforcement fillet
            translate([thickness, thickness, 0])
            rotate([0, -90, 0])
            linear_extrude(height = thickness)
            polygon(points = [
                [0, 0],
                [fillet_radius, 0],
                [0, fillet_radius]
            ]);
        }
        
        // Sensor mounting holes (vertical arm)
        for (hole = sensor_holes) {
            counterbored_hole(hole[0], thickness/2, hole[1], true);
        }
        
        // Frame mounting holes (horizontal arm)
        for (hole = frame_holes) {
            counterbored_hole(thickness/2, hole[1], hole[0], false);
        }
        
        // Material reduction cutouts (to save material and weight)
        // Vertical arm cutout
        translate([width/2, thickness + 0.1, height/2])
        rotate([90, 0, 0])
        cylinder(h = thickness + 0.2, d = width - 20, $fn = 60);
        
        // Horizontal arm cutout
        translate([thickness + 0.1, depth/2, width/2])
        rotate([0, 90, 0])
        cylinder(h = thickness + 0.2, d = depth - 20, $fn = 60);
    }
}

// Generate the bracket
bracket();

// Add reference coordinate system
%color("red", 0.2) {
    translate([-10, 0, 0]) cube([5, 100, 5]);
    translate([0, -10, 0]) cube([100, 5, 5]);
    translate([0, 0, -10]) cube([5, 5, 100]);
}