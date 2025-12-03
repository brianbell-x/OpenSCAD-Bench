// Ergonomic Tool Handle Generator
// Based on 4-section profile transition
// Dimensions approximated based on standard ergonomic grip sizing
// Total Length: 90mm

// --- Configuration ---
$fn = 60; // Resolution for smooth curves

// Handle Lengths (Z positions)
z_pos_A = 0.0;   // Base
z_pos_B = 35.0;  // Neck (Narrowest point)
z_pos_C = 65.0;  // Thumb Rest (Widest feauture)
z_pos_D = 90.0;  // Tip

// Slice thickness (very thin, purely for hulling definition)
epsilon = 0.05;

// --- Main Render ---

module main_handle() {
    union() {
        // Segment 1: Base (Rect) to Neck (Ellipse)
        hull() {
            translate([0,0,z_pos_A]) section_A_base();
            translate([0,0,z_pos_B]) section_B_ellipse();
        }
        
        // Segment 2: Neck (Ellipse) to Thumb Rest (Bump)
        hull() {
            translate([0,0,z_pos_B]) section_B_ellipse();
            translate([0,0,z_pos_C]) section_C_thumb();
        }
        
        // Segment 3: Thumb Rest (Bump) to Tip (Circle)
        hull() {
            translate([0,0,z_pos_C]) section_C_thumb();
            translate([0,0,z_pos_D]) section_D_tip();
        }
    }
}

// --- Cross Section Definitions ---

// Section A: Base - Rounded Rectangle
// Provides a broad base for the palm heel
module section_A_base() {
    linear_extrude(height=epsilon) {
        offset(r=4) {
            square([22, 18], center=true); 
            // Resulting size approx 30x26mm
        }
    }
}

// Section B: Mid - Elliptical
// Narrower for the fingers to wrap around
module section_B_ellipse() {
    linear_extrude(height=epsilon) {
        scale([0.85, 0.75]) circle(d=30); 
        // Approx 25.5x22.5mm
    }
}

// Section C: Thumb Rest - Circle with Asymmetric Bump
// The "Bump" provides a ledge for the thumb to push against
module section_C_thumb() {
    linear_extrude(height=epsilon) {
        hull() {
            // Main shaft body
            circle(d=21);
            
            // The Thumb Bump
            // Rotated to 45 degrees for ergonomic thumb placement
            rotate([0, 0, -45]) { 
                translate([10, 0, 0]) 
                scale([1.2, 0.8]) 
                circle(d=10);
            }
        }
    }
}

// Section D: Tip - Simple Circle
// Interface for the tool shank
module section_D_tip() {
    linear_extrude(height=epsilon) {
        circle(d=16); // Standard tool ferrule size
    }
}

// --- Output ---
color("SlateGray") 
main_handle();

// Optional: Cutaway view to check internal geometry (Uncomment to view)
// #translate([0,0,-1]) cube([50,50,100]);