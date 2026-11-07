# Streetlight -- a light at the kerb.
#
# Hand-written. **SOMETHING TO WALK BACK TOWARD.** The way down the path is
# four seconds of nothing once the house is behind you, so there is a lamp
# where the child is going: a pole on the plane it stands in, the lamp, and
# the glow around it, which is the one warm thing on the way out.
import lib.Shapes
import lib.ArgbColor
import lib.Brush
import lib.RgbColor
import lib.Eye
import Panels

Streetlight :: [].{
	lamp_c : Brush.Rgba
	lamp_c = Brush.opaque(RgbColor.of(0xffe9a8))
	pole_c : Brush.Rgba
	pole_c = Brush.opaque(RgbColor.of(0x101014))

	# Beside the path at the kerb, and four metres up.
	stands_at : F64
	stands_at = 1.9
	lamp_high : F64
	lamp_high = 4.1

	shapes : Eye.Eye, F64 -> List(Shapes.Shape)
	shapes = |v, fwd| {
		lamp = { right: stands_at, forward: fwd, height: lamp_high }
		if Eye.ahead(v, lamp) {
			c = Eye.turn(v, lamp)
			p = Eye.flat(v, c)
			ppm = Eye.pixels_per_metre(v, c.forward)
			List.concat(
				Panels.face(v, fwd, [stands_at - 0.06, 0.0, stands_at + 0.06, 0.0, stands_at + 0.06, lamp_high, stands_at - 0.06, lamp_high], Flat(pole_c)),
				[
					Disc({ x: p.x, y: p.y, radius: 1.4 * ppm, fill: Radial({ inner_color: Brush.translucent(ArgbColor.of(0x80ffe9a8)), outer_color: Brush.translucent(ArgbColor.of(0x00ffe9a8)), center: { x: p.x, y: p.y }, inner_radius: 0.0, outer_radius: 1.4 * ppm }) }),
					Disc({ x: p.x, y: p.y, radius: 0.24 * ppm, fill: Flat(lamp_c) }),
				],
			)
		} else {
			[]
		}
	}
}
