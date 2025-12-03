// Ergonomic Tool Handle Grip
// Based on cross-section profiles from reference sketch

// Parameters
handle_length = 90; // Total length in mm
sections = 4;       // Number of cross-sections

// Section positions along handle (0 = base, 1 = tip)
section_positions = [0, 0.33, 0.66, 1];

// Section A (base): Rounded rectangle
function section_a_profile(t) = [
    for (angle = [0:5:360])
        let(
            // Rounded rectangle: 18x12mm with 3mm corner radius
            width = 18,
            height = 12,
            radius = 3,
            
            // Parametric rounded rectangle
            x_base = angle <= 45 || angle >= 315 ? width/2 - radius :
                    angle >= 45 && angle <= 135 ? (width/2 - radius) + radius * cos(angle - 45) :
                    angle >= 135 && angle <= 225 ? -width/2 + radius :
                    (width/2 - radius) + radius * cos(angle - 225),
                    
            y_base = angle <= 45 || angle >= 315 ? (height/2 - radius) + radius * sin(angle) :
                    angle >= 45 && angle <= 135 ? height/2 - radius :
                    angle >= 135 && angle <= 225 ? (height/2 - radius) + radius * sin(angle - 135) :
                    -height/2 + radius,
                    
            // Add slight taper toward tip
            taper = 0.95
        )
        [x_base * taper, y_base * taper]
];

// Section B: Elliptical shape
function section_b_profile(t) = [
    for (angle = [0:5:360])
        let(
            // Ellipse: 16mm major axis, 14mm minor axis
            a = 8,  // Semi-major axis
            b = 7,  // Semi-minor axis
            
            // Rotate ellipse for ergonomic grip
            rot_angle = 15,
            x = a * cos(angle),
            y = b * sin(angle),
            
            // Rotated coordinates
            x_rot = x * cos(rot_angle) - y * sin(rot_angle),
            y_rot = x * sin(rot_angle) + y * cos(rot_angle)
        )
        [x_rot, y_rot]
];

// Section C: Circle with asymmetric thumb rest bump
function section_c_profile(t) = [
    for (angle = [0:5:360])
        let(
            // Base circle: 14mm diameter
            radius = 7,
            
            // Thumb rest parameters
            thumb_angle = 45,    // Position of thumb rest (degrees from top)
            thumb_width = 30,    // Angular width of thumb rest
            thumb_bump = 3,      // Height of thumb bump
            
            // Calculate distance from thumb rest center
            angle_diff = min(
                abs(angle - thumb_angle),
                abs(angle - thumb_angle + 360),
                abs(angle - thumb_angle - 360)
            ),
            
            // Apply thumb rest bump if within thumb rest region
            bump_factor = angle_diff < thumb_width/2 ? 
                thumb_bump * cos(180 * angle_diff / thumb_width) : 0,
            
            // Final radius with thumb bump
            final_radius = radius + bump_factor,
            
            // Convert to Cartesian coordinates
            x = final_radius * cos(angle),
            y = final_radius * sin(angle)
        )
        [x, y]
];

// Section D (tip): Simple circle
function section_d_profile(t) = [
    for (angle = [0:5:360])
        let(
            // Tapered circle: 10mm diameter
            radius = 5,
            x = radius * cos(angle),
            y = radius * sin(angle)
        )
        [x, y]
];

// Get profile for a specific section
function get_profile(section, t) = 
    section == 0 ? section_a_profile(t) :
    section == 1 ? section_b_profile(t) :
    section == 2 ? section_c_profile(t) :
    section_d_profile(t);

// Create a single cross-section slice
module cross_section_slice(section_idx, z_pos) {
    profile = get_profile(section_idx, section_positions[section_idx]);
    
    // Create polygon from profile points
    linear_extrude(height = 0.1, center = true) {
        polygon(points = profile);
    }
    
    // Add positioning
    translate([0, 0, z_pos]) {
        linear_extrude(height = 0.1, center = true) {
            polygon(points = profile);
        }
    }
}

// Create smooth handle using hull between slices
module ergonomic_handle() {
    // Number of intermediate slices for smooth transition
    slices = 20;
    
    // Create hull between consecutive slices
    for (i = [0:slices-1]) {
        hull() {
            // Current slice position
            t1 = i / slices;
            z1 = t1 * handle_length;
            
            // Next slice position
            t2 = (i + 1) / slices;
            z2 = t2 * handle_length;
            
            // Determine which sections to interpolate between
            section1 = floor(t1 * (sections - 1));
            section2 = floor(t2 * (sections - 1));
            
            // Local interpolation parameter within section transition
            local_t1 = (t1 - section_positions[section1]) / 
                      (section_positions[section1+1] - section_positions[section1]);
            local_t2 = (t2 - section_positions[section2]) / 
                      (section_positions[section2+1] - section_positions[section2]);
            
            // Create interpolated profiles
            profile1 = interpolate_profile(
                get_profile(section1, local_t1),
                get_profile(section1+1, local_t1),
                local_t1
            );
            
            profile2 = interpolate_profile(
                get_profile(section2, local_t2),
                get_profile(section2+1, local_t2),
                local_t2
            );
            
            // Create slices at both positions
            translate([0, 0, z1]) {
                linear_extrude(height = 0.1, center = true) {
                    polygon(points = profile1);
                }
            }
            
            translate([0, 0, z2]) {
                linear_extrude(height = 0.1, center = true) {
                    polygon(points = profile2);
                }
            }
        }
    }
}

// Interpolate between two profiles
function interpolate_profile(profile1, profile2, t) = [
    for (i = [0:len(profile1)-1])
        [
            profile1[i].x * (1-t) + profile2[i].x * t,
            profile1[i].y * (1-t) + profile2[i].y * t
        ]
];

// Create mounting base for tool attachment
module mounting_base() {
    translate([0, 0, -5]) {
        cylinder(h = 5, r = 10, $fn = 60);
        
        // Hexagonal anti-rotation feature
        translate([0, 0, -3]) {
            cylinder(h = 3, r = 8, $fn = 6);
        }
        
        // Mounting hole
        translate([0, 0, -8]) {
            cylinder(h = 8, r = 4, $fn = 30);
        }
    }
}

// Main assembly
union() {
    // Ergonomic handle
    ergonomic_handle();
    
    // Mounting base
    mounting_base();
    
    // Add fillet at base transition
    translate([0, 0, 0]) {
        rotate_extrude($fn = 60) {
            translate([10, 0, 0]) {
                circle(r = 2, $fn = 30);
            }
        }
    }
}

// Add orientation indicator for thumb rest
color("red") {
    translate([0, 10, handle_length * 0.66]) {
        rotate([90, 0, 0]) {
            cylinder(h = 1, r = 1, $fn = 20);
        }
    }
}