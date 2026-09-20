# Streetlight -- a light at the kerb.
#
# Hand-written. **SOMETHING TO WALK BACK TOWARD.** The way down the path is
# four seconds of nothing once the house is behind you, so there is a lamp
# where the child is going: a pole on the plane it stands in, the lamp, and
# the glow around it, which is the one warm thing on the way out.
import lib.Shapes
import lib.Brush
import lib.View
import Panels

Streetlight :: [].{
	lamp_c : Brush.Rgba
	lamp_c = Brush.opaque(0xffe9a8)
	pole_c : Brush.Rgba
	pole_c = Brush.opaque(0x101014)

	# Beside the path at the kerb, and four metres up.
	stands_at : F64
	stands_at = 1.9
	lamp_high : F64
	lamp_high = 4.1

	shapes : View.View, F64 -> List(Shapes.Shape)
	shapes = |v, fwd| {
		lamp = { right: stands_at, forward: fwd, height: lamp_high }
		if View.ahead(v, lamp) {
			c = View.turn(v, lamp)
			p = View.flat(v, c)
			ppm = View.pixels_per_metre(v, c.forward)
			List.concat(
				Panels.face(v, fwd, [stands_at - 0.06, 0.0, stands_at + 0.06, 0.0, stands_at + 0.06, lamp_high, stands_at - 0.06, lamp_high], Flat(pole_c)),
				[
					Disc({ x: p.x, y: p.y, r: 1.4 * ppm, fill: Radial({ inner: Brush.with_alpha(0x80ffe9a8), outer: Brush.with_alpha(0x00ffe9a8), x: p.x, y: p.y, r0: 0.0, r1: 1.4 * ppm }), clip: Anywhere }),
					Disc({ x: p.x, y: p.y, r: 0.24 * ppm, fill: Flat(lamp_c), clip: Anywhere }),
				],
			)
		} else {
			[]
		}
	}
}
