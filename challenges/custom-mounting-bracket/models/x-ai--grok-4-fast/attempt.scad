// L-shaped mounting bracket with counterbored holes
// Dimensions based on reference sketch: 
// - Horizontal leg: 100mm long x 50mm wide x 5mm thick
// - Vertical leg: 80mm high x 50mm wide x 5mm thick
// - Hole pattern: M4 holes (4mm dia) with 8mm dia x 2mm deep counterbores
// - Horizontal leg holes: at (20,15) and (80,35) from origin (bottom-left of horizontal leg)
// - Vertical leg holes: at (15,20), (35,40), and (15,60) from the bend origin
// Geometry is manifold and 3D-printable (print flat on horizontal leg)

$fn = 50; // Resolution for cylinders

module l_bracket() {
    difference() {
        union() {
            // Horizontal leg (base)
            cube([100, 50, 5]);
            
            // Vertical leg (upright from bend)
            translate([0, 0, 5]) cube([50, 50, 75]);
        }
        
        // Hole 1 on horizontal leg: through hole with counterbore on top
        translate([20, 15, -0.1]) {
            cylinder(h = 5.2, d = 4); // Through hole
            translate([0, 0, 3]) cylinder(h = 2.1, d = 8); // Counterbore
        }
        
        // Hole 2 on horizontal leg: through hole with counterbore on top
        translate([80, 35, -0.1]) {
            cylinder(h = 5.2, d = 4); // Through hole
            translate([0, 0, 3]) cylinder(h = 2.1, d = 8); // Counterbore
        }
        
        // Hole 1 on vertical leg: through hole with counterbore on outer face
        translate([15, 20, 5 - 0.1]) rotate([90, 0, 0]) {
            cylinder(h = 50.2, d = 4); // Through hole (along y)
            translate([0, 0, 48]) cylinder(h = 2.1, d = 8); // Counterbore (on outer side)
        }
        
        // Hole 2 on vertical leg: through hole with counterbore on outer face
        translate([35, 40, 5 - 0.1]) rotate([90, 0, 0]) {
            cylinder(h = 50.2, d = 4); // Through hole (along y)
            translate([0, 0, 48]) cylinder(h = 2.1, d = 8); // Counterbore
        }
        
        // Hole 3 on vertical leg: through hole with counterbore on outer face
        translate([15, 60, 5 - 0.1]) rotate([90, 0, 0]) {
            cylinder(h = 50.2, d = 4); // Through hole (along y)
            translate([0, 0, 48]) cylinder(h = 2.1, d = 8); // Counterbore
        }
    }
}

// Render the bracket
l_bracket();