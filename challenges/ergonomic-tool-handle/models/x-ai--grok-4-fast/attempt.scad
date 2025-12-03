// Ergonomic tool handle grip based on assumed cross-section profiles
// Dimensions approximated for a reasonable ergonomic design:
// - Section A (base at z=0): Rounded rectangle 20mm wide (x), 30mm high (y), 3mm corner radius
// - Section B (at z=30mm): Ellipse 20mm wide (x), 30mm high (y) -- matching base for smooth transition
// - Section C (at z=60mm): 15mm diameter circle with 3mm radius thumb rest bump offset 5mm in +x direction
// - Section D (tip at z=90mm): 10mm diameter circle
// Transitions use pairwise hulls for linear lofting, ensuring manifold geometry suitable for 3D printing

// 2D cross-section modules (centered at origin in xy-plane)
module crossA() {
    minkowski() {
        square([14, 24], center = true); // Sharp inner rectangle: 20-2*3=14 width, 30-2*3=24 height
        circle(r = 3);
    }
}

module crossB() {
    scale([10, 15]) circle(r = 1); // Ellipse: 20mm x 30mm diameters
}

module crossC() {
    union() {
        circle(r = 7.5); // 15mm diameter circle
        translate([5, 0]) circle(r = 3); // Asymmetric thumb rest bump, offset +x
    }
}

module crossD() {
    circle(r = 5); // 10mm diameter circle
}

// Thin slices at positions along z-axis (total length 90mm)
slice_thickness = 0.001; // Minimal thickness for hull compatibility

sliceA = translate([0, 0, 0]) linear_extrude(slice_thickness, center = true) crossA();
sliceB = translate([0, 0, 30]) linear_extrude(slice_thickness, center = true) crossB();
sliceC = translate([0, 0, 60]) linear_extrude(slice_thickness, center = true) crossC();
sliceD = translate([0, 0, 90]) linear_extrude(slice_thickness, center = true) crossD();

// Lofted handle using pairwise hulls for smooth linear transitions
handle = hull() { sliceA; sliceB; } union hull() { sliceB; sliceC; } union hull() { sliceC; sliceD; };

// Render the handle
handle;