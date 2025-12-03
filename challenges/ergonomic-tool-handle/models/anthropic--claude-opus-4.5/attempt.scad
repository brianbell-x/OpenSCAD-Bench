// Ergonomic Tool Handle Grip
// Cross-sections transition from base to tip:
// A (base): Rounded rectangle
// B: Ellipse
// C: Circle with thumb rest bump
// D (tip): Simple circle

$fn = 64; // Smooth curves for 3D printing

// Total handle length
total_length = 90;

// Section positions along the handle
pos_A = 0;
pos_B = 30;
pos_C = 60;
pos_D = 90;

// Number of interpolation steps between sections
steps = 12;

// Section A (base) - Rounded rectangle parameters
A_width = 32;
A_height = 24;
A_radius = 6;

// Section B - Ellipse parameters
B_width = 28;
B_height = 22;

// Section C - Circle with thumb rest
C_radius = 12;
C_bump_radius = 5;
C_bump_offset = 10; // Distance from center to bump center

// Section D (tip) - Simple circle
D_radius = 10;

// Module to create a rounded rectangle profile
module rounded_rect_profile(width, height, corner_r) {
    offset(r = corner_r)
        offset(r = -corner_r)
            square([width - 0.01, height - 0.01], center = true);
}

// Module to create an ellipse profile
module ellipse_profile(w, h) {
    scale([w/2, h/2])
        circle(r = 1);
}

// Module to create circle with asymmetric thumb rest bump
module thumb_rest_profile(main_r, bump_r, bump_offset) {
    hull() {
        circle(r = main_r);
        // Thumb rest bump positioned asymmetrically (upper right)
        translate([bump_offset * 0.7, bump_offset * 0.7])
            circle(r = bump_r);
    }
}

// Module to create simple circle profile
module circle_profile(r) {
    circle(r = r);
}

// Linear interpolation helper
function lerp(a, b, t) = a + (a - b) * t;

// Create hull between two cross-sections at different heights
module hull_sections(z1, z2, section1, section2) {
    hull() {
        translate([0, 0, z1])
            linear_extrude(height = 0.01)
                children(0);
        translate([0, 0, z2])
            linear_extrude(height = 0.01)
                children(1);
    }
}

// Main handle construction using hull operations between slices
module ergonomic_handle() {
    // Section A to B transition
    for (i = [0:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        z1 = lerp(pos_A, pos_B, t);
        z2 = lerp(pos_A, pos_B, t_next);
        
        // Interpolated dimensions
        w1 = lerp(A_width, B_width, t);
        h1 = lerp(A_height, B_height, t);
        r1 = lerp(A_radius, min(w1, h1)/2 - 0.1, t);
        
        w2 = lerp(A_width, B_width, t_next);
        h2 = lerp(A_height, B_height, t_next);
        r2 = lerp(A_radius, min(w2, h2)/2 - 0.1, t_next);
        
        hull() {
            translate([0, 0, z1])
                linear_extrude(height = 0.01)
                    rounded_rect_profile(w1, h1, min(r1, min(w1,h1)/2 - 0.1));
            translate([0, 0, z2])
                linear_extrude(height = 0.01)
                    rounded_rect_profile(w2, h2, min(r2, min(w2,h2)/2 - 0.1));
        }
    }
    
    // Section B to C transition
    for (i = [0:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        z1 = lerp(pos_B, pos_C, t);
        z2 = lerp(pos_B, pos_C, t_next);
        
        // Interpolate from ellipse to circle with bump
        w1 = lerp(B_width, C_radius * 2, t);
        h1 = lerp(B_height, C_radius * 2, t);
        bump1 = lerp(0, C_bump_radius, t);
        offset1 = lerp(0, C_bump_offset, t);
        
        w2 = lerp(B_width, C_radius * 2, t_next);
        h2 = lerp(B_height, C_radius * 2, t_next);
        bump2 = lerp(0, C_bump_radius, t_next);
        offset2 = lerp(0, C_bump_offset, t_next);
        
        hull() {
            translate([0, 0, z1])
                linear_extrude(height = 0.01)
                    hull() {
                        ellipse_profile(w1, h1);
                        if (bump1 > 0.1)
                            translate([offset1 * 0.7, offset1 * 0.7])
                                circle(r = bump1);
                    }
            translate([0, 0, z2])
                linear_extrude(height = 0.01)
                    hull() {
                        ellipse_profile(w2, h2);
                        if (bump2 > 0.1)
                            translate([offset2 * 0.7, offset2 * 0.7])
                                circle(r = bump2);
                    }
        }
    }
    
    // Section C to D transition
    for (i = [0:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        z1 = lerp(pos_C, pos_D, t);
        z2 = lerp(pos_C, pos_D, t_next);
        
        // Interpolate from circle with bump to simple circle
        r1 = lerp(C_radius, D_radius, t);
        bump1 = lerp(C_bump_radius, 0, t);
        offset1 = lerp(C_bump_offset, 0, t);
        
        r2 = lerp(C_radius, D_radius, t_next);
        bump2 = lerp(C_bump_radius, 0, t_next);
        offset2 = lerp(C_bump_offset, 0, t_next);
        
        hull() {
            translate([0, 0, z1])
                linear_extrude(height = 0.01)
                    hull() {
                        circle(r = r1);
                        if (bump1 > 0.1)
                            translate([offset1 * 0.7, offset1 * 0.7])
                                circle(r = bump1);
                    }
            translate([0, 0, z2])
                linear_extrude(height = 0.01)
                    hull() {
                        circle(r = r2);
                        if (bump2 > 0.1)
                            translate([offset2 * 0.7, offset2 * 0.7])
                                circle(r = bump2);
                    }
        }
    }
}

// Render the handle
ergonomic_handle();