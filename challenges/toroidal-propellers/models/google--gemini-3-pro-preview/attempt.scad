// OpenSCAD Toroidal Propeller Design
// Dimensions and parameters based on user specifications

/* [Global Resolution] */
$fn = 60; // Smoothness of curves

/* [Hub Dimensions] */
hub_diameter = 15;
hub_height = 10;
mount_hole_diameter = 5;

/* [Blade Configuration] */
num_blades = 3;
prop_diameter_target = 100; // Approximate total diameter
blade_width = 12; // The "height" of the band
blade_thickness = 2; // Wall thickness of the band
blade_arc_angle = 340; // How much of a full loop (degrees)
blade_z_climb = 15; // Vertical spiral height from start to end
blade_cant_angle = 25; // Tilt of the entire loop structure (pitch)

/* [Geometry Calculations] */
// To achieve target diameter:
// Max radius = loop_offset + loop_radius
// Inner radius (hub merge) = loop_offset - loop_radius
// We want inner radius roughly inside hub (e.g., 4mm) and Outer at 50mm.
// 50 = offset + radius
// 4 = offset - radius
// 2 * offset = 54 -> offset = 27
// radius = 23
loop_radius = (prop_diameter_target / 2 - 4) / 2; // Approx 23mm
loop_center_offset = 50 - loop_radius; // Approx 27mm

// Calculate start and end angles to ensure connection points assume minimal radius (closest to hub)
// Cosine is -1 at 180 degrees. This puts the part closest to the hub axis.
start_deg = 180 + 10; 
end_deg = start_deg + blade_arc_angle;

/* [Render] */
difference() {
    union() {
        // 1. Central Hub
        color("DimGray")
        cylinder(d = hub_diameter, h = hub_height, center = true);

        // 2. Blades
        for (b = [0 : num_blades - 1]) {
            rotate([0, 0, b * (360 / num_blades)])
            draw_blade();
        }
    }

    // 3. Mounting Hole
    cylinder(d = mount_hole_diameter, h = hub_height + 2, center = true);
}


module draw_blade() {
    // Generate the blade by hulling sequential thin slices along the path
    step_size = 4; // Degrees per segment (lower is smoother but slower)
    
    color("DarkSlateGray")
    for (i = [start_deg : step_size : end_deg - step_size]) {
        hull() {
            blade_slice(i);
            blade_slice(i + step_size);
        }
    }
}

module blade_slice(angle) {
    // 1. Calculate local progress (0.0 to 1.0) for Z-climb
    progress = (angle - start_deg) / blade_arc_angle;
    current_z_lift = (progress * blade_z_climb) - (blade_z_climb/2);

    // 2. Apply Transformations in reverse order of operations
    
    // D. Move out to the Loop Center Offset
    translate([loop_center_offset, 0, current_z_lift])
    
    // C. Tilt the entire loop plane (Propeller overall pitch)
    rotate([0, blade_cant_angle, 0])
    
    // B. Position on the circle perimeter
    // We rotate the coordinate system to the specific angle on the loop
    rotate([0, 0, angle])
    
    // A. Move to the rim of the loop radius
    translate([loop_radius, 0, 0])
    
    // 3. Draw the Cross-Section
    // The cube represents a thin slice of the band.
    // X-axis: Radial Thickness (2mm)
    // Z-axis: Band Width (12mm) - oriented "up" relative to the loop plane
    // Y-axis: Segment length (very small, strictly for hulling)
    rotate([0, 0, 0]) // Placeholder for local twist if needed
    cube([blade_thickness, 0.1, blade_width], center = true);
}

// Visual check helper (uncomment to see expected envelope)
// %cylinder(d=100, h=1, center=true);