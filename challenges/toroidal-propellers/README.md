# Toroidal Propellers

## Success Criteria
- [ ] Must have exactly 3 blades arranged symmetrically (120° apart)
- [ ] Central hub with mounting hole present
- [ ] Each blade forms a twisted toroidal/ring shape
- [ ] Blades spiral upward from hub (creating propeller pitch)
- [ ] Must be manifold (watertight geometry)
- [ ] Blades must connect smoothly to the central hub

## Skills Tested
- `rotate_extrude` - Creating toroidal ring shapes
- `for-loop` - Generating multiple symmetric blades
- `transforms` - Complex 3D rotations and translations
- `hull` or `sweep` - Smooth transitions between blade and hub
- `parametric` - Managing multiple interdependent dimensions
- `trigonometry` - Calculating blade positions and angles

## Notes
This is a challenging model that requires understanding of:
- How to create twisted/tilted torus shapes (not a simple rotate_extrude)
- Proper blade pitch angles for propeller aerodynamics
- Smooth transitions where blades meet the hub
- Maintaining manifold geometry with complex curved surfaces

Common issues:
- Models may create simple flat rings instead of properly twisted toroidal blades
- Blade-to-hub connections often have gaps or non-manifold edges
- The helical twist of each blade is difficult to achieve in OpenSCAD
- May require advanced techniques like sweep operations or polyhedron construction