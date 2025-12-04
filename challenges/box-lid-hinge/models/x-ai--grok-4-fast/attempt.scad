// Parameters for the hinge
hinge_length = 20;  // Total width/length of the hinge along the axis
plate_length = 20;  // Length of the mounting plate (from hinge edge to end)
thickness = 3;      // Thickness of the plate and wall compatibility
knuckle_width = 4;  // Width of each knuckle along the axis
knuckle_radius = 3; // Radius of the knuckles (outer diameter 6mm)
pin_radius = 1.6;   // Radius for 3.2mm pin hole (slight clearance for 3mm filament)
hole_radius = 1.5;  // Radius for 3mm mounting screw holes

// Module to generate one hinge part (box or lid)
module hinge_part(knuckle_y_centers, dir) {
    difference() {
        union() {
            // Mounting plate
            if (dir == 1) {
                // Box plate: from x=0 to plate_length
                cube([plate_length, hinge_length, thickness]);
            } else {
                // Lid plate: from x=-plate_length to 0 (mirrored)
                translate([-plate_length, 0, 0]) cube([plate_length, hinge_length, thickness]);
            }
            // Knuckles (solid cylinders along y-axis)
            for (yc = knuckle_y_centers) {
                translate([0, yc, thickness / 2]) {
                    rotate([90, 0, 0]) 
                        cylinder(h = knuckle_width, r = knuckle_radius, center = true, $fn = 32);
                }
            }
        }
        // Pin holes through knuckles (along y-axis)
        for (yc = knuckle_y_centers) {
            translate([0, yc, thickness / 2]) {
                rotate([90, 0, 0]) 
                    cylinder(h = knuckle_width + 2, r = pin_radius, center = true, $fn = 16);
            }
        }
        // Mounting holes (along z-axis, through thickness)
        hole_y_list = [5, 15];
        hole_x_rel = plate_length / 2;
        for (yh = hole_y_list) {
            xh = dir * hole_x_rel;
            translate([xh, yh, thickness / 2]) 
                cylinder(h = thickness + 2, r = hole_radius, center = true, $fn = 20);
        }
    }
}

// Render both parts side-by-side for visualization (print separately)
// Box part (with two outer knuckles)
hinge_part([2, 18], 1);

// Lid part (with one middle knuckle), translated along y to avoid overlap
translate([0, hinge_length + 10, 0]) 
    hinge_part([10], -1);