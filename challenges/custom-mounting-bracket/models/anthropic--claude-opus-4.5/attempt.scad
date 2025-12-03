// L-Shaped Mounting Bracket for Sensor-to-Frame Connection
// All dimensions in mm

// Parameters
$fn = 32; // Smooth circles for printing

// Material thickness
thickness = 5;

// Flange dimensions (from reference)
horizontal_length = 60;
horizontal_width = 40;
vertical_height = 50;
vertical_width = 40;

// Hole parameters
hole_diameter = 5;          // M5 clearance holes
counterbore_diameter = 10;  // For M5 socket head cap screws
counterbore_depth = 3;      // Depth for flush mounting

// Hole positions on horizontal flange (from reference sketch)
// Measured from corner where flanges meet
h_holes = [
    [15, 10],   // Bottom left hole
    [45, 10],   // Bottom right hole
    [15, 30],   // Top left hole
    [50, 25],   // Offset hole (irregular pattern)
];

// Hole positions on vertical flange (from reference sketch)
// x = horizontal position, y = height from bend
v_holes = [
    [10, 15],   // Lower left
    [30, 15],   // Lower right
    [20, 35],   // Upper center (offset - irregular)
];

// Fillet radius at the bend
fillet_radius = 5;

module counterbore_hole(depth, hole_d, cb_d, cb_depth) {
    union() {
        // Through hole
        cylinder(h = depth + 1, d = hole_d, center = false);
        // Counterbore from top
        translate([0, 0, depth - cb_depth])
            cylinder(h = cb_depth + 1, d = cb_d, center = false);
    }
}

module horizontal_flange() {
    difference() {
        // Base plate
        cube([horizontal_length, horizontal_width, thickness]);
        
        // Mounting holes with counterbores
        for (pos = h_holes) {
            translate([pos[0], pos[1], -0.5])
                counterbore_hole(thickness + 1, hole_diameter, counterbore_diameter, counterbore_depth);
        }
    }
}

module vertical_flange() {
    difference() {
        // Vertical plate
        translate([0, 0, thickness])
            cube([thickness, vertical_width, vertical_height - thickness]);
        
        // Mounting holes with counterbores (from outside face)
        for (pos = v_holes) {
            translate([thickness + 0.5, pos[0], thickness + pos[1]])
                rotate([0, -90, 0])
                    counterbore_hole(thickness + 1, hole_diameter, counterbore_diameter, counterbore_depth);
        }
    }
}

module inside_fillet() {
    // Reinforcing fillet at the inside corner of the L
    translate([thickness, 0, thickness])
        rotate([-90, 0, 0])
            linear_extrude(height = min(horizontal_width, vertical_width))
                polygon([
                    [0, 0],
                    [fillet_radius, 0],
                    [0, fillet_radius]
                ]);
}

module l_bracket() {
    union() {
        horizontal_flange();
        vertical_flange();
        inside_fillet();
    }
}

// Render the bracket
l_bracket();