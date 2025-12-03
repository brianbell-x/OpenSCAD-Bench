# Ergonomic Tool Handle

## Success Criteria
- [ ] Handle created using loft or hull between 4 cross-sections
- [ ] Cross-section A (base, z=0): 35mm × 25mm rounded rectangle, corner radius 8mm
- [ ] Cross-section B (z=30mm): 30mm × 28mm ellipse
- [ ] Cross-section C (z=60mm): 28mm circle with 5mm bump on one side (thumb rest)
- [ ] Cross-section D (tip, z=90mm): 22mm circle
- [ ] Smooth transitions between sections
- [ ] Total height approximately 90mm
- [ ] Geometry is manifold

## Difficulty
**Hard**

## Skills Tested
- `reference-image-interpretation` (reading cross-section profiles from sketch)
- `hull` or `loft` (transitioning between different shapes)
- `polygon` (creating custom 2D profiles)
- `linear_extrude` with scale/twist or stacked hulls
- `organic-shapes` (non-prismatic geometry)

## Notes
This challenge tests the ability to create organic, lofted geometry from cross-section profiles. The asymmetric thumb rest on section C is particularly challenging - it cannot be described purely in text and must be interpreted from the reference sketch. OpenSCAD doesn't have native loft, so the model must improvise with hull() between slices or other techniques.