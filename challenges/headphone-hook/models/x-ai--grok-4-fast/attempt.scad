// Headphone hook clamp for 25mm desk thickness
// Extends 50mm out, curved holding part via rounded bend
// Sturdy 6mm walls, friction C-clamp (no screws)

desk_thickness = 25;
arm_thick = 6;
back_thick = 8;
clamp_depth = 15;
width = 25;
hook_extension = 50;
hang_length = 25;
round_r = 5;

union() {
    // Bottom arm (under desk)
    translate([0, -width/2, -arm_thick]) cube([clamp_depth, width, arm_thick]);
    
    // Top arm (over desk)
    translate([0, -width/2, desk_thickness]) cube([clamp_depth, width, arm_thick]);
    
    // Vertical connector (back of C-clamp)
    translate([-back_thick, -width/2, -arm_thick]) cube([back_thick, width, desk_thickness + 2 * arm_thick]);
    
    // Rounded hook (L-shaped with rounded bend for curved holding)
    minkowski() {
        union() {
            // Horizontal extension arm
            translate([-back_thick - hook_extension, -width/2, desk_thickness]) cube([hook_extension, width, arm_thick]);
            
            // Vertical drop at end
            translate([-back_thick - hook_extension - arm_thick, -width/2, desk_thickness - hang_length]) cube([arm_thick, width, hang_length]);
        }
        sphere(round_r);
    }
}