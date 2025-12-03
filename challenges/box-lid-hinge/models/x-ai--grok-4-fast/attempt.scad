// Simple two-part hinge for 3mm thick box walls
// Total width: 20mm
// Mounting: 3mm screw holes
// Assembly: Interleave fingers by aligning in y, insert ~2mm diameter filament pin through holes along y-axis
// Print box_hinge() for box side, lid_hinge() for lid side

width = 20;
plate_length = 15;
plate_thickness = 3;
finger_protrusion = 5;
pin_d = 2;
screw_d = 3;
hole_x = 2;  // Position of pin hole from x=0 edge of finger
z_center = 0;

box_finger_width = 4;
lid_finger_width = 2.5;
gap_size = 3;
end_gap = 1;
num_box_fingers = 3;

// Box finger start y positions
box_starts = [for (i = [0 : num_box_fingers-1]) end_gap + i * (box_finger_width + gap_size)];

// Lid finger start y positions
lid_starts = [for (i = [0 : num_box_fingers-2]) box_starts[i] + box_finger_width + (gap_size - lid_finger_width)/2 ];

module hinge_leaf(is_box) {
    local_fw = is_box ? box_finger_width : lid_finger_width;
    local_starts = is_box ? box_starts : lid_starts;
    local_num_fingers = is_box ? num_box_fingers : num_box_fingers - 1;
    local_plate_x_offset = is_box ? 0 : -plate_length;
    local_screw_x = is_box ? finger_protrusion + 5 : -5;
    
    difference() {
        union() {
            // Fingers
            for (i = [0 : local_num_fingers - 1]) {
                start_y = local_starts[i];
                translate([0, start_y, -plate_thickness / 2])
                    cube([finger_protrusion, local_fw, plate_thickness]);
            }
            
            // Mounting plate
            translate([local_plate_x_offset, 0, -plate_thickness / 2])
                cube([plate_length, width, plate_thickness]);
        }
        
        // Pin holes in fingers
        for (i = [0 : local_num_fingers - 1]) {
            start_y = local_starts[i];
            y_mid = start_y + local_fw / 2;
            translate([hole_x, y_mid, z_center])
                rotate([0, 90, 0])
                    cylinder(h = local_fw + 0.4, d = pin_d, center = true, $fn = 20);
        }
        
        // Screw holes in plate
        screw_y_positions = [6, 14];
        for (sy = screw_y_positions) {
            translate([local_screw_x, sy, z_center])
                cylinder(d = screw_d, h = plate_thickness + 0.2, center = true, $fn = 20);
        }
    }
}

module box_hinge() {
    hinge_leaf(true);
}

module lid_hinge() {
    hinge_leaf(false);
}

// Render both parts side-by-side for preview
box_hinge();
translate([25, 0, 0]) lid_hinge();