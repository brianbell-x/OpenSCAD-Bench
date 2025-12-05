// Toroidal Propeller Generator
// Dimensions matching specifications:
// - 100mm Tip-to-Tip
// - 15mm Hub
// - 12mm Band Width, 2mm Thickness

/* [Main Dimensions] */
prop_diameter = 100;
hub_diameter = 15;
hub_height = 10;
hole_diameter = 5;

/* [Blade Configuration] */
num_blades = 3;
blade_loop_od = 50;
band_width = 12;     // The "height" of the ribbon
band_thickness = 2;  // The wall thickness
blade_pitch_h = 15;  // Vertical rise of the spiral
blade_arc = 340;     // Degrees of the loop
tilt_angle = 25;     // Pitch/Angle of attack of the ribbon band

/* [Resolution] */
$fn = 60;            // Resolution for hub and curves
steps = 80;          // Number of segments per blade (higher is smoother but slower)

module main() {
    difference() {
        union() {
            // 1. Central Hub
            cylinder(d = hub_diameter, h = hub_height);
            
            // 2. Blades
            for (i = [0 : num_blades - 1]) {
                rotate([0, 0, i * (360 / num_blades)]) {
                    make_blade();
                }
            }
        }
        
        // 3. Mounting Hole
        translate([0, 0, -1])
            cylinder(d = hole_diameter, h = hub_height + 2);
    }
}

module make_blade() {
    // Derived Dimensions
    loop_radius = blade_loop_od / 2; 
    // Calculate offset so the outer tip hits the prop_diameter/2
    // Center_Offset + Loop_Radius = Prop_Radius
    center_offset = (prop_diameter / 2) - loop_radius;
    
    // Start/End Angles
    // We need the loop to start partially inside the hub. 
    // Equation: center_offset + loop_radius * cos(angle) = approx hub_radius
    // 25 + 25*cos(a) = 5  -> cos(a) = -0.8 -> a approx 143 deg.
    // We start at 145 to ensure it tucks in nicely.
    start_angle = 145;
    
    step_angle = blade_arc / steps;

    // Generate the ribbon using sequential hull operations
    for (i = [0 : steps - 1]) {
        hull() {
            blade_segment(i, start_angle, step_angle, loop_radius, center_offset);
            blade_segment(i + 1, start_angle, step_angle, loop_radius, center_offset);
        }
    }
}

module blade_segment(index, start_ang, step_ang, radius, offset) {
    // Current angle in the loop
    theta = start_ang + (index * step_ang);
    
    // Normalized progress (0.0 to 1.0)
    progress = index / steps;
    
    // Vertical position (Helix rise)
    // We start slightly below hub top and rise up
    z_pos = progress * blade_pitch_h;

    // Transform the cross-section slice into position
    translate([offset, 0, 0]) // 4. Move loop center away from main hub
    translate([0, 0, z_pos])  // 3. Individual slice height (Spiral)
    rotate([0, 0, theta])     // 2. Rotate around loop center
    translate([radius, 0, 0]) // 1. Move to loop radius
    rotate([tilt_angle, 0, 0]) // 0. Tilt band for Angle of Attack
    
    // The Cross-Section (Slice)
    // We use a very thin cube to represent a plane section 
    // X = Thickness (Radial)
    // Z = Band Width (Height/Axial)
    // Y = Segment length (Tangent - approximates 0 for slice)
    translate([-band_thickness/2, -0.05, -band_width/2])
        cube([band_thickness, 0.1, band_width]);
}

// Render the propeller
main();