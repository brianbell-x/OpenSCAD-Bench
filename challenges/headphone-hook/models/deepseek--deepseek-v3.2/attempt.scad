// Headphone Hook for 25mm Desk
// Friction-fit C-clamp design

// Parameters
desk_thickness = 25;
hook_extension = 50;
wall_thickness = 4;
clamp_depth = 40;
hook_radius = 15;
curve_resolution = 64;

// Main module
headphone_hook();

module headphone_hook() {
    // Main clamp body
    difference() {
        // Outer shape
        union() {
            // Vertical clamp arm (desk side)
            translate([0, 0, 0])
            cube([wall_thickness, clamp_depth, desk_thickness + wall_thickness*2]);
            
            // Horizontal top clamp
            translate([0, 0, desk_thickness + wall_thickness])
            cube([clamp_depth/2 + wall_thickness, clamp_depth, wall_thickness]);
            
            // Horizontal bottom clamp
            translate([0, 0, 0])
            cube([clamp_depth/2 + wall_thickness, clamp_depth, wall_thickness]);
            
            // Hook arm
            translate([wall_thickness, clamp_depth/2, wall_thickness])
            rotate([0, -90, 0])
            linear_extrude(height = wall_thickness)
            polygon(points = [
                [0, 0],
                [hook_extension, 0],
                [hook_extension, -hook_radius],
                [hook_extension - hook_radius, -hook_radius]
            ]);
            
            // Curved hook end
            translate([wall_thickness, clamp_depth/2, wall_thickness - hook_radius])
            rotate([0, -90, 0])
            linear_extrude(height = wall_thickness)
            difference() {
                circle(r = hook_radius, $fn = curve_resolution);
                translate([-hook_radius, -hook_radius*2])
                square([hook_radius*2, hook_radius*2]);
            }
        }
        
        // Cutout for desk
        translate([-0.1, wall_thickness, wall_thickness])
        cube([wall_thickness + 0.2, clamp_depth - wall_thickness*2, desk_thickness]);
        
        // Cutout for hook curve (to make it hollow)
        translate([wall_thickness - 0.1, clamp_depth/2, wall_thickness - hook_radius])
        rotate([0, -90, 0])
        linear_extrude(height = wall_thickness + 0.2)
        difference() {
            circle(r = hook_radius - wall_thickness, $fn = curve_resolution);
            translate([-hook_radius, -hook_radius*2])
            square([hook_radius*2, hook_radius*2]);
        }
        
        // Fillet cuts for smoother edges
        // Top front fillet
        translate([-0.1, clamp_depth - wall_thickness, desk_thickness + wall_thickness])
        rotate([0, 90, 0])
        cylinder(r = wall_thickness, h = wall_thickness + 0.2, $fn = curve_resolution/4);
        
        // Bottom front fillet
        translate([-0.1, clamp_depth - wall_thickness, wall_thickness])
        rotate([0, 90, 0])
        cylinder(r = wall_thickness, h = wall_thickness + 0.2, $fn = curve_resolution/4);
    }
    
    // Reinforcement ribs
    for(z = [wall_thickness*2: wall_thickness*2: desk_thickness]) {
        translate([0, clamp_depth/3, z])
        cube([wall_thickness*1.5, wall_thickness, wall_thickness/2]);
        
        translate([0, clamp_depth*2/3, z])
        cube([wall_thickness*1.5, wall_thickness, wall_thickness/2]);
    }
}