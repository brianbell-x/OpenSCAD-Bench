// Headphone Hook for 25mm desk thickness
// Uses friction-fit C-clamp design

// Constants
desk_thickness = 25;  // mm
wall_thickness = 4.5;  // mm (slightly above requirement for sturdiness)
hook_extension = 50;   // mm
hook_radius = 20;      // mm for headphone curve

// Main assembly
translate([0, 0, wall_thickness/2]) {
    difference() {
        union() {
            // Desk clamp (C-shaped bracket)
            translate([0, 0, 0])
            clamp_bracket();
            
            // Hook arm
            translate([0, wall_thickness + desk_thickness/2, 0])
            hook_arm();
        }
        
        // Remove inner space for desk
        translate([0, wall_thickness, 0])
        cube([100, desk_thickness + 0.5, wall_thickness], center=true);
        
        // Chamfer entry for easier desk insertion
        translate([0, wall_thickness/2, -wall_thickness/2])
        rotate([0, 0, 45])
        cube([10, 10, wall_thickness], center=true);
    }
}

module clamp_bracket() {
    // Main bracket that clamps to desk
    width = 60;  // mm wide enough for stability
    height = wall_thickness;
    depth = desk_thickness + 2*wall_thickness;
    
    translate([0, depth/2, 0])
    cube([width, depth, height], center=true);
}

module hook_arm() {
    // Curved hook for headphones
    arm_width = 60;  // Same as clamp for stability
    arm_height = 35; // Tall enough for most headbands
    
    // Solid curved hook
    hull() {
        // Base at desk edge
        translate([0, 0, 0])
        cube([arm_width, wall_thickness, wall_thickness], center=true);
        
        // Transition to curve
        translate([0, hook_extension/2, 0])
        cube([arm_width, wall_thickness, wall_thickness], center=true);
        
        // Curved tip
        translate([0, hook_extension - hook_radius, hook_radius])
        rotate([90, 0, 0])
        cylinder(r=hook_radius, h=wall_thickness, center=true);
    }
    
    // Add inner curve for headphone band
    translate([0, hook_extension - hook_radius, hook_radius])
    rotate([90, 0, 0])
    difference() {
        cylinder(r=hook_radius, h=arm_width, center=true);
        cylinder(r=hook_radius - wall_thickness, h=arm_width + 1, center=true);
    }
}