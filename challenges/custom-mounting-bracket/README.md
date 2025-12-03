# Custom Mounting Bracket

## Success Criteria
- [ ] L-bracket shape with 90° bend is correct
- [ ] Base plate dimensions: 65mm × 40mm × 4mm thick
- [ ] Vertical leg: 40mm height from bend
- [ ] Three holes on base at correct positions: (12,15), (45,28), (55,12) from corner
- [ ] Two holes on vertical leg at correct positions: (20,18) and (20,32) from bend line
- [ ] All holes: 5mm diameter with 10mm counterbore, 2mm deep
- [ ] Geometry is manifold

## Difficulty
**Hard**

## Skills Tested
- `reference-image-interpretation` (reading dimensioned sketch)
- `counterbore` (multi-depth hole features)
- `translate` (precise positioning from coordinates)
- `boolean-ops` (subtracting holes from solid)

## Notes
This challenge requires interpreting a reference sketch with arbitrary hole positions. The hole pattern is intentionally non-uniform and cannot be memorized or guessed - it must be read from the provided reference image.