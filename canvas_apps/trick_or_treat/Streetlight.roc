# Streetlight -- a light at the kerb.
#
# Hand-written. **SOMETHING TO WALK BACK TOWARD.** The way down the path is
# four seconds of nothing once the house is behind you, so there is a lamp
# where the child is going: a pole on the plane it stands in, the lamp, and
# the glow around it, which is the one warm thing on the way out.
import lib.Pixels
import lib.Point
import lib.Shapes
import lib.ArgbColor
import lib.Brush
import lib.RgbColor
import Eye
import Panels

Streetlight :: [].{
	lamp_c : Brush.Rgba
	lamp_c = Brush.opaque_rgba(RgbColor.of(0xffe9a8))
	pole_c : Brush.Rgba
	pole_c = Brush.opaque_rgba(RgbColor.of(0x101014))

	# Beside the path at the kerb, and four metres up.
	stands_at : F64
	stands_at = 1.9
	lamp_high : F64
	lamp_high = 4.1

	shapes : Eye.Eye, F64 -> List(Shapes.Shape)
	shapes = |v, fwd| {
		lamp = { right: stands_at, forward: fwd, height: lamp_high }
		match Eye.sighting(v, lamp) {
			Err(BehindEye) => []
			Ok({ point: p, pixels_per_metre: ppm }) =>
				List.concat(
					Panels.face(v, fwd, [stands_at - 0.06, 0.0, stands_at + 0.06, 0.0, stands_at + 0.06, lamp_high, stands_at - 0.06, lamp_high], Flat(pole_c)),
					[
						Disc({ center: Point.at(p.x, p.y), radius: Pixels.of(1.4 * ppm), fill: Radial({ inner_color: Brush.translucent(ArgbColor.of(0x80ffe9a8)), outer_color: Brush.translucent(ArgbColor.of(0x00ffe9a8)), center: Point.at(p.x, p.y), inner_radius: Pixels.of(0.0), outer_radius: Pixels.of(1.4 * ppm) }) }),
						Disc({ center: Point.at(p.x, p.y), radius: Pixels.of(0.24 * ppm), fill: Flat(lamp_c) }),
					],
				)
		}
	}
}
