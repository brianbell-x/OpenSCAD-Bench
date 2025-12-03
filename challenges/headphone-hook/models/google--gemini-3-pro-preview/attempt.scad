// ==========================================
// Headphone Desk Clamp Hook
// ==========================================

/* [Dimensions] */
// Thickness of your desk in mm
desk_thickness = 25; 

// How far the hook extends from the desk edge
extension_length = 50; 

// Width of the hook (wide enough for the headband)
hook_width = 30; 

// Structural wall thickness (min 4mm recommended)
wall_thickness = 5;

// Depth of the clamp on top of the desk
clamp_depth = 40; 

/* [Friction Fit Settings] */
// Extra gap at the opening for easy insertion (mm)
opening_tolerance = 0.5; 
// Pinch at the back of the clamp (negative makes it tighter than desk_thickness)
pinch_tightness = 0.0; 

/* [Geometry] */
// Radius of the curve that holds the headphones
rest_curve_radius = 25; 
// Height of the lip at the end to stop falling
lip_height = 8; 

// Smoothness of curves
$fn = 100;

// ==========================================
// Main Geometry Construction
// ==========================================

linear_extrude(height = hook_width) {
    headphone_hook_profile();
}

module headphone_hook_profile() {
    
    // Calculate total dimensions
    total_height = desk_thickness + (wall_thickness * 2);
    
    // The arm extends from the back of the clamp
    arm_total_len = clamp_depth + extension_length;

    difference() {
        // 1. POSITIVE SHAPE (The Body)
        union() {
            // The Main Clamp C-Shape and Extension Arm combined
            // We use hull() to blend shapes together smoothly
            
            hull() {
                // Top Plate Anchor
                translate([0, total_height - wall_thickness])
                    square([clamp_depth, wall_thickness]);
                
                // Vertical Spine (Back of clamp)
                translate([0, 0])
                    square([wall_thickness, total_height]);
                
                // Bottom Arm (The part the hook attaches to)
                translate([0, 0])
                    square([arm_total_len, wall_thickness]);
            }

            // The Headphone Rest (Curved area)
            // Situated at the end of the extension
            translate([arm_total_len, wall_thickness + rest_curve_radius*0.3]) {
                rotate([0, 0, 0])
                intersection() {
                    // This circle creates the gentle arc for the band
                    translate([-rest_curve_radius/2, -rest_curve_radius + 2])
                        circle(r=rest_curve_radius);
                    
                    // Limit the height so it doesn't become a huge ball
                    translate([-rest_curve_radius, 0])
                        square([rest_curve_radius*2, lip_height + 5]);
                }
            }
            
            // The Lip (The nub at the very end)
            translate([arm_total_len + (rest_curve_radius/2) - 2, wall_thickness + lip_height])
                circle(r=wall_thickness/1.5);
                
            // Fill the gap between arm and lip for a smooth transition
            hull() {
                translate([arm_total_len - 10, wall_thickness]) 
                    square([10, 0.1]); // Base on arm
                translate([arm_total_len + (rest_curve_radius/2) - 2, wall_thickness + lip_height])
                    circle(r=wall_thickness/1.5); // The Lip
            }
        }

        // 2. NEGATIVE SHAPE (The Desk Cutout)
        // We add a slight taper to create a wedging action (friction fit)
        translate([wall_thickness, wall_thickness]) {
            polygon(points=[
                [0, 0], // Bottom back
                [clamp_depth + 10, 0], // Bottom front (extending out to ensure cut)
                
                // Top front (includes tolerance for loose fit at opening)
                [clamp_depth + 10, desk_thickness + opening_tolerance], 
                
                // Top back (exact fit or slightly pinch)
                [0, desk_thickness - pinch_tightness] 
            ]);
        }
        
        // 3. Round internal corner for stress relief/strength
        // Sharp internal corners break easily. We drill a small relief hole 
        // essentially by hulling a circle in the subtractive layer, 
        // but here we just ensure the spine-thickess absorbs the stress.
        // Instead, we add a chamfer to the cutout entrance for easy mounting.
        translate([wall_thickness + clamp_depth, wall_thickness - 2])
            rotate([0, 0, 45])
            square([5, 5]);
        
        translate([wall_thickness + clamp_depth, wall_thickness + desk_thickness + opening_tolerance + 2])
            rotate([0, 0, 45])
            square([5, 5], center=true);
    }
}