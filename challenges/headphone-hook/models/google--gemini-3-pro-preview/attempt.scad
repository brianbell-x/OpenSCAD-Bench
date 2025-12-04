// ==========================================
// Parameter Settings
// ==========================================

// Thickness of your desk (mm)
desk_thickness = 25;

// How far the hook sticks out from the edge of the desk (mm)
hook_reach = 50;

// How deep the clamp goes onto the desk (mm)
clamp_depth = 45;

// Width of the hook (width of the headband contact area) (mm)
part_width = 25;

// Minimum wall thickness (mm) - kept >4mm for sturdiness
wall_thick = 6;

// Tolerance for the clamp gap (mm). 
// 0.4mm usually provides a nice friction fit for PLA/PETG.
tolerance = 0.4;

// Resolution of curves
$fn = 100; 

// ==========================================
// Main Geometry
// ==========================================

// Rotate to lay flat on the print bed for maximum strength
rotate([0, -90, 0])
    headphone_hook();

module headphone_hook() {
    linear_extrude(height = part_width) {
        difference() {
            // 1. The Main Body Shape (with rounded corners)
            offset(r = 2) {
                union() {
                    // Top Clamp Arm
                    translate([-clamp_depth, desk_thickness + tolerance])
                        square([clamp_depth + wall_thick, wall_thick - 2]); // -2 accounts for offset
                    
                    // Spine (Vertical back part)
                    translate([0, -wall_thick])
                        square([wall_thick, desk_thickness + tolerance + 2*wall_thick]);
                    
                    // The Hook / Headband Rest
                    // We construct this geometry specifically to be curved
                    translate([wall_thick, -wall_thick])
                        hook_geometry();
                }
            }

            // 2. Subtract the empty space for the Desk
            // We treat zero (Y=0) as the bottom surface of the desk
            desk_cutout();
        }
    }
}

module hook_geometry() {
    // This creates the "J" shape with a curved top surface
    // preventing creasing of the headband.
    union() {
        intersection() {
            // Boundary box for the hook arm
            translate([0, -30]) square([hook_reach, 30]);
            
            // tremendous circle to create a gentle "convex" arch
            // This mimics the shape of a head
            translate([hook_reach / 2, -55]) 
                circle(r = 60);
        }
        
        // The Lip at the end (to stop headphones sliding off)
        translate([hook_reach - 4, 0]) 
            hull() {
                translate([0, -5]) circle(d=5);
                translate([0, 5]) circle(d=5);
            }
    }
}

module desk_cutout() {
    // Main slot
    translate([-clamp_depth - 10, 0])
        square([clamp_depth + 10, desk_thickness + tolerance]);
    
    // Chamfer/Flare at the opening to help slide it on
    translate([-clamp_depth, desk_thickness + tolerance])
        polygon(points=[[0,0], [-2, 2], [0, 2]]);
        
    translate([-clamp_depth, 0])
        polygon(points=[[0,0], [-2, -2], [0, -2]]);
}