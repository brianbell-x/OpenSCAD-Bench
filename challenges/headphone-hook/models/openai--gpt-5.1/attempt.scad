// Headphone hook that clamps onto a 25 mm thick desk
// Units: millimeters

//////////////////// PARAMETERS ////////////////////

desk_thickness   = 25;   // actual desk thickness
wall_thickness   = 4;    // minimum structural wall thickness
hook_width       = 30;   // width of hook (along desk edge)
clip_reach       = 30;   // how far top/bottom arms reach onto desk
hook_length      = 50;   // how far the headphone support extends out from desk
hook_thickness   = 18;   // vertical thickness of the curved support
curve_radius     = 60;   // radius for the curved headband support

top_arm_height    = wall_thickness;
bottom_arm_height = wall_thickness;

$fn = 96;  // smoothness for curves

//////////////////// MAIN CALL ////////////////////

headphone_hook();

//////////////////// MODULES ////////////////////

module headphone_hook() {
    // Câshaped clamp + curved support hook
    union() {
        clamp_body();
        curved_support();
    }
}

// C-shaped clamp that slides over the desk front edge (no screws)
module clamp_body() {
    // Coordinate system:
    // X: horizontal, desk depth direction (X >= 0 is on/under the desk surface)
    // Y: along desk edge (width)
    // Z: vertical; desk bottom is Z=0, desk top is Z=desk_thickness

    // Vertical back plate that sits against the front edge of the desk
    translate([-wall_thickness, 0, -bottom_arm_height])
        cube([wall_thickness,
              hook_width,
              desk_thickness + top_arm_height + bottom_arm_height]);

    // Top arm over the desk surface
    translate([0, 0, desk_thickness])
        cube([clip_reach,
              hook_width,
              top_arm_height]);

    // Bottom arm under the desk surface
    translate([0, 0, -bottom_arm_height])
        cube([clip_reach,
              hook_width,
              bottom_arm_height]);
}

// Curved support that extends out from the desk and cradles the headband
module curved_support() {
    // The support is entirely below the desk and attached to the bottom arm.
    // Highest point of the curved support is flush with the underside of
    // the bottom arm at Z = -bottom_arm_height.

    intersection() {
        // Rectangular block that defines overall size of the support
        // X: from -hook_length (away from desk) to 0 (at desk front edge)
        // Z: from -bottom_arm_height - hook_thickness up to -bottom_arm_height
        translate([-hook_length, 0, -bottom_arm_height - hook_thickness])
            cube([hook_length,
                  hook_width,
                  hook_thickness]);

        // Large cylinder whose outer surface gives the curved top
        // Axis along Y; we intersect with the block to get a domed top.
        translate([-hook_length/2, hook_width/2, -bottom_arm_height - curve_radius])
            rotate([90, 0, 0])  // axis along global Y
                cylinder(r = curve_radius,
                         h = hook_width,
                         center = true);
    }
}

/*
// Optional: visual desk reference (commented out; for preview only)
module desk_preview() {
    color([0.8, 0.7, 0.6, 0.3])
        translate([0, 0, 0])
            cube([200, 200, desk_thickness], center = false);
}

// Uncomment to preview clamp on a desk:
// union() {
//     desk_preview();
//     headphone_hook();
// }